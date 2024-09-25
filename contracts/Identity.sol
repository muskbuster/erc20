pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Identity is Ownable {
    mapping(address => euint8) private countryCode;
    mapping(address => bool) private isRegistered;

    event IdentityRegistered(address indexed user);
    event CountryCodeUpdated(address indexed user);

    constructor() Ownable(msg.sender) {}

    function registerIdentity(address user,einput encryptedCountryCode, bytes calldata inputProof) external onlyOwner()
     {
        require(!isRegistered[user], "Identity already registered");

        euint8 code = TFHE.asEuint8(encryptedCountryCode, inputProof);
        countryCode[user] = code;
        isRegistered[user] = true;

        TFHE.allow(code, msg.sender);
        TFHE.allow(code, user);
        TFHE.allow(code,address(this));

        emit IdentityRegistered(user);
    }

    function updateCountryCode
    (address user, einput encryptedCountryCode, bytes calldata inputProof) external onlyOwner() {
        require(isRegistered[user], "Identity not registered");

        euint8 code = TFHE.asEuint8(encryptedCountryCode, inputProof);
        countryCode[user] = code;

        // Allow access to the updated encrypted country code
        TFHE.allow(code, msg.sender);
        TFHE.allow(code,address(this));

        emit CountryCodeUpdated(msg.sender);
    }

    function checkSameCountry(address from, address to) public  returns (ebool) {
        require(isRegistered[from], "From address is not registered");
        require(isRegistered[to], "To address is not registered");

        euint8 fromCountry = countryCode[from];
        euint8 toCountry = countryCode[to];
           
        ebool result = TFHE.eq(fromCountry, toCountry);
        
        // Allow querying contract to access the result
        TFHE.allow(result, msg.sender);

        return result;
    }

    function isUserRegistered(address user) external view returns (bool) {
        return isRegistered[user];
    }

    function getIdentity(address user) external  returns (euint8) {
        require(isRegistered[user], "User is not registered");

        euint8 code = countryCode[user];

        // Allow the requester to access the user's country code
        TFHE.allow(code, msg.sender);

        return code;
    }
}
