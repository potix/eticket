pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ETicket is StandardToken, Ownable {
    using strings for *;
    
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
        uint lastTicketId;
        uint discard;
    }
    mapping (address => mapping(uint => mapping(uint => publishEventTicketGroup))) publishEventTicketGroups;

    // publich event
    struct publishEvent {
        uint eventId;
        uint publishTime;
        string attributes;
        bool   stop;
        uint   lastTicketGroupId;
        uint   lastTicketSerialNumber;
    }
    mapping (address => mapping(uint => publishEvent)) publishEvents;

    // ticket
    struct ticket {
        address publisher;
        uint eventId;
        uint ticketGroupId;
        uint ticketId;
        uint price;
        bool sale;
        address owner;
        bytes commemoration;
    }
    mapping (address => ticket[]) tickers;

    // user 
    struct user {
        string attributes;
        uint   lastEventId;
    }
    mapping (address => user) users;
    mapping (address => mapping(string => string)) usersAttributes;

    // search for event
    struct eventForSearch {
        uint eventForSearchId;
        address publisher;
        uint eventId;
    }
    mapping (uint => eventForSearch) eventsForSearch;
    uint lastEventForSearchId;

    // user operation
    function GetUser() returns (string attributes){
        require(bytes(users[msg.sender].attributes).length != 0);
        attributes = users[msg.sender].attributes;
    }

    function GetUserByAddress(address userAddress) returns (string attributes) {
        require(bytes(users[userAddress].attributes).length != 0);
        attributes = users[userAddress].attributes;
    }

    function CreateUser(string name, string email, string description) {
        require(bytes(name).length != 0 && bytes(email).length != 0);

        var attrs = "".toSlice();
        attrs.concat("name:".toSlice());
        attrs.concat(name.toSlice());
        attrs.concat(", email:".toSlice());
        attrs.concat(email.toSlice());
        attrs.concat(", description:".toSlice());
        attrs.concat(description.toSlice());
        
        users[msg.sender] = user({ 
            attributes: attrs.toString(),
            lastEventId: 0
        });
    }

    function ModifyUser(string name, string email, string description) {
        require(bytes(users[msg.sender].attributes).length != 0);

        var attrs = "".toSlice();
        attrs.concat("name:".toSlice());
        attrs.concat(name.toSlice());
        attrs.concat(", email:".toSlice());
        attrs.concat(email.toSlice());
        attrs.concat(", description:".toSlice());
        attrs.concat(description.toSlice());

        users[msg.sender].attributes = attrs.toString(); 
    }


    // search operation
    function SearchEvent() {
        
    }


    // ticket operation
    function GetTickets() {
        
    }
    
    function BuyTicket() {
        
    }

    function SellTicket() {
        
    }

    function TransferTicket() {
        
    }

    function CancelTicket() {
        
    }


    // enter operation
    function enter() {
        
    }


    // publish event operation
    function GetPublishEvent() {
        
    }
    
    function CreatePublishEvent(string name, string description, string tags, string startTime, string endTime, string place, string mapLink) {
        require(bytes(name).length != 0);
        
        // for user
        strings.slice memory attrs = "".toSlice();
        attrs.concat("name:".toSlice());
        attrs.concat(name.toSlice());
        attrs.concat(", description:".toSlice());
        attrs.concat(description.toSlice());
        attrs.concat(", tags:".toSlice());
        attrs.concat(tags.toSlice());
        attrs.concat(", startTime:".toSlice());
        attrs.concat(startTime.toSlice());
        attrs.concat(", endTime:".toSlice());
        attrs.concat(endTime.toSlice());
        attrs.concat(", place:".toSlice());
        attrs.concat(place.toSlice());
        attrs.concat(", mapLink:".toSlice());
        attrs.concat(mapLink.toSlice());
        var user = users[msg.sender];
        var eventId = user.lastEventId;
        publishEvents[msg.sender][user.lastEventId] = publishEvent ({
            eventId: eventId,
            publishTime: block.timestamp,
            attributes: attrs.toString(), 
            stop: false,
            lastTicketGroupId: 0,
            lastTicketSerialNumber: 0
        });
        user.lastEventId++;

        // for search
        eventsForSearch[lastEventForSearchId] = eventForSearch({
            eventForSearchId: lastEventForSearchId,
            publisher: msg.sender,
            eventId: eventId
        });

    }

    function ModifyPublishEvent() {
        
    }

    function StopPublishEvent() {
        
    }


    // publish event ticket operation
    function GetPublishEventTicket() {
        
    }

    function CreatePublishEventTicket() {
        
    }

    function DiscardPublishEventTicketGroup() {
        
    }

    function DiscardPublichEventTicket() {
        
    }
    
}


