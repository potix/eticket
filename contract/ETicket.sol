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
        uint ticketId;
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
    mapping (uint => mapping(uint => mapping(uint => publishEventTicket))) publishEventTickets;

    // publish event
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
        uint maxPrice;
        uint8 status; // 1 stopped, 2 closed
        uint lastTicketGroupId;
        uint lastTicketId;
        uint version;
    }
    mapping(uint => mapping(uint => publishEvent)) publishEvents;

    // ticket
    struct userTicket {
        uint userTicketId;
        uint userId;
        uint eventId;
        uint ticketId;
    }
    mapping (uint => mapping(uint => userTicket)) userTickets;

    // user
    struct user {
        uint userId;
        string name;
        string email;
        string description;
        uint lastPublishEventId;
        uint lastUserTicketId;
        uint version;
    }
    mapping (address => user) users;
    uint lastUserId;

    // search for event
    struct eventSearch {
        uint eventSearchId;
        uint userId;
        uint eventId;
    }
    mapping (uint => eventSearch) eventsSearch;
    uint lastEventSearchId;


    modifier userExists(address _address) {
        require(bytes(users[_address].name).length != 0);
        _;
    }

    modifier userNotExists(address _address) {
        require(bytes(users[_address].name).length == 0);
        _;
    }

    modifier eventExists(address _address, uint _eventId) {
        var _user = users[_address];
        require(bytes(_user.name).length != 0);
        require(bytes(publishEvents[_user.userId][_eventId].name).length != 0);
    }

    modifier ticketExists(address _address, uint _eventId, uint _ticketId) {
        var _user = users[_address];
        require(bytes(_user.name).length != 0);
        require(bytes(publishEvents[_user.userId][_eventId].name).length != 0);
        require(publishEventTickets[_userId][_eventId][_ticketId].owner != address(0));
    }

    function ETicket() {
        totalSupply = 6000000000000000;
        balances[msg.sender] = totalSupply;
        name = "ETicketToken";
        decimals = 18;
        symbol = "ETT";
    }

    // user operation
    function getLastUserId() returns (uint _lastUserId) {
        return lastUserId;
    }

    function getUserVersion() userExists(msg.sender) returns (uint8 _version) {
        return users[msg.sender].version;
    }

    function getUser() userExists(msg.sender) returns (string _name, string _email, string _description, uint _version) {
        return (users[msg.sender].name, users[msg.sender].email, users[msg.sender].description, users[msg.sender].version);
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
            description: _description,
            lastEventId: 0,
            version: 0
        });
        lastUserId++;
    }

    function modifyUser(string _name, string _email, string _description) userExists(msg.sender)  {
        require(bytes(_name).length != 0 && bytes(_email).length != 0);
        users[msg.sender].name = _name;
        users[msg.sender].email = _email;
        users[msg.sender].description = _description;
        users[msg.sender].version++;
    }

    // search operation
    function getLastEventSearchId() returns (uint _eventSearchId) {
        return lastEventSearchId; 
    }

    function getEventSearchVersion(uint _eventSearchId) returns (uint _version) {
        require(_eventSearchId < lastEventSearchId);
        var _userId = eventsSearch[eventSearchId].userId;
        var _eventId = eventsSearch[eventSearchId].eventId;
        return publishEvents[_userId][_eventId].version;
    }

    function getEventSearch(uint _eventSearchId) returns  (string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _version) {
        require(_eventSearchId < lastEventSearchId);
        var _userId = eventsSearch[eventSearchId].userId;
        var _eventId = eventsSearch[eventSearchId].eventId;
        _name = publishEvents[_userId][_eventId].name;
        _description = publishEvents[_userId][_eventId].description;
        _tags = publishEvents[_userId][_eventId].tags;
        _startDateTime = publishEvents[_userId][_eventId].startDateTime;
        _endDateTime = publishEvents[_userId][_eventId].endDateTime;
        _place = publishEvents[_userId][_eventId].place;
        _mapLink = publishEvents[_userId][_eventId].mapLink;
        _version = publishEvents[_userId][_eventId].version;
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
    function getPublishEventVersion(uint _eventId) eventExists(msg.sender, _eventId) returns (uint _version) {
        var _userId = users[msg.sender].userId;
        return publishEvents[_userId][_eventId].version;
    }

    function getPublishEvent(uint _eventId) eventExists(msg.sender, _eventId) returns (string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _version) {
        var _userId = users[msg.sender].userId;
        _name = publishEvents[_userId][_eventId].name;
        _description = publishEvents[_userId][_eventId].description;
        _tags = publishEvents[_userId][_eventId].tags;
        _startDateTime = publishEvents[_userId][_eventId].startDateTime;
        _endDateTime = publishEvents[_userId][_eventId].endDateTime;
        _place = publishEvents[_userId][_eventId].place;
        _mapLink = publishEvents[_userId][_eventId].mapLink;
        _version = publishEvents[_userId][_eventId].version;
    }
    
    function createPublishEvent(string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _maxPrice) userExists(msg.sender) returns (uint _eventId){
        require(bytes(_name).length != 0);
        var _userId = users[msg.sender].userId;
        _publishEventId = users[msg.sender].lastPublishEventId;
        publishEvents[_userId][_eventId] = publishEvent ({
            eventId: _publishEventId,
            publishTime: block.timestamp,
            name: _name,
            description: _description,
            tags: _tags,
            startDateTime: _startDateTime,
            endDateTime: _endDateTime,
            place: _place,
            mapLink: _mapLink,
            maxPrice: _maxPrice,
            stop: false,
            lastTicketGroupId: 0,
            lastTicketSerialNumber: 0,
            version: 0
        });
        users[msg.sender].lastPublishEventId++;

        // for search
        eventsSearch[lastEventSearchId] = eventSearch({
            eventSearchId: lastEventSearchId,
            userId: _userId,
            eventId: _publishEventId
        });
        lastEventSearchId++;
    }

    function modifyPublishEvent(uint _eventId, string _name, string _description, string _tags, string _startDateTime, string _endDateTime, string _place, string _mapLink, uint _maxPrice) eventExists(msg.sender, _eventId)  {
        require(bytes(name).length != 0);
        var _userId = users[msg.sender].userId;
        publishEvents[_userId][_eventId].name = _name;
        publishEvents[_userId][_eventId].description = _description;
        publishEvents[_userId][_eventId].tags = _tags;
        publishEvents[_userId][_eventId].startDateTime = _startDateTime;
        publishEvents[_userId][_eventId].endDateTime = _endDateTime;
        publishEvents[_userId][_eventId].place = _place;
        publishEvents[_userId][_eventId].mapLink = _mapLink;
        publishEvents[_userId][_eventId].maxPrice = _maxPrice;
        publishEvents[_userId][_eventId].version++;
    }

    function stopPublishEvent(uint _eventId) eventExists(msg.sender, _eventId) {
        var _userId = users[msg.sender].userId;
        publishEvents[_userId][_eventId].status = 1;
        publishEvents[_userId][_eventId].version++;
        // XXX haraimodoshi    最初に売った価格を現在の所有者に返却する
        // XXX ticket cancel
    }

    function closePublishEvent(uint _eventId) eventExists(msg.sender, _eventId) {
        var _userId = users[msg.sender].userId;
        publishEvents[_userId][_eventId].status = 1;
        publishEvents[_userId][_eventId].version++;
        // XXX ticket expire

    }

    // publish event ticket operation
    function getPublishEventLastTicketId(uint _eventId) eventExists(msg.sender, _eventId) returns (uint _lastTicketId) {
        var _userId = users[msg.sender].userId;
        return publishEvents[_userId][_eventId].lastTicketId;
    }

    function getPublishEventTicketVersion(uint _eventId, uint _ticketId) ticketExists(msg.sender, _eventId, _ticketId) returns (uint _version) {
        var _userId = users[msg.sender].userId;
        return publishEventTickets[_userId][_eventId][_ticketId].version;
    }

    function getPublishEventTicket(uint _eventId, uint _ticketId) ticketExists(msg.sender, _eventId, _ticketId) returns (uint _ticketGroupId, uint _salePrice, bool _sale, uint _firstSoldPrice, address _owner, uint8 _status, uint _version) {
        var _userId = users[msg.sender].userId;
        _ticketGroupId =  publishEventTickets[_userId][_eventId][_ticketId].ticketGroupId;
        _salePrice = publishEventTickets[_userId][_eventId][_ticketId].salePrice;
        _sale = publishEventTickets[_userId][_eventId][_ticketId].dale;
        _firstSoldPrice = publishEventTickets[_userId][_eventId][_ticketId].firstSoldPrice;
        _owner = publishEventTickets[_userId][_eventId][_ticketId].owner;
        _status = publishEventTickets[_userId][_eventId][_ticketId].status;
        _version = publishEventTickets[_userId][_eventId][_ticketId].version;
    }

    function createPublishEventTicket(uint _eventId, uint _amount, uint _price) eventExists(msg.sender, _eventId)  returns (uint _total) {
        return createPublishEventTicketGroup(1, _amount, _price);
    }

    function createPublishEventTicketGroup(uint _eventId, uint _unit, uint _amount, uint _price) eventExists(msg.sender, _eventId)  returns (uint _total) {
        require(_unit != 0 && _amount != 0);
        var _user = users[msg.sender];
        var _userId = _user.userId;
        _total = 0;
        for (uint i = 0; i < _amount; i++) {
            var _ticketGroupId = publishEvents[_userId][_eventId].lastTicketGroupId;
            for (uint j = 0; j < _unit; j++) {
                // create publish event ticker
                var _ticketId = publishEvents[_userId][_eventId].lastTicketId;
                publishEventTickets[_userId][_eventId][_ticketId] = publishEventTicket ({
                    ticketId: _ticketId,
                    ticketGroupId: _ticketGroupId,
                    salePrice: _price,
                    sale: true,
                    firstSoldPrice: 0,
                    publisher: msg.sender,
                    owner: msg.sender,
                    status: 0,
                    version: 0
                });
                publishEvents[_userId][_eventId].lastTicketId++;
                // create user ticket
                var _userTicketId = _user.lastUserTicketId;
                userTickets[_userId][_userTicketId] = userTicket ({
                    userTicketId: _userTicketId,
                    userId: _userId,
                    eventId: _eventId,
                    ticketId: _ticketId
                });
                _total++;
            }
            publishEvents[_userId][_eventId].lastTicketGroupId++;
        }
    }

    function discardPublishEventTicketGroup() {
        
    }

    function discardPublichEventTicket() {
        
    }
    
}
