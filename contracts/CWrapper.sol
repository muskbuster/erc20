// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";
import "contracts/EncryptedERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/CompliantERC20.sol";

contract ConfidentialERC20Wrapper is EncryptedERC20, GatewayCaller {
    IERC20 public baseERC20;
    mapping(address => bool) public unwrapDisabled;
    mapping(uint256 => BurnRequest) public burnRequests;
    uint256 counter;
    struct BurnRequest {
        address account;
        uint64 amount;
    }

    event Wrap(address indexed account, uint64 amount);
    event Unwrap(address indexed account, uint64 amount);
    event Burn(address indexed account, uint64 amount);

    error UnwrapNotAllowed(address account);

    constructor(address _baseERC20) EncryptedERC20("Wrapped cERC20", "wcERC20") {
        baseERC20 = IERC20(_baseERC20);
    }

    function wrap(uint64 amount) external {
        uint256 _amount = uint256(amount);
        uint256 allowance = baseERC20.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Not enough allowance");
        baseERC20.transferFrom(msg.sender, address(this),_amount);
        _mint(msg.sender, uint64(amount));
        emit Wrap(msg.sender, amount);
    }

    function unwrap(uint256 amount) external {
        if (unwrapDisabled[msg.sender]) {
            revert UnwrapNotAllowed(msg.sender);
        }

        _requestBurn(msg.sender, uint64(amount));
    }

    function _requestBurn(address account, uint64 amount) internal {
        //_checkNotZeroAddress(account);
        ebool enoughBalance = TFHE.le(amount, balances[account]);
        TFHE.allow(enoughBalance, address(this));
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(enoughBalance);
        // Store burn request
        uint256 requestID = Gateway.requestDecryption(
            cts,
            this._burnCallback.selector,
            0,
            block.timestamp + 100,
            false
        );

        burnRequests[requestID] = BurnRequest(account, amount);
    }

    function _burnCallback(uint256 requestID, bool decryptedInput) public onlyGateway {
        BurnRequest memory burnRequest = burnRequests[requestID];
        address account = burnRequest.account;
        uint64 amount = burnRequest.amount;

        if (!decryptedInput) {
            revert("Decryption failed");
        }
        _totalSupply=_totalSupply-amount;
        balances[account] = TFHE.sub(balances[account], amount);
        TFHE.allow(balances[account], address(this));
        TFHE.allow(balances[account], account);
        emit Burn(account, amount);

        baseERC20.transfer(account, amount);
        emit Unwrap(account, amount);

        // Clean up the burn request after handling it
        delete burnRequests[requestID];
    }
}
