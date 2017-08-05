pragma solidity ^0.4.14;

import "./EticketInterface.sol";
import "./EticketLibrary.sol";
import "./Token.sol";

contract Eticket is EticketInterface, Token {
    using EticketLibrary for address;
    
    address eticketDB;
    
    function Eticket(address _tokenDB, address _eticketDB) Token(_tokenDB) {
        require(_eticketDB != address(0));
        eticketDB = _eticketDB;
        name = "EticketToken";
        decimals = 18;
        symbol = "ETT";
    }

    function createUser(string _name, string _email, string _profile) returns (uint256, bool) {
        return ticketDB.createUSer(_name, _email, _profile);
    }
    
}


