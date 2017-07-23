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
    struct publishEventTicket {
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
    mapping (address => mapping(uint => mapping(uint => publishEventTicketGroup))) publishEventTicketGroups;

    // publich event
    struct publishEvent {
        address publisher;
        uint eventId;
        uint publishTime;
        string name;
        string description;
        string tag;
        uint startTime;
        uint endTime;
        string place;
        string mapUrl;
        uint   lastTicketGroupsIndex;
        uint   lastTicketSerialNumber;
        uint   stop;
    }
    mapping (address => mapping(uint => publishEvent)) publishEvents;

    // ticket
    struct ticket {
        address publisher;
        uint eventId;
        uint ticketGroupId;
        uint ticketId;
        uint price;
        uint owner;
        bytes commemoration;
    }
    mapping (address => mapping(uint => ticket)) tickers;

    // user 
    struct user {
        string name;
        string email;
        string description;
        uint   lastEventsIndex;
        uint   lastTicketsIndex;
    }
    mapping (address => user) users;

    // search for event
    struct eventForSearch {
        uint eventForSearchId;
        address publisher;
        uint eventId;
    }
    mapping (uint => eventForSearch) eventsForSearch;
    uint lastEventForSearchIndex;



    // user operation
    function GetUser() {
        
    }

    function CreateUser() {
        
    }

    function ModifytUser() {
        
    }


    // search operation
    function SearchEvent() {
        
    }


    // ticket operation
    function BuyTicket() {
        
    }

    function SellTicket() {
        
    }

    function CancelTicket() {
        
    }


    // enter operation
    function enter() {
        
    }


    // publish event operation
    function GetPublishEvent() {
        
    }
    
    function CreatePublishEvent() {
        
    }

    function ModifyPublishEvent() {
        
    }

    function StopPublishEvent() {
        
    }


    // publish ticket operation
    function GetPublishEventTicket() {
        
    }

    function CreatePublishEventTicket() {
        
    }

    function DiscardPublishEventTicketGroup() {
        
    }

    function DiscardPublichEventTicket() {
        
    }
    
}

