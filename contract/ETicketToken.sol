pragma solidity ^0.4.14;

import "./Ticket.sol";

contract Eticket is Ticket {

    function Eticket(address _tokenDB, address _ticketDB) Ticket(_tokenDB, _ticketDB) {    

    }

    function initialize() onlyOwner {
        setName("EticketToken");
        setSymbol("XET");
        setDecimals(18);
        initSupply(1000000000000000); 
    }
}
