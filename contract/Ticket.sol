pragma solidity ^0.4.14;

import "./TicketInterface.sol";
import "./Token.sol";
import "./TicketDB.sol";

contract Ticket is TicketInterface, Token {
    address ticketDB;
    
    function Ticket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != 0x0);
        ticketDB = _ticketDB;
    }

    function removeTicketDB() onlyOwner returns (bool) {
        ticketDB = address(0);
        return true;
    }

    function createUser(string _name, string _email, string _profile) returns (uint256) {
        // userId
        // user.name
        // user.email
        // user.pprofile
        var userId = TicketDB(ticketDB).getAndIncrementId(sha3("userId"));
        TicketDB(ticketDB).setString(sha3("user.name", userId), _name);
        TicketDB(ticketDB).setString(sha3("user.email", userId), _email);
        TicketDB(ticketDB).setString(sha3("user.profile", userId), _profile);
        return (userId);
    }
}



