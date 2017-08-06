pragma solidity ^0.4.14;

import "./Ticket.sol";

contract Eticket is Ticket {
    function Eticket(address _tokenDB, address _ticketDB) Ticket(_tokenDB, _ticketDB) {    

    }

    function initialize() onlyOwner returns (bool) {
        setName("ETicketToken");
        setSymbol("ETX");
        setDecimals(18);
        // for test
        increaseSupply(1000000000000000);
        return true;
    }
}

