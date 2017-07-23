pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";

contract ETicket is StandardToken, Ownable {
    string public name = "ETicketToken"; 
    string public symbol = "ETT";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 6000000000000000;

    function ETicket() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    // publich ticket
    struct publishEventTicker {
        uint ticketId;
        uint ticketSerialNumber;
        uint discard;
        address owner;
    }
    mapping (address => mapping(uint => mapping(uint => publishEventTicket))) publishEventTickets;

    // publich ticket group
    struct publishEventTicketGroup {
        uint ticketGroupId;
        uint lastTicketIndex;
        uint discard;
    }
    mapping (address => mapping(uint => mapping(uint => publichEventTicketGroup))) publishEventTicketGroups;

    // publich event
    struct publishEvent {
        uint eventId;
        string name;
        string description;
        uint startTime;
        uint endTime;
        string place;
        string mapUrl;
        uint   lastTicketGroupsIndex;
        uint   lastTicketSerialNumber;
        uint   stop;
    }
    mapping (address => mapping(uint => evnt)) publishEvents;

    // ticket
    struct ticker {
        address publisher;
        uint eventId;
        uint ticketGroupId;
        uint ticketId;
        uint price;
        uint owner;
    }
    mapping (address => mapping(uint => Ticket)) Tickets;

    // user 
    struct user {
        string name;
        string email;
        uint   lastEventsIndex;
        uint   lastTicketsIndex;
    }
    mapping (address => user) users;



    // user operation
    function CreateUser() {
        
    }

    function ModifytUser() {
        
    }



    // event operation
    function CreateEvent() {
        
    }

    function ModifyEvent() {
        
    }

    function StopEvent() {
        
    }



    // event ticket
    function CreateTicket() {
        
    }

    function DiscardTicketGroup() {
        
    }

    function DiscardTicket() {
        
    }



 
 
    
}
