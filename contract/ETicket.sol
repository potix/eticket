pragma solidity ^0.4.14;

import "./Token.sol";

contract ETicket is Token {
    address ticketDB;
    
    function ETicket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != address(0));
        name = "xxx";
    }
}

