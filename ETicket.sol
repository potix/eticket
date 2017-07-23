pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "ownership/Ownable.sol";

contract ETicket is StandardToken, Ownable {
    string public name = "ETicketToken"; 
    string public symbol = "ETT";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 6000000000000000;

    function ETicket() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    
    
}
