pragma solidity ^0.4.14;

import "./TicketInterface.sol";
import "./Token.sol";
import "./State.sol";
import "./TicketDB.sol";

contract Ticket is TicketInterface, Token {
    using State for uint32;  
    
    address ticketDB;
    
    function Ticket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != 0x0);
        ticketDB = _ticketDB;
    }

    function removeTicketDB() onlyOwner returns (bool) {
        ticketDB = address(0);
        return true;
    }

    // [user] 
    // userId
    // users <userId> "address"
    // users <userId> "name"
    // users <userId> "email"
    // users <userId> profile
    // idMap <address> <userId>

    function isOwnerUser(uint256 _userId) returns (bool) {
        var _address = TicketDB(ticketDB).getAddress(sha3("users", _userId, "address"));
        return (msg.sender == _address);
    }

    function createAndModifyUserCommon(
        uint256 _userId,
        string _name, 
        string _email, 
        string _profile
    ) {
        var b = bytes(_name);
        require(b.length > 0 && b.length <= 100);
        b = bytes(_email);
        require(b.length <= 100);
        b = bytes(_profile);
        require(b.length <= 1000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "email"), _email);
        TicketDB(ticketDB).setString(sha3("users", _userId, "profile"), _profile);
    }

    function createUser(
        string _name, 
        string _email,
        string _profile
        ) returns (uint256) {
        var _userId = TicketDB(ticketDB).getAndIncrementId(sha3("userId"));
        TicketDB(ticketDB).setAddress(sha3("users", _userId, "address"), msg.sender);
        createAndModifyUserCommon(_userId, _name, _email, _profile);
        TicketDB(ticketDB).setIdMap(msg.sender, _userId);
        return _userId;
    }

    function modifyUser(
        string _name, 
        string _email, 
        string _profile
        ) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        createAndModifyUserCommon(_userId, _name, _email, _profile);
        return true;
    }

    // [event] 
    // userId <userId> eventId
    // users <userId> events <eventId> name
    // users <userId> events <eventId> country [ISO_3166-1 alpha-2 or alpha-3]
    // users <userId> events <eventId> tags
    // users <userId> events <eventId> description
    // users <userId> events <eventId> maxPrice
    // users <userId> events <eventId> memorialUrlOfReserved
    // users <userId> events <eventId> memorialOracleUrlOfEntered
    // users <userId> events <eventId> cacheBackOracleUrl
    // users <userId> events <eventId> state [ 0x01 CREATED, 0x02 OPENED, 0x04 STOPPED, 0x08 CLOSED, 0x10 COLLECTED ]
    
    uint32 constant EVST_CREATED   = 0x01;
    uint32 constant EVST_OPENED    = 0x02;
    uint32 constant EVST_STOPPED   = 0x04;
    uint32 constant EVST_CLOSED    = 0x08;
    uint32 constant EVST_COLLECTED = 0x10;

    function isEventExists(uint256 _userId, uint256 _eventId) returns (bool) {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        return (_state != 0);
    }

    function createAndModifyEventCommon(
        uint256 _userId,
        uint256 _eventId,
        string _name, 
        string _country, 
        string _tags, 
        string _description, 
        uint32 _maxPrice, 
        string _memorialUrlOfReserved, 
        string _memorialOracleUrlOfEntered, 
        string _cacheBackOracleUrl
        ) returns (uint256) {
        var b = bytes(_name);
        require(b.length > 0 && b.length <= 200);
        b = bytes(_country);
        require(b.length > 0 && b.length <= 3);
        b = bytes(_tags);
        require(b.length <= 1000);
        b = bytes(_description);
        require(b.length <= 10000);
        b = bytes(_memorialUrlOfReserved);
        require(b.length <= 2000);
        b = bytes(_memorialOracleUrlOfEntered);
        require(b.length <= 2000);
        b = bytes(_cacheBackOracleUrl);
        require(b.length <= 2000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "country"), _country);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "tags"), _tags);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "description"), _description);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "maxPrice"), _maxPrice);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "memorialUrlOfReserved"), _memorialUrlOfReserved);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "memorialOracleUrlOfEntered"), _memorialOracleUrlOfEntered);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "cacheBackOracleUrl"), _cacheBackOracleUrl);
        return _eventId;
    }
    
    function createEvent(
        string _name, 
        string _country, 
        string _tags, 
        string _description, 
        uint32 _maxPrice, 
        string _memorialUrlOfReserved, 
        string _memorialOracleUrlOfEntered, 
        string _cacheBackOracleUrl
        ) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        var _eventId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId"));
        createAndModifyEventCommon(
            _userId,
            _eventId,
            _name, 
            _country, 
            _tags, 
            _description, 
            _maxPrice, 
            _memorialUrlOfReserved, 
            _memorialOracleUrlOfEntered, 
            _cacheBackOracleUrl);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), EVST_OPENED);
        return _eventId;
    }

    function modifyEvent(
        uint256 _eventId,
        string _name, 
        string _country, 
        string _tags, 
        string _description, 
        uint32 _maxPrice, 
        string _memorialUrlOfReserved, 
        string _memorialOracleUrlOfEntered, 
        string _cacheBackOracleUrl
        ) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        createAndModifyEventCommon(
            _userId,
            _eventId,
            _name, 
            _country, 
            _tags, 
            _description, 
            _maxPrice, 
            _memorialUrlOfReserved, 
            _memorialOracleUrlOfEntered, 
            _cacheBackOracleUrl);
        return true;
    }

    // [ticketGroup]
    // users <userId> events <eventId> totalSupplyTickets
    // users <userId> events <eventId> SoldTickets
    // users <userId> events <eventId> buyUsers <userId> buyTickets 








    
}




