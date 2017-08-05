pragma solidity ^0.4.11;

contract Ticket is TicketInterface, Ownable {
    address _ticketDB;
    
    function setTicketDB(address _ticketDB) onlyOwner returns (nool) {
        if (_ticketDB == address(0)) {
            return false;
        }
        ticketDB = _ticketDB;
        return true;
    }
}
