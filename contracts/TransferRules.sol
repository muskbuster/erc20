// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "./Identity.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TransferRules is Ownable2Step {
    Identity public immutable identityContract;
    
    uint64 public constant transferLimit=(20000 * 10**6);
    euint64 public TRANSFER_LIMIT=TFHE.asEuint64(transferLimit); // 20,000 tokens with 6 decimals

    mapping(address => bool) public userBlocklist;
    mapping(string => uint8) public countries;
    uint16[] public countryToCountryBlock;

    event BlacklistUpdated(address indexed user, bool isBlacklisted);
    error AddressBlacklisted(address  user);

    constructor(address _identityContract) Ownable(msg.sender) {
        identityContract = Identity(_identityContract);
    }
    
    function transfer(address from, address to,einput amount,bytes calldata inputproof)
    public returns (ebool)
    {
        euint64 eamount = TFHE.asEuint64(amount, inputproof);
        return transfer(from, to,eamount);
    }
    function transfer(address from, address to, euint64 amount) public  returns (ebool) {
        // Condition 1: Check that addresses are not blacklisted
        if (userBlocklist[from] || userBlocklist[to]) {
            revert AddressBlacklisted(userBlocklist[from] ? from : to);
        }

    
        ebool sameCountry = identityContract.checkSameCountry(from, to);
       TFHE.allow(sameCountry,address(this));
        // Condition 3: If not from the same country, check if the amount is below the transfer limit
      //  ebool belowLimit = TFHE.le(amount, TRANSFER_LIMIT);
       // TFHE.allow(belowLimit,address(this));
        // Final condition: (same country OR (different country AND below limit))
       ebool transferAllowed = sameCountry;//TFHE.or(sameCountry, TFHE.and(TFHE.not(sameCountry), belowLimit));

        // If transfer is allowed, return the original amount, otherwise return 0
        // euint64 result = TFHE.select(transferAllowed, amount, TFHE.asEuint64(0));

        // Allow this contract to access the result
        TFHE.allow(transferAllowed,address(this));

        // Allow the caller (likely the token contract) to access the result
        TFHE.allow(transferAllowed, msg.sender);

        return transferAllowed;
    }
    function mint(address to, euint64 amount) public returns (ebool) {
        // Condition 1: Check if the user is blacklisted
        if (userBlocklist[to]) {
            revert AddressBlacklisted(to);
        }
        ebool belowMintLimit = TFHE.le(amount, TRANSFER_LIMIT); // You could define a separate mint limit if necessary


        ebool mintAllowed = TFHE.and(TFHE.asEbool(true), belowMintLimit); 
        euint64 mintAmount = TFHE.select(mintAllowed, amount, TFHE.asEuint64(0));

        // Allow the result to be accessible
        TFHE.allow(mintAllowed, address(this));
        TFHE.allow(mintAllowed, msg.sender);

        return mintAllowed;
    }

    function setBlacklist(address user, bool isBlacklisted) onlyOwner() external {
        require(user != address(0), "Invalid address");
        userBlocklist[user] = isBlacklisted;
        emit BlacklistUpdated(user, isBlacklisted);
    }
}
