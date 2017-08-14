pragma solidity ^0.4.14;

import "./ETicket.sol";

contract PotiToken is ETicket {
    function PotiToken(address _tokenDB, address _ticketDB) ETicket(_tokenDB, _ticketDB) {    

    }

    function initialize() onlyOwner returns (bool) {
        setName("PotiToken");
        setSymbol("POTI");
        setDecimals(18);
        // for test
        increaseSupply(1000000000000000);
        return true;
    }
}


