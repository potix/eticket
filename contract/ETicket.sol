pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";

contract ETicket is StandardToken, Ownable {
    //using strings for *;
    
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
    mapping (uint => mapping(uint => mapping(uint => mapping(uint => publishEventTicket)))) publishEventTickets;

    // publich ticket group
    struct publishEventTicketGroup {
        uint ticketGroupId;
        uint lastTicketId;
        uint discard;
    }
    mapping (uint => mapping(uint => mapping(uint => publishEventTicketGroup))) publishEventTicketGroups;

    // publich event
    struct publishEvent {
        uint eventId;
        uint publishTime;
        string name;
        string description;
        string tags;
        string startDateTime;
        string endDateTime;
        string place;
        string mapLink;
        bool   stop;
        uint   lastTicketGroupId;
        uint   lastTicketSerialNumber;
    }
    mapping(uint => mapping(uint => publishEvent)) publishEvents;

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
    mapping (uint => ticket[]) tickers;

    // user 
    struct user {
        uint userId;
        string name;
        string email;
        string description;
        uint   lastEventId;
    }
    mapping (address => user) users;
    uint lastUserId;

    // search for event
    struct eventForSearch {
        uint eventForSearchId;
        address publisher;
        uint eventId;
    }
    mapping (uint => eventForSearch) eventsForSearch;
    uint lastEventForSearchId;

    // user operation
    function GetUser() returns (string name, string email, string description){
        require(bytes(users[msg.sender].name).length != 0);
        name = users[msg.sender].name;
        email = users[msg.sender].email;
        description = users[msg.sender].description;
    }

    function GetUserByAddress(address userAddress) returns (string name, string email, string description) {
        require(bytes(users[userAddress].name).length != 0);
        name = users[userAddress].name;
        email = users[userAddress].email;
        description = users[userAddress].description;
    }

    function CreateUser(string name, string email, string description) {
        require(bytes(users[msg.sender].name).length == 0);
        require(bytes(name).length != 0 && bytes(email).length != 0);
        users[msg.sender] = user({ 
            userId: lastUserId,
            name: name,
            email: email,
            description: description,
            lastEventId: 0
        });
    }

    function ModifyUser(string name, string email, string description) {
        require(bytes(users[msg.sender].name).length != 0);
        require(bytes(name).length != 0 && bytes(email).length != 0);
        users[msg.sender].name = name; 
        users[msg.sender].email = email; 
        users[msg.sender].description = description; 
    }


    // search operation
    function findEventForSearch() {
        
    }
    
    function getEventForSearch() {
        
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
    function GetPublishEvent(uint eventId) returns (string name, string description, string tags, string startDateTime, string endDateTime, string place, string mapLink) {
        require(bytes(users[msg.sender].name).length != 0);
        require(bytes(publishEvents[users[msg.sender].userId][eventId].name).length != 0);
        name = publishEvents[users[msg.sender].userId][eventId].name;
        description = publishEvents[users[msg.sender].userId][eventId].description;
        tags = publishEvents[users[msg.sender].userId][eventId].tags;
        startDateTime = publishEvents[users[msg.sender].userId][eventId].startDateTime;
        endDateTime = publishEvents[users[msg.sender].userId][eventId].endDateTime;
        place = publishEvents[users[msg.sender].userId][eventId].place;
        mapLink = publishEvents[users[msg.sender].userId][eventId].mapLink;
    }
    
    function CreatePublishEvent(string name, string description, string tags, string startDateTime, string endDateTime, string place, string mapLink) returns (uint eventId){
        require(bytes(users[msg.sender].name).length != 0);
        require(bytes(name).length != 0);
        eventId = users[msg.sender].lastEventId;
        publishEvents[users[msg.sender].userId][eventId] = publishEvent ({
            eventId: eventId,
            publishTime: block.timestamp,
            name: name, 
            description: description, 
            tags: tags,
            startDateTime: startDateTime, 
            endDateTime: endDateTime, 
            place: place, 
            mapLink: mapLink, 
            stop: false,
            lastTicketGroupId: 0,
            lastTicketSerialNumber: 0
        });
        users[msg.sender].lastEventId++;

        // for search
        eventsForSearch[lastEventForSearchId] = eventForSearch({
            eventForSearchId: lastEventForSearchId,
            publisher: msg.sender,
            eventId: eventId
        });
        lastEventForSearchId++;
    }

    function ModifyPublishEvent(uint eventId, string name, string description, string tags, string startDateTime, string endDateTime, string place, string mapLink) {
        require(bytes(users[msg.sender].name).length != 0);
        require(bytes(name).length != 0);
        require(bytes(publishEvents[users[msg.sender].userId][eventId].name).length != 0);
        publishEvents[users[msg.sender].userId][eventId].name = name;
        publishEvents[users[msg.sender].userId][eventId].description = description;
        publishEvents[users[msg.sender].userId][eventId].tags = tags;
        publishEvents[users[msg.sender].userId][eventId].startDateTime = startDateTime;
        publishEvents[users[msg.sender].userId][eventId].endDateTime = endDateTime;
        publishEvents[users[msg.sender].userId][eventId].place = place;
        publishEvents[users[msg.sender].userId][eventId].mapLink = mapLink;
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



