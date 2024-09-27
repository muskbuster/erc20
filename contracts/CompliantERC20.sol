// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "./ConfidentialERC20.sol";
import "./Identity.sol";
import "./TransferRules.sol";
contract CompliantConfidentialERC20 is ConfidentialERC20 {
    Identity public identityContract;
    TransferRules public transferRulesContract;

    constructor(string memory name_, string memory symbol_, address _identityContract, address _transferRulesContract) 
    ConfidentialERC20(name_, symbol_) 
    {
       address owner = msg.sender;
        identityContract = Identity(_identityContract);
        transferRulesContract = TransferRules(_transferRulesContract);
    }

    



    // Overridden transfer function handling encrypted inputs
    function transfer(address to, einput encryptedAmount, bytes calldata inputProof) 
    public virtual override returns (bool) {
        euint64 amount = TFHE.asEuint64(encryptedAmount, inputProof);
        return transfer(to, amount);
    }
    
    // Internal transfer function applying the transfer rules
// Fix visibility to match the base contract's function
function transfer(address to, euint64 amount) public override returns (bool) {
    require(TFHE.isSenderAllowed(amount), "Sender not allowed");

    ebool hasEnough = TFHE.le(amount, balances[msg.sender]);
    euint64 transferAmount = TFHE.select(hasEnough, amount, TFHE.asEuint64(0));
    TFHE.allow(transferAmount,address(transferRulesContract));
    // Apply transfer rules
    ebool rulesPassed = transferRulesContract.transfer(msg.sender, to, transferAmount);
    transferAmount = TFHE.select(rulesPassed, transferAmount, TFHE.asEuint64(0));
    TFHE.allow(transferAmount,address(this));
    _transfer(msg.sender, to, transferAmount);
    return true;
}


    // Internal transfer function with transfer rules and encrypted balances
    function _transfer(address from, address to, euint64 _amount) internal  {
        euint64 newBalanceFrom = TFHE.sub(balances[from], _amount);
        balances[from] = newBalanceFrom;
        TFHE.allow(newBalanceFrom, from);

        euint64 newBalanceTo = TFHE.add(balances[to], _amount);
        balances[to] = newBalanceTo;
        TFHE.allow(newBalanceTo, address(this));
        TFHE.allow(newBalanceTo, to);

        emit Transfer(from, to);
    }

    // Allows admin to view any user's encrypted balance
    function adminViewUserBalance(address user) public onlyOwner {
        TFHE.allow(balances[user], owner());
    }

}
