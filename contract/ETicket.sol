pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";

contract ETicketToken is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    // publish ticket
    struct publishEventTicket {
        uint ticketGroupId;
        uint maxSalePrice;
        uint salePrice;
        bool sale;
        bytes commemoration;
        uint fistSoldPrice;
        address publisher;
        address owner;
        uint8 status; // 1 discard, 2 expired,
        uint version;
    }

    // publish event
    struct publishEvent {
        uint publishTime;
        string name;
        string description;
        string tags;
        string startDateTime;
        string endDateTime;
        string place;
        string mapLink;
        uint maxPrice;
        uint8 status; // 1 stopped, 2 closed
        publishEventTicket[] tickets;
        uint lastTicketGroupId;
        uint version;
    }

    // ticket
    struct userTicketRef {
        address publisher;
        uint eventId;
        uint ticketId;
    }

    // user
    struct user {
        string name;
        string email;
        string description;
        publishEvent[] events;
        userTicketRef[] ticketRefs;
        uint version;
    }
    mapping (address => user) users;
    uint usersCount;

    // search for event
    struct eventRef {
        address publisher;
        uint eventId;
    }
    eventRef[] eventRefs;


    modifier userExists(address _address) {
        require(bytes(users[_address].name).length != 0);
        _;
    }

    modifier userNotExists(address _address) {
        require(bytes(users[_address].name).length == 0);
        _;
    }

    modifier eventRefExists(uint _eventRefId) {
        require(_eventRefId < eventRefs.length);
        _;
    }

    modifier eventExists(address _address, uint _eventId) {
        var _user = users[_address];
        require(bytes(_user.name).length != 0);
        require(_eventId < _user.events.length);
        require(bytes(_user.events[_eventId].name).length != 0);
        _;
    }

    modifier ticketExists(address _address, uint _eventId, uint _ticketId) {
        var _user = users[_address];
        require(bytes(_user.name).length != 0);
        require(_eventId < _user.events.length);
        var _event = _user.events[_eventId];
        require(bytes(_event.name).length != 0);
        require(_ticketId < _event.tickets.length);
        require(_event.tickets[_ticketId].owner != address(0));
        _;
    }

    function ETicket() {
        totalSupply = 6000000000000000;
        balances[msg.sender] = totalSupply;
        name = "ETicketToken";
        decimals = 18;
        symbol = "ETT";
    }

    // user operation
    function getUsersCount() returns (uint _usersCount) {
        return usersCount;
    }

    function getUserVersion() returns (uint8 _version) {
        return getUserVersionByAddress(msg.sender);
    }

    function getUser()  returns (string _name, string _email, string _description, uint _version) {
        return getUserByAddress(msg.sender);
    }

    function getUserVersionByAddress(address _address) userExists(_address)returns (uint8 _version) {
        return users[_address].version;
    }

    function getUserByAddress(address _address) userExists(_address) returns (string _name, string _email, string _description, uint _version) {
        return (users[_address].name, users[_address].email, users[_address].description, users[_address].version);
    }

    function createUser(string _name, string _email, string _description) userNotExists(msg.sender)  {
        require(bytes(_name).length != 0 && bytes(_email).length != 0);
        users[msg.sender] = user({ 
            userId: lastUserId,
            name: _name,
            email: _email,
            description: _description
        });
    }

    function modifyUser(string _name, string _email, string _description) userExists(msg.sender)  {
        require(bytes(_name).length != 0 && bytes(_email).length != 0);
        var _user = users[msg.sender];
        _user.name = _name;
        _user.email = _email;
        _user.description = _description;
        _user.version++;
    }

    // search operation
    function getEventRefsMaxId() returns (uint _maxId) {
        return eventRefs.length - 1;
    }

    function getEventSearchVersion(uint _eventRefId) eventRefExists(_eventRefId) returns (uint _version) {
        require(_eventRefId < eventRefs.length);
        var _publisher = eventsSearch[_eventRefId].publisher;
        var _eventId = eventsSearch[_eventRefId].eventId;
        return users[_publisher].publishEvent[_eventId].version;
    }

    function getEventSearch(uint _eventRefId) eventRefExists(_eventRefId) returns (address _publisher, uint _eventId, string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _version) {
        require(_eventRefId < eventRefs.length);
        _publisher = eventsSearch[_eventRefId].publisher;
        _eventId = eventsSearch[_eventRefId].eventId;
        var _event = users[_publisher].publishEvent[_eventId];
        _name = _event.name;
        _description = _event.description;
        _tags = _event.tags;
        _startDateTime = _event.startDateTime;
        _endDateTime = _event.endDateTime;
        _place = _event.place;
        _mapLink = _event.mapLink;
        _version = _event.version;
    }


    // ticket operation
    function getTickets() {
        
    }
    
    function buyTicket() {
        
    }

    function buyTicketGroup() {

    }

    function sellTicket(uint _price) {
        // publisherでなければmaxpriceを超えた価格を設定できない
        // publisherであればmaxpriceを変更できる
    }

    function transferTicket() {
        
    }

    function cancelTicket() {
        
    }


    // enter operation
    function enter() {
        
    }


    // publish event operation
    function getPublishEventsMaxId(uint _eventId) returns (uint _maxId) {
        return getPublishEventsMaxIdByAddress(msg.sender, _eventId);
    }

    function getPublishEventVersion(uint _eventId)  returns (uint _version) {
        return getPublishEventVersionByAddress(msg.sender, _eventId);
    }

    function getPublishEvent(uint _eventId) returns (string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _version) {
        return getPublishEventByAddress(msg.sender, _eventId);
    }

    function getPublishEventsMaxIdByAddress(address _address, uint _eventId) userExists(_address)returns (uint _maxId) {
        return users[_address].publishEvent.length - 1;
    }

    function getPublishEventVersionByAddress(address _address, uint _eventId) eventExists(_address, _eventId) returns (uint _version) {
        return users[_address].publishEvent[_eventId].version;
    }

    function getPublishEventByAddress(address _address, uint _eventId) eventExists(_address, _eventId) returns (string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _version) {
        var _event = users[_address].publishEvent[_eventId];
        _name = _event.name;
        _description = _event.description;
        _tags = _event.tags;
        _startDateTime = _event.startDateTime;
        _endDateTime = _event.endDateTime;
        _place = _event.place;
        _mapLink = _event.mapLink;
        _version = _event.version;
    }

    function createPublishEvent(string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _maxPrice) userExists(msg.sender) returns (uint _eventId){
        require(bytes(_name).length != 0);
        var _user = users[msg.sender];

        // create publish event
        _eventId = _user.publishEvent.length;
        users[msg.sender].events.push(publishEvent ({
            publishTime: block.timestamp,
            name: _name,
            description: _description,
            tags: _tags,
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
            place: _place,
            mapLink: _mapLink,
            maxPrice: _maxPrice,
            stop: false
        }));

        // for search
        eventRefs.push(eventSearch({
            publisher: msg.sender,
            eventId: _eventId
        }));
    }

    function modifyPublishEvent(uint _eventId, string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _maxPrice) eventExists(msg.sender, _eventId)  {
        require(bytes(name).length != 0);
        var _event = users[msg.sender].publishEvent[_eventId];
        _event.name = _name;
        _event.description = _description;
        _event.tags = _tags;
        _event.startDateTime = _startDateTime;
        _event.endDateTime = _endDateTime;
        _event.place = _place;
        _event.mapLink = _mapLink;
        _event.maxPrice = _maxPrice;
        _event.version++;
    }

    function stopPublishEvent(uint _eventId) eventExists(msg.sender, _eventId) {
        var _userId = users[msg.sender].userId;
        var _event = users[msg.sender].publishEvent[_eventId];
        _event.status = 1;
        _event.version++;
        // XXX haraimodoshi    最初に売った価格を現在の所有者に返却する
        // XXX ticket cancel
    }

    function closePublishEvent(uint _eventId) eventExists(msg.sender, _eventId) {
        var _userId = users[msg.sender].userId;
        var _event = users[msg.sender].publishEvent[_eventId];
        _event.status = 2;
        _event.version++;
        // XXX ticket expire

    }

    // publish event ticket operation
    function getPublishEventTicketsMaxId(uint _eventId)  returns (uint _maxId) {
        return getPublishEventTicketsMaxIdByAddress(msg.sender, _eventId);
    }

    function getPublishEventTicketVersion(uint _eventId, uint _ticketId) returns (uint _version) {
        return getPublishEventTicketVersionByAddress(msg.sender, _eventId, _ticketId);
    }

    function getPublishEventTicket(uint _eventId, uint _ticketId) returns (uint _ticketGroupId, uint _salePrice, bool _sale, uint _firstSoldPrice, address _owner, uint8 _status, uint _version) {
        return getPublishEventTicketByAddress(msg.sender, _eventId, _ticketId);
    }

    function getPublishEventTicketsMaxIdByAddress(address _address, uint _eventId) eventExists(_address, _eventId) returns (uint _maxId) {
        return users[_address].publishEvent[_eventId].tickets.length - 1;
    }

    function getPublishEventTicketVersionByAddress(address _address, uint _eventId, uint _ticketId) ticketExists(_address, _eventId, _ticketId) returns (uint _version) {
        return users[_address].publishEvent[_eventId].tickets[_ticketId].version;
    }

    function getPublishEventTicketByAddress(address _address, uint _eventId, uint _ticketId) ticketExists(_address, _eventId, _ticketId) returns (uint _ticketGroupId, uint _salePrice, bool _sale, uint _firstSoldPrice, address _owner, uint8 _status, uint _version) {
        var _ticket = users[_address].publishEvent[_eventId].tickets[_ticketId];
        _ticketGroupId = _ticket.ticketGroupId;
        _salePrice = _ticket.salePrice;
        _sale = _ticket.sale;
        _firstSoldPrice = _ticket.firstSoldPrice;
        _owner = _ticket.owner;
        _status = _ticket.status;
        _version = _ticket.version;
    }

    function createPublishEventTicket(uint _eventId, uint _amount, uint _price) eventExists(msg.sender, _eventId)  returns (uint _total) {
        return createPublishEventTicketGroup(1, _amount, _price);
    }

    function createPublishEventTicketGroup(uint _eventId, uint _unit, uint _amount, uint _price) eventExists(msg.sender, _eventId)  returns (uint _total) {
        require(_unit != 0 && _amount != 0);
        var _user = users[msg.sender];
        var _event = _user.publishEvent[_eventId];
        require(_price <= _event.maxPrice);
        _total = 0;
        for (uint i = 0; i < _amount; i++) {
            var _ticketGroupId = _event.lastTicketGroupId;
            for (uint j = 0; j < _unit; j++) {
                // create publish event ticket
                var _ticketId = _event.tickets.length;
                _event.tickets.push(publishEventTicket({
                    ticketId: _ticketId,
                    ticketGroupId: _ticketGroupId,
                    salePrice: _price,
                    sale: true,
                    firstSoldPrice: 0,
                    publisher: msg.sender,
                    owner: msg.sender,
                    status: 0,
                    version: 0
                }));
                // create user ticket ref
                sers[msg.sender].ticketRefs.push( userTicketRef ({
                    publisher: msg.sender,
                    eventId: _eventId,
                    ticketId: _ticketId
                }));
                _total++;
            }
            _event.lastTicketGroupId++;
        }
    }

    function discardPublishEventTicketGroup() {
        
    }

    function discardPublichEventTicket() {
        
    }
    
}
