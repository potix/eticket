pragma solidity ^0.4.14;

import "./EticketInterface.sol";
import "./Token.sol";
import "./EticketDB.sol";

contract Eticket is EticketInterface, Token {
    address eticketDB;
    
    function Eticket(address _tokenDB, address _eticketDB) Token(_tokenDB) {
        require(_eticketDB != address(0));
        eticketDB = _eticketDB;
    }

    function initialize() onlyOwner {
        setName("EticketToken");
        setSymbol("XET");
        setDecimals(18);
        initSupply(1000000000000000); 
    }

    function createUser(string _name, string _email, string _profile) returns (uint256) {
            // userId
            // user.name
            // user.email
            // user.pprofile
            var userId = EticketDB(eticketDB).getAndIncrementId(sha3("userId"));
            EticketDB(eticketDB).setString(sha3("user.name", userId), _name);
            EticketDB(eticketDB).setString(sha3("user.email", userId), _email);
            EticketDB(eticketDB).setString(sha3("user.profile", userId), _profile);
            return (userId);
    }
    
}


