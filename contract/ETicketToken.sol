pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./ValueFinder.sol";

contract ETicketToken is StandardToken, Ownable {
    using ValueFinder for ValueFinder.finder;
         
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    // publish ticket
    struct publishEventTicket {
        uint ticketGroupId;
        uint salePrice;
        bytes commemoration;
        uint firstSoldPrice;
        address publisher;
        address owner;
        bool sale;
        uint8 status; // 1 discard, 2 expired,
    }
    mapping (address => mapping(uint => publishEventTicket[])) publishEventTickets;

    // publish event
    struct publishEvent {
        uint publishTime;
        string name;
        string attributes;
        uint maxPrice;
        uint lastTicketGroupId;
        uint8 status; // 1 stopped, 2 closed
    }
    mapping (address => publishEvent[]) publishEvents;

    // ticket
    struct userTicketRef {
        address publisher;
        uint eventId;
        uint ticketId;
    }
    mapping (address => userTicketRef[]) userTicketRefs;

    // user
    struct user {
        string name;
        string attributes;
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
        require(bytes(users[_address].name).length != 0);
        var _events = publishEvents[_address];
        require(_eventId < publishEvents[_address].length);
        require(bytes(_events[_eventId].name).length != 0);
        _;
    }

    modifier ticketExists(address _address, uint _eventId, uint _ticketId) {
        require(bytes(users[_address].name).length != 0);
        var _events = publishEvents[_address];
        require(_eventId < _events.length);
        require(bytes(_events[_eventId].name).length != 0);
        var _tickets = publishEventTickets[_address][_eventId];
        require(_ticketId < _tickets.length);
        require(_tickets[_ticketId].owner != address(0));
        _;
    }

    function ETicketToken() {
        totalSupply = 6000000000000000;
        balances[msg.sender] = totalSupply;
        name = "ETicketToken";
        decimals = 18;
        symbol = "ETT";
    }

    // user operation
    function getUsersCount() returns (uint) {
        return usersCount;
    }

    function getUser(address _address) userExists(_address) returns (string, string) {
        return (users[_address].name, users[_address].attributes);
    }

    function createUser(string _name, string _attributes) userNotExists(msg.sender)  {
        bool _found;
        bool _isNull;
        bytes memory _value;
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        (_found, _isNull, _value) = finder.findString("email");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("profile");
        require(_found && !_isNull && _value.length != 0);
        users[msg.sender] = user({
            name: _name,
            attributes: _attributes
        });
    }

    function modifyUser(string _name, string _attributes) userExists(msg.sender)  {
        bool _found;
        bool _isNull;
        bytes memory _value;
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        (_found, _isNull, _value) = finder.findString("email");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("profile");
        require(_found && !_isNull && _value.length != 0);
        var _user = users[msg.sender];
        _user.name = _name;
        _user.attributes = _attributes;
    }

    // search operation
    function getEventRefsMaxId() returns (uint _maxId) {
        return eventRefs.length - 1;
    }

    function getEventRef(uint _eventRefId) eventRefExists(_eventRefId) returns (address, uint) {
        require(_eventRefId < eventRefs.length);
        var _publisher = eventRefs[_eventRefId].publisher;
        var _eventId = eventRefs[_eventRefId].eventId;
        return (_publisher, _eventId);        
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
    function getPublishEventsMaxId(address _address, uint _eventId) userExists(_address)returns (uint) {
        return publishEvents[_address].length - 1;
    }

    function getPublishEvent(address _address, uint _eventId) eventExists(_address, _eventId) returns (string, string, uint) {
        var _event = publishEvents[_address][_eventId];
        return (_event.name, _event.attributes, _event.maxPrice);
    }

    function createPublishEvent(string _name, string _attributes, uint _maxPrice) userExists(msg.sender) returns (uint){
        bool _found;
        bool _isNull;
        bytes memory _value;
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        (_found, _isNull, _value) = finder.findString("description");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("country");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("tags");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("startDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("endDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("place");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("mapUrl");
        require(_found && !_isNull && _value.length != 0);
        // create publish event
        var _eventId = publishEvents[msg.sender].length;
        publishEvents[msg.sender].push(publishEvent ({
            publishTime: block.timestamp,
            name: _name,
            attributes: _attributes,
            maxPrice: _maxPrice,
            status: 0,
            lastTicketGroupId: 0
        }));
        // for search
        eventRefs.push(eventRef({
            publisher: msg.sender,
            eventId: _eventId
        }));
        
        return _eventId;
    }

    function modifyPublishEvent(uint _eventId, string _name, string _attributes, uint _maxPrice) eventExists(msg.sender, _eventId)  {
        bool _found;
        bool _isNull;
        bytes memory _value;
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        (_found, _isNull, _value) = finder.findString("description");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("country");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("tags");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("startDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("endDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("place");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("mapUrl");
        require(_found && !_isNull && _value.length != 0);
        var _event = publishEvents[msg.sender][_eventId];
        _event.name = _name;
        _event.attributes = _attributes;
        _event.maxPrice = _maxPrice;
    }

    function stopPublishEvent(uint _eventId) eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        _event.status = 1;
        // XXX haraimodoshi    最初に売った価格を現在の所有者に返却する
        // XXX ticket cancel
    }

    function closePublishEvent(uint _eventId) eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        _event.status = 2;
        // XXX ticket expire
    }

    // publish event ticket operation
    function getPublishEventTicketsMaxId(address _address, uint _eventId) eventExists(_address, _eventId) returns (uint) {
        return publishEventTickets[_address][_eventId].length - 1;
    }

    // function getPublishEventTicketByAddress(address _address, uint _eventId, uint _ticketId) ticketExists(_address, _eventId, _ticketId) returns (uint, uint, bool, uint, address, uint8, uint) {
    //     var _ticket = users[_address].events[_eventId].tickets[_ticketId];
    //     return (_ticket.ticketGroupId,  _ticket.salePrice, _ticket.sale, _ticket.firstSoldPrice, _ticket.owner, _ticket.status, _ticket.version);
    // }

    // function createPublishEventTicket(uint _eventId, uint _amount, uint _price) eventExists(msg.sender, _eventId)  returns (uint _total) {
    //     return createPublishEventTicketGroup(_eventId, 1, _amount, _price);
    // }

    // function createPublishEventTicketGroup(uint _eventId, uint _unit, uint _amount, uint _price) eventExists(msg.sender, _eventId)  returns (uint) {
    //     require(_unit != 0 && _amount != 0);
    //     var _event = users[msg.sender].events[_eventId];
    //     require(_price <= _event.maxPrice);
    //     var _total = 0;
    //     for (uint i = 0; i < _amount; i++) {
    //         var _ticketGroupId = _event.lastTicketGroupId;
    //         for (uint j = 0; j < _unit; j++) {
    //             // create publish event ticket
    //             var _ticketId = _event.tickets.length;
    //             _event.tickets.push(publishEventTicket({
    //                 ticketGroupId: _ticketGroupId,
    //                 salePrice: _price,
    //                 sale: true,
    //                 firstSoldPrice: 0,
    //                 commemoration: new bytes(0),
    //                 publisher: msg.sender,
    //                 owner: msg.sender,
    //                 status: 0,
    //                 version: 0
    //             }));
    //             // create user ticket ref
    //             users[msg.sender].ticketRefs.push(userTicketRef ({
    //                 publisher: msg.sender,
    //                 eventId: _eventId,
    //                 ticketId: _ticketId
    //             }));
    //             _total++;
    //         }
    //         _event.lastTicketGroupId++;
    //     }
    //     return _total;
    // }

    function discardPublishEventTicketGroup() {
        
    }

    function discardPublichEventTicket() {
        
    }
}


