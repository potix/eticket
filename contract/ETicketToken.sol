pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./ValueFinder.sol";
import "./Random.sol";

contract ETicketToken is StandardToken, Ownable, Random {
    using ValueFinder for ValueFinder.finder;
         
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    uint8 constant TS_BUY  = 1;
    uint8 constant TS_JOIN = 2;

    uint8 constant ES_OPENED  = 1;
    uint8 constant ES_STOPPED = 2;
    uint8 constant ES_CLOSED  = 3;

    // publish ticket
    struct publishEventTicket {
        uint    groupId;
        address owner;
        int64   firstSoldPrice;
        uint32  price;
        string  buyOraclizeResponse;
        string  joinOraclizeResponse;
        uint32  buyCode;
        uint32  joinCode;
        uint8   status;
        bool    sale;
        uint64  version;
    }
    mapping (address => mapping(uint => publishEventTicket[])) publishEventTickets;

    // publish event
    struct publishEvent {
        string name;
        string attributes;
        string buyOraclizeUrl;
        string joinOraclizeUrl;
        uint32 maxPrice;
        uint8  status;
        uint groupCount;
        uint64 version;
    }
    mapping (address => publishEvent[]) publishEvents;

    // user
    struct user {
        string name;
        string attributes;
        uint64 version;
    }
    mapping (address => user) users;

    // search for user
    struct userRef {
        address user;
    }
    userRef[] userRefs;

    // search for event
    struct eventRef {
        address publisher;
        uint eventId;
    }
    eventRef[] eventRefs;

    // search for user ticket
    struct userTicketRef {
        address publisher;
        uint    eventId;
        uint    ticketId;
    }
    mapping (address => userTicketRef[]) userTicketRefs;

    modifier userRefExists(uint _userRefId) {
        require(_userRefId < userRefs.length);
        _;
    }

    modifier eventRefExists(uint _eventRefId) {
        require(_eventRefId < eventRefs.length);
        _;
    }
    
    modifier userTicketRefExists(address _address, uint _userTicketRefId) {
        require(_userTicketRefId < userTicketRefs[_address].length);
        _;
    }
    
    modifier userExists(address _address) {
        require(bytes(users[_address].name).length != 0);
        _;
    }

    modifier userNotExists(address _address) {
        require(bytes(users[_address].name).length == 0);
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
    
    function getRandomCode() private returns (uint32){ 
        return uint32(getRandom() % 4294967291);
    }

    function ETicketToken() {
        totalSupply = 6000000000000000;
        balances[msg.sender] = totalSupply;
        name = "ETicketToken";
        decimals = 18;
        symbol = "ETT";
    }



    // user ref operation
    function getUserRefsMaxId() 
    returns (uint) {
        return eventRefs.length - 1;
    }

    function getUserRef(uint _userRefId) 
    userRefExists(_userRefId) 
    returns (address) {
        var _user = userRefs[_userRefId].user;
        return _user;        
    }
    
    

    // event ref operation
    function getEventRefsMaxId() 
    returns (uint) {
        return eventRefs.length - 1;
    }

    function getEventRef(uint _eventRefId) 
    eventRefExists(_eventRefId) 
    returns (address, uint) {
        var eventRef = eventRefs[_eventRefId];
        var _publisher = eventRef.publisher;
        var _eventId = eventRef.eventId;
        return (_publisher, _eventId);        
    }



    // user ticket ref operation
    function getUserTicketRefsMaxId()
    returns (uint) {
        return userTicketRefs[msg.sender].length - 1;
    }

    function getUserTicketRef(uint _userTicketRefId) 
    userTicketRefExists(msg.sender, _userTicketRefId) 
    returns (address, uint, uint) {
        var userTicketRef =  userTicketRefs[msg.sender][_userTicketRefId];
        var _publisher = userTicketRef.publisher;
        var _eventId = userTicketRef.eventId;
        var _ticketId = userTicketRef.eventId;
        return (_publisher, _eventId, _ticketId);        
    }



    // user operation
    function getUser(address _address) 
    userExists(_address) 
    returns (string, string, uint64) {
        return (users[_address].name, users[_address].attributes, users[_address].version);
    }

    function createUser(string _name, string _attributes) 
    userNotExists(msg.sender)  {
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("email");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("profile");
        require(_found && !_isNull && _value.length != 0);
        users[msg.sender] = user({
            name: _name,
            attributes: _attributes,
            version:  0
        });
        // create user ref
        userRefs.push(userRef({
            user: msg.sender
        }));
    }

    function modifyUser(string _name, string _attributes) 
    userExists(msg.sender)  {
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("email");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("profile");
        require(_found && !_isNull && _value.length != 0);
        var _user = users[msg.sender];
        _user.name = _name;
        _user.attributes = _attributes;
        _user.version++;
    }



    // publish event operation
    function getPublishEventsMaxId(address _address, uint _eventId) 
    userExists(_address)
    returns (uint) {
        return publishEvents[_address].length - 1;
    }

    function getPublishEvent(address _address, uint _eventId) 
    eventExists(_address, _eventId) 
    returns (string, string, uint32, uint8, uint, uint64) {
        var _event = publishEvents[_address][_eventId];
        return (_event.name, _event.attributes, _event.maxPrice, _event.status, _event.groupCount, _event.version);
    }

    function createPublishEvent(string _name, string _attributes, uint32 _maxPrice) 
    userExists(msg.sender) 
    returns (uint){
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("description");
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
            name: _name,
            attributes: _attributes,
            buyOraclizeUrl: "",
            joinOraclizeUrl: "",
            maxPrice :_maxPrice,
            status: ES_OPENED,
            groupCount: 0,
            version: 0
        }));
        // create event ticket ref
        eventRefs.push(eventRef({
            publisher: msg.sender,
            eventId: _eventId
        }));
        return _eventId;
    }

    function modifyPublishEvent(uint _eventId, string _name, string _attributes, uint32 _maxPrice)
    eventExists(msg.sender, _eventId)  {
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("description");
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
        _event.version++;
    }

    function getOraclizeUrlPublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) 
    returns (string, string) {
        var _event = publishEvents[msg.sender][_eventId];
        return (_event.buyOraclizeUrl, _event.joinOraclizeUrl);
    }
    
    function setOraclizeUrlPublishEvent(uint _eventId, string _buyOraclizeUrl, string _joinOraclizeUrl)
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        _event.buyOraclizeUrl = _buyOraclizeUrl;
        _event.joinOraclizeUrl = _joinOraclizeUrl;
    }
    
    function stopPublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        _event.status = ES_STOPPED;
        _event.version++;
        // XXXXXXX
        // XXX haraimodoshi    最初に売った価格を現在の所有者に返却する
        // XXX owner != publisher  ticket -> cancel
    }

    function closePublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        require(_event.status == ES_OPENED);
        _event.status = ES_CLOSED;
        _event.version++;
    }

    function reopenPublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        require(_event.status == ES_CLOSED);
        _event.status = ES_CLOSED;
        _event.version++;
    }



    // publish event ticket operation
    function getPublishEventTicketsMaxId(address _address, uint _eventId)
    eventExists(_address, _eventId)
    returns (uint) {
        return publishEventTickets[_address][_eventId].length - 1;
    }

    function getPublishEventTicket(address _address, uint _eventId, uint _ticketId) 
    ticketExists(_address, _eventId, _ticketId)
    returns (uint, uint32, string, uint32, uint32, uint8, bool, uint64) {
        var _ticket = publishEventTickets[_address][_eventId][_ticketId];
        require(_address == msg.sender || _address == _ticket.owner);
        return (_ticket.groupId, _ticket.price, _ticket.joinOraclizeResponse, _ticket.buyCode, _ticket.joinCode, _ticket.status, _ticket.sale, _ticket.version);
    }

    function getExtraPublishEventTicket(uint _eventId, uint _ticketId) 
    ticketExists(msg.sender, _eventId, _ticketId) 
    returns (int64, address, string, uint64) {
        var _ticket = publishEventTickets[msg.sender][_eventId][_ticketId];
        return (_ticket.firstSoldPrice, _ticket.owner,  _ticket.buyOraclizeResponse, _ticket.version);
    }

    function createPublishEventTicketGroup(uint _eventId, uint _amount, uint32 _price) 
    eventExists(msg.sender, _eventId) {
        require(_amount != 0);
        var _event = publishEvents[msg.sender][_eventId];
        require(_price <= _event.maxPrice);
        var _groupId = _event.groupCount;
        for (uint i = 0; i < _amount; i++) {
            var _ticketId = publishEventTickets[msg.sender][_eventId].length;
            publishEventTickets[msg.sender][_eventId].push(publishEventTicket({
                groupId: _groupId,
                owner: msg.sender,
                firstSoldPrice: -1,
                price: _price,
                buyOraclizeResponse: "",
                joinOraclizeResponse: "",
                buyCode : getRandomCode(),
                joinCode : 0,
                status: TS_BUY,
                sale: true,
                version: 0
            }));
            // create user ticket ref
            userTicketRefs[msg.sender].push(userTicketRef ({
                publisher: msg.sender,
                eventId: _eventId,
                ticketId: _ticketId
            }));
            _event.groupCount++;
        }
    }

    function getSummaryPublishEventTickets() {
        // validCount
        // joinCount
        // maxprice
        // minprice
        // totalPrice
        // ticketCount
    }
    
    
    
    
    // ticket operation
    function buyTicket() {
        
    }

    function buyTicketWithCode() {
        
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
    
}



