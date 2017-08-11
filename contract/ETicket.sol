pragma solidity ^0.4.14;

import "./ETicketInterface.sol";
import "./Token.sol";
import "./State.sol";
import "./ETicketDB.sol";

contract ETicket is ETicketInterface, Token {
    using State for uint32;  
    using SafeMath for uint256;   
    
    address ticketDB;
    
    function Ticket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != 0x0);
        ticketDB = _ticketDB;
    }

    function removeTicketDB() onlyOwner returns (bool) {
        ticketDB = address(0);
        return true;
    }

    // common define
    
    uint256 public constant ONE_DAY_SECONDS = 86400;

    // utility function
    function validStringLength(string _value, uint min, uint max) private {
        var b = bytes(_value);
        require(b.length >= min && b.length <= max);
    }

    function validUint256Range(uint256 _value, uint min, uint max) private {
        require(_value >= min && _value <= max);
    }


    // [user] 
    // userId
    // users <userId> "address"
    // users <userId> "name"
    // users <userId> "email"
    // users <userId> profile
    // users <userId> version
    // idMap <address> <userId>

    modifier onlyOwnerUser() {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _address = TicketDB(ticketDB).getAddress(sha3("users", _userId, "address"));
        require(msg.sender == _address);
        _;
    }
    
    function userExists(uint256 _checkUserId) private {
        var _address = TicketDB(ticketDB).getUint32(sha3("users", _checkUserId, "address"));
        var _userId = TicketDB(ticketDB).getIdMap(_address);
        require(_checkUserId == _userId);
    }

    function createUser(string _name, string _email, string _profile) returns (uint256) {
        require(msg.sender != 0x0);
        var _userId = TicketDB(ticketDB).getAndIncrementId(sha3("userId"));
        TicketDB(ticketDB).setAddress(sha3("users", _userId, "address"), msg.sender);
        validStringLength(_name, 1, 100);        
        validStringLength(_email, 0, 100);        
        validStringLength(_profile, 0, 1000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "email"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "profile"), _profile);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
        TicketDB(ticketDB).setIdMap(msg.sender, _userId);
        return _userId;
    }

    function setUserName(string _name) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        validStringLength(_name, 1, 100);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "name"), _name);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
        return true;
    }

    function setUserEmail(string _email) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        validStringLength(_email, 0, 100);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "email"), _email);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
        return true;
    }

    function setUserProfile(string _profile) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        validStringLength(_profile, 0, 1000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "profile"), _profile);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
        return true;
    }

    // == create/modify ==
    // [event] 
    // userId <userId> eventId
    // users <userId> events <eventId> name
    // users <userId> events <eventId> country [ISO_3166-1 alpha-2 or alpha-3]
    // users <userId> events <eventId> tags
    // users <userId> events <eventId> description
    // users <userId> events <eventId> reserveOracleUrl
    // users <userId> events <eventId> enterOracleUrl
    // users <userId> events <eventId> cashBackOracleUrl
    // users <userId> events <eventId> amountSold
    // users <userId> events <eventId> readyTimestamp
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // users <userId> events <eventId> version
    // [event reference]
    // eventRefId
    // eventRefs <eventrefId> eventOwner(userId)
    // eventRefs <eventrefId> eventId
    // eventRefs <eventrefId> state [ 0x01 CREATE ]

    uint32 constant EVST_CREATE  = 0x01;
    uint32 constant EVST_SALE    = 0x02;
    uint32 constant EVST_OPEN    = 0x04;
    uint32 constant EVST_READY   = 0x08;
    uint32 constant EVST_STOP    = 0x10;
    uint32 constant EVST_CLOSE   = 0x20;
    uint32 constant EVST_COLLECT = 0x40;
    uint32 constant EVREFST_CREATE  = 0x01;

    function eventExists(uint256 _userId, uint256 _eventId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state != 0);
    }
    
    function eventRefExists(uint256 _eventRefId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("eventRefs", _eventRefId, "state"));
        require(_state != 0);
    }
    
    function createEventCommon(uint256 _userId, string _name, string _country, string _description) private returns (uint256) {
        var _eventId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId"));
        validStringLength(_name, 1, 200);        
        validStringLength(_country, 1, 3);        
        validStringLength(_description, 0, 15000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "country"), _country);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "description"), _description);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "amountSold"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "readyTimestamp"), 0);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        var _eventRefId = TicketDB(ticketDB).getAndIncrementId(sha3("eventRegId"));
        TicketDB(ticketDB).setUint256(sha3("eventRefs", _eventRefId, "userId"), _userId);
        TicketDB(ticketDB).setUint256(sha3("eventRefs", _eventRefId, "eventId"), _eventId);
        TicketDB(ticketDB).setUint32(sha3("eventRefs", _eventRefId, "state"), EVREFST_CREATE);
        return _eventId;
    }
    
    function createEventWithSale(string _name, string _country, string _description) onlyOwnerUser() returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _eventId = createEventCommon( _userId,  _name,  _country,  _description);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), EVST_SALE);
        return _eventId;
    }

    function createEventWithNotSale(string _name, string _country, string _description) onlyOwnerUser() returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _eventId = createEventCommon( _userId,  _name,  _country,  _description);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), EVST_CREATE);
        return _eventId;
    }

    function setEventName(uint256 _eventId, string _name) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        validStringLength(_name, 1, 200);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "name"), _name);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventCountry(uint256 _eventId, string _country) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        validStringLength(_country, 1, 3);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "country"), _country);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventDescription(uint256 _eventId, string _description) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        validStringLength(_description, 0, 15000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "description"), _description);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventReserveOracleUrl(uint256 _eventId, string _reserveOracleUrl) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        validStringLength(_reserveOracleUrl, 0, 2000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "reserveOracleUrl"), _reserveOracleUrl);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventEnterOracleUrl(uint256 _eventId, string _enterOracleUrl) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        validStringLength(_enterOracleUrl, 0, 2000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "enterOracleUrl"), _enterOracleUrl);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventCashbackOracleUrl(uint256 _eventId, string _cashbackOracleUrl) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        validStringLength(_cashbackOracleUrl, 0, 2000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "cashbackOracleUrl"), _cashbackOracleUrl);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function saleEvent(uint256 _eventId) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_OPEN));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_CREATE|EVST_OPEN), EVST_SALE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // チケットが販売できるようになる
    }

    function openEvent(uint256 _eventId) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_SALE|EVST_READY), EVST_OPEN));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // reserveがenter,cashbackできるようになる
    }

    function readyEvent(uint256 _eventId) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_OPEN|EVST_CLOSE));
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "readyTimestamp"), now);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // 1日後cancelができなくなる
    }

    function stopEvent(uint256 _eventId) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY), EVST_STOP));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // イベントを中止せざるをえなくなったとき
        // reservedとかenterとかcashbackとかとかできなくなる
        // ticketGroupの情報も変更できなくなる
        // すべての購入者へトークンの返却が可能になる
        // 返却は自己申告制
        // reserveしてない人はcancelで
        // reserveしちゃった人はrefundで
        // これ以降の状態変更はない
    }

    function closeEvent(uint256 _eventId) onlyOwnerUser() returns (bool) { 
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_READY));
        // 1日以上経過していないとcloseできない
        var _readyTimestamp = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "readyTimestamp"));
        require(now > _readyTimestamp.add(ONE_DAY_SECONDS));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_READY), EVST_CLOSE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // reservedとかenterとかcashbackとかとかできなくなる
        // ticketGroupの情報も変更できなくなる
    }

   function collectAmountSold(uint256 _eventId) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CLOSE));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_CLOSE), EVST_COLLECT));
        var _amountSold = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "amountSold"));
        TokenDB(tokenDB).addBalance(msg.sender, _amountSold);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // 購入した人のトークンが回収される
        // これをやるまでは状態として記録されているだけ
        // これ以降の状態変更はない
    }

    // == create/modify ==
    // [ticketGroup]
    // userId <userId> eventId <eventId> ticketGroupId
    // users <userId> events <eventId> ticketGroups <ticketGroupId> name
    // users <userId> events <eventId> ticketGroups <ticketGroupId> description
    // users <userId> events <eventId> ticketGroups <ticketGroupId> supplyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> soldTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> maxPrice
    // users <userId> events <eventId> ticketGroups <ticketGroupId> price
    // users <userId> events <eventId> ticketGroups <ticketGroupId> lastSerialNumber
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALABLE 0x02 UNSALABLE ]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> version
    // == related ==
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]

    uint32 constant TGST_SALABLE = 0x01;
    uint32 constant TGST_UNSALABLE  = 0x02;

    function ticketGroupExists(uint256 _userId, uint256 _eventId, uint256 _ticketGroupId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state != 0);
    }
    
    function createTicketGroupCommon(
        uint256 _userId,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) private returns (uint256) {
        eventExists(_userId, _eventId);
        var _ticketGroupId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId", _eventId, "ticketGroupId"));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        validStringLength(_name, 1, 100);        
        validStringLength(_description, 1, 3000);
        require(_maxPrice >= _price);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "description"), _description);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"), _supplyTickets);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "price"), _price);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "lastSerialNumber"), 0);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return _ticketGroupId;
    }

    function createTicketGroupWithSale(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) onlyOwnerUser() returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _ticketGroupId = createTicketGroupCommon(_userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), TGST_SALABLE);
        return _ticketGroupId;
    }
    
    function createTicketGroupWithNotSale(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) onlyOwnerUser() returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _ticketGroupId = createTicketGroupCommon(_userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), TGST_UNSALABLE);
        return _ticketGroupId;
    }
    
    function setTicketGroupName(uint256 _eventId, uint256 _ticketGroupId, string _name) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        validStringLength(_name, 1, 100);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "name"), _name);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }
    
    function setTicketGroupDescription(uint256 _eventId, uint256 _ticketGroupId, string _description) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        validStringLength(_description, 1, 3000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "description"), _description);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function addTicketGroupSupplyTickets(uint256 _eventId, uint256 _ticketGroupId, uint256 _addSupplyTickets) onlyOwnerUser()  returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        require(_addSupplyTickets > 0);
        TicketDB(ticketDB).addUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "supplyTickets"), _addSupplyTickets);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function subTicketGroupSupplyTickets(uint256 _eventId, uint256 _ticketGroupId, uint256 _subSupplyTickets) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        require(_subSupplyTickets > 0);
        // すでに売れているチケットを超えて減らすことはできない
        var _supplyTickets = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"));
        var _soldTickets =  TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"));
        require(_supplyTickets.sub(_subSupplyTickets) >= _soldTickets);
        TicketDB(ticketDB).subUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "supplyTickets"), _subSupplyTickets);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function setTicketGroupMaxPrice(uint256 _eventId, uint256 _ticketGroupId, uint256 _maxPrice) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        // maxPriceをpriceより小さくして設定するとpriceの値がmaxPriceより大きくなることがあるけど許容する
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function setTicketGroupPrice(uint256 _eventId, uint256 _ticketGroupId, uint256 _price) onlyOwnerUser()  returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        // maxPriceは超えられない
        var _maxPrice = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "maxPrice"));
        require(_maxPrice >= _price);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "price"), _price);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function startTicketGroupSalable(uint256 _eventId, uint256 _ticketGroupId) onlyOwnerUser() returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        _state =  TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state.equalsState(TGST_UNSALABLE));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"),  _state.changeState(TGST_UNSALABLE, TGST_SALABLE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売開始する
    }
    
    function stopTicketGroupUnsalable(uint256 _eventId, uint256 _ticketGroupId) onlyOwnerUser()  returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        _state =  TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state.equalsState(TGST_SALABLE));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), _state.changeState(TGST_SALABLE, TGST_UNSALABLE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売停止する
    }


    // == create/modify ==
    // [transaction]
    // userId <userId> eventId <eventId> ticketGroupId <ticketGroupId> txnId
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> buyer(userId)
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> buyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> reservedTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> buyPrioce
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> totalCashBackPrice
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> state [ 0x01 SALABLE 0x02 UNSALABLE ]
    // [userBuyTicket]
    // userId <userId> txnRefId
    // users <userId> txnRefs <txnRefId> eventOwner(userId)
    // users <userId> txnRefs <txnRefId> eventId
    // users <userId> txnRefs <txnRefId> ticketGroupId
    // users <userId> txnRefs <txnRefId> txnId
    // users <userId> txnRefs <txnRefId> state [ 0x01 CREATE]
    // == related == 
    // [event]
    // users <userId> events <eventId> amountSold
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // [ticket group]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> supplyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> soldTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> price
    // users <userId> events <eventId> ticketGroups <ticketGroupId> admountSold
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALABLE 0x02 UNSALABLE ] 
    
    uint32 constant TXNST_SALABLE = 0x01;
    uint32 constant TXNST_UNSALABLE = 0x01;
    uint32 constant TXNREF_CREATE  = 0x01;
    uint256 MAX_BUYABLE_TICKETS = 20;
    
    function txnExists(uint256 _userId, uint256 _eventId, uint256 _ticketGroupId, uint256 _txnId) {
        var state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state")); 
        require(state != 0);
    }

    function txnRefExists(uint256 _userId, uint256 _txnRefId) {
        var state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "txnRefs", _txnRefId, "state"));
        require(state != 0);
    }
    
    function buyTicketValidate(uint256 _eventOwner, uint256 _eventId,  uint256 _ticketGroupId, uint256 _amount) private returns (bool, string, uint256) {
        //　イベントオーナーの存在チェック
        userExists(_eventOwner);
        // イベントの存在チェック
        eventExists(_eventOwner, _eventId);
        // チケットグループの存在チェッぃ
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // イベントのステートチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_OPEN|EVST_READY));
        // チケットグループのステータスチェック
        _state =  TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state.equalsState(TGST_SALABLE));
        // amountが1から20の間 (1回の購入で買えるのは20枚まで)
        validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS);
        // チケットグループの残りチケット枚数を確認
        var _supplyTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "supplyTickets"));
        var _soldTickets =  TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"));
        if (_supplyTickets.sub(_soldTickets) < _amount) {
            // 売り切れ
            return (false, "sold out", 0);
        }   
        // 買い手の所持金確認
        var _price = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "price"));
        var _balance = TokenDB(tokenDB).getBalance(msg.sender);
        var _totalPrice = _price.mul(_amount);
        if (_balance < _totalPrice) {
            // 資金不足
            return (false "no enough funds", 0);
        }
        return (true, "", _price);      
    }

    function buyTicket(uint256 _eventOwner, uint256 _eventId,  uint256 _ticketGroupId, uint256 _amount) returns (bool, string) {
        // イベントオーナーからチケットを買う
        var (result, message, _price) = buyTicketValidate(_eventOwner, _eventId, _ticketGroupId, _amount);
        if (!result) {
            return (result, message);
        }
        var _totalPrice = _price.mul(_amount);
        // チケットグループに取引情報を作成する
        var _buyer = TicketDB(ticketDB).getIdMap(msg.sender);
        var _txnId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _eventOwner, "eventId", _eventId, "ticketGroupId", _ticketGroupId, "txnId"));        
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyer"), _buyer);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"), _amount);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyPrioce"), _price);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "reservedTickets"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "totalCashBackPrice"), 0);
        TicketDB(ticketDB).setUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state"), TXNST_UNSALABLE);
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "version"));
        // ユーザー情報に取引情報への参照を作成する
        var _txnRefId =  TicketDB(ticketDB).getAndIncrementId(sha3("userId", _buyer, "txnRefId"));
        TicketDB(ticketDB).setUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventId"), _eventId);
        TicketDB(ticketDB).setUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "ticketGroupId"), _ticketGroupId);
        TicketDB(ticketDB).setUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "txnId"), _txnId);
        TicketDB(ticketDB).setUint32(sha3("users", _buyer, "txnRefs", _txnRefId, "state"), TXNREF_CREATE);
        // ticketGroupの情報更新
        TicketDB(ticketDB).addUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"), _amount);
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "version"));
        // eventの情報更新
        TicketDB(ticketDB).addUint256(sha3("users", _eventOwner, "events", _eventId, "admountSold"), _totalPrice);
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "version"));
        // ユーザからお金を引く
        TokenDB(tokenDB).subBalance(msg.sender, _totalPrice);
    }
    
    function setBuyTicketSalable(uint256 _txnRefId) onlyOwnerUser() {
        // 取引情報をのステータスをSALABLEにする
        // ユーザー情報のトランザクションへの参照が存在するか確認
        var _buyer = TicketDB(ticketDB).getIdMap(msg.sender);
        txnRefExists(_buyer, _txnRefId);
        // 必要な情報の取り出し
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "txnId"));
        // イベントオーナーの存在確認
        userExists(_eventOwner);
        // イベントの存在確認
        eventExists(_eventOwner, _eventId);
        // チケットの存在確認
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // 取引情報の存在確認
        txnExists(_eventOwner, _eventId, _ticketGroupId, _txnId);
        // 現在UNSALABLEであること
        var state =  TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state"));
        require(state.ewualsState(TXNST_UNSALABLE));
        // ステータスの変更
        TicketDB(ticketDB).setUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state"), state.changeState(TXNST_UNSALABLE, TXNST_SALABLE));
        // versionの更新
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "version"));
    }

    function setBuyTicketUnsalable(uint256 _buyTicketId) onlyOwnerUser() {
        // 取引情報をのステータスをSALABLEにする
        // ユーザー情報のトランザクションへの参照が存在するか確認
        var _buyer = TicketDB(ticketDB).getIdMap(msg.sender);
        txnRefExists(_buyer, _txnRefId);
        // 必要な情報の取り出し
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "txnId"));
        // イベントオーナーの存在確認
        userExists(_eventOwner);
        // イベントの存在確認
        eventExists(_eventOwner, _eventId);
        // チケットの存在確認
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // 取引情報の存在確認
        txnExists(_eventOwner, _eventId, _ticketGroupId, _txnId);
        // 現在UNSALABLEであること
        var state =  TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state"));
        require(state.ewualsState(TXNST_SALABLE));
        // ステータスの変更
        TicketDB(ticketDB).setUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state"), state.changeState(TXNST_SALABLE, TXNST_UNSALABLE));
        // versionの更新
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "version"));
    }
    
    function buyTicketFromBuyer(uint256 _buyer, uint256 _txnRefId, uint256 _amount) returns (bool, string) {
        // すでに買ってある人からチケットをかう
        // 買い手の存在チェック
        userExists(_buyer);
        // 買い手の取引情報への参照が存在するかチェック
        txnRefExists(_buyer, _txnRefId);
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "txnId"));
        // イベントオーナーの存在チェック
        userExists(_eventOwner);
        // イベントの存在チェック
        eventExists(_eventOwner, _eventId);
        // チケットグループの存在チェック
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // トランザクション情報の存在チェック
        txnExists(_eventOwner, _eventId, _ticketGroupId, _txnId);
        // イベントステータスのチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_OPEN|EVST_READY));
        // 取引情報のステータスがSALABLEであること
        _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "state"));
        require(_state = TXNST_SALABLE)
        // amountが0ではない
        require(_amount > 0);
        // 買った量を超えて購入することはできない
        // reserveした分は買えない
        var _buyTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"));
        var _reservedTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "reservedTickets")); 
        if (_buyTickets.sub(_reservedTickets) < _amount) {
            // 売り切れ    
            return (false "sold out");
        }
        // 新たな買い手の所持金確認
        var _buyPrice = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyPrice"));
        var _balance = TokenDB(tokenDB).getBalance(msg.sender);
        var _totalPrice = _buyPrice.mul(_amount);
        if (_balance < _totalPrice) {
            // 資金不足
            return (false "no enough funds");
        }
        // チケットグループに新しい取引情報の作成
        var _newBuyer = TicketDB(ticketDB).getIdMap(msg.sender);
        var _newTxnId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _eventOwner, "eventId", _eventId, "ticketGroupId", _ticketGroupId, "txnId"));        
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "buyer"), _newBuyer);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "buyTickets"), _amount);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "buyPrioce"), _buyPrice);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "reservedTickets"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "totalCashBackPrice"), 0);
        TicketDB(ticketDB).setUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "state"), TXNST_UNSALABLE);
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _newTxnId, "version"));
        // 新しい買い手に、新しい取引情報への参照を作成
        var _newTxnRefId =  TicketDB(ticketDB).getAndIncrementId(sha3("userId", _newBuyer, "txnRefId"));
        TicketDB(ticketDB).setUint256(sha3("users", _newBuyer, "txnRefs", _newTxnRefId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _newBuyer, "txnRefs", _newTxnRefId, "eventId"), _eventId);
        TicketDB(ticketDB).setUint256(sha3("users", _newBuyer, "txnRefs", _newTxnRefId, "ticketGroupId"), _ticketGroupId);
        TicketDB(ticketDB).setUint256(sha3("users", _newBuyer, "txnRefs", _newTxnRefId, "txnId"), _newTxnId);
        TicketDB(ticketDB).setUint32(sha3("users", _newBuyer, "txnRefs", _newTxnRefId, "state"), TXNREF_CREATE);
        // 元の取引情報を更新する
        TicketDB(ticketDB).subUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"), amount); 
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "version"));
        // 元の買い手の所持金を増やす
        var _buyerAddress = TicketDB(ticketDB).getUint32(sha3("users", _buyer, "address"));
        TokenDB(tokenDB).addBalance(_buyerAddress, _totalPrice);
        // 新たな書いての所持金を減らす
        TokenDB(tokenDB).subBalance(msg.sender, _totalPrice);
    }
    
    function cancelTicketValidate(uint256 _txnRefId, uint256 _amount) private 
        returns (uint256 _eventOwner, uint256 _eventId, uint256 _ticketGroupId, uint256 _txnId){
        // ユーザの取引への参照情報が存在するか確認
        var _buyer = TicketDB(ticketDB).getIdMap(msg.sender);
        txnRefExists(_buyer, _txnRefId);
        // 必要な情報を取り出す
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "txnRefs", _txnRefId, "txnId"));
        // イベントオーナーの存在チェック
        userExists(_eventOwner);
        // イベントの存在チェック
        eventExists(_eventOwner, _eventId);
        // チケットグループの存在チェック
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // トランザクション情報の存在チェック
        txnExists(_eventOwner, _eventId, _ticketGroupId, _txnId);
        // イベントのステートチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_OPEN|EVST_STOP|EVST_READY));
        // EVST_READYのばあいは1日以上時間が経過しているとキャンセルできない
        if (_state.equalsState(EVST_READY)) {
            var _readyTimestamp = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "readyTimestamp"));
            require(now <= _readyTimestamp.add(ONE_DAY_SECONDS));  
        }
        // amountが0ではない
        require(_amount > 0);
        // 買った量を超えてcancelできない
        // reserveした分はキャンセルできない
        var _buyTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"));
        var _reservedTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "reservedTickets")); 
        require(_buyTickets.sub(_reservedTickets) >= _amount);
    }

    function cancelTicket(uint256 _txnRefId, uint256 _amount) onlyOwnerUser() {
        // チケットをキャンセルする
        var (_eventOwner, _eventId, _ticketGroupId, _txnId) = cancelTicketValidate(_txnRefId, _amount); 
        // キャンセル可能
        var _price = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyPrioce"));
        var _totalPrice =  _price.mul(_amount);
        // 取引情報の更新
        // 購入チケットを減らす
        TicketDB(ticketDB).subUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"), _amount); 
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "version"));
        // ticketGroupの情報更新
        TicketDB(ticketDB).subUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"), _amount);
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "version"));
        // eventの情報更新
        TicketDB(ticketDB).subUint256(sha3("users", _eventOwner, "events", _eventId, "admountSold"), _totalPrice);
        TicketDB(ticketDB).incrementUint256(sha3("users", _eventOwner, "events", _eventId, "version"));
        // ユーザにお金を戻す
        TokenDB(tokenDB).addBalance(msg.sender, _totalPrice);
    }

    // == create/modify ==
    // [ticketContexts]
    // users <userId> events <eventId> ticketCtxId
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> eventOwner(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> eventId
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> ticketGroupId
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> buyer(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> prevTicketOwner(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> ticketOwner(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> reservedUrl
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> EnteredUrl
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> cashBackPrice
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> enterCode
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> serialNumber
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> BuyPrice
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> salePrice
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> state [ 0x10 SALABLE, 0x01 RESERVED, 0x02 ENTERD ]
    // [reservedTicketCcontexts]
    // userId <userId> ticketCtxRefId
    // users <userId> ticketCtxRefs <ticketCtxRefId> eventOwner(userId) 
    // users <userId> ticketCtxRefs <ticketCtxRefId> eventId
    // users <userId> ticketCtxRefs <ticketCtxRefId> ticketCtxId
    // users <userId> ticketCtxRefs <ticketCtxRefId> state [ 0x01 CREATE ]
    // == related == 
    // [transaction]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> buyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> reservedTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> txns <txnId> state [ 0x01 CREATE ]
    // [userBuyTicket]
    // userId <userId> txnRefId
    // users <userId> txnRefs <txnRefId> eventOwner(userId)
    // users <userId> txnRefs <txnRefId> eventId
    // users <userId> txnRefs <txnRefId> ticketGroupId
    // users <userId> txnRefs <txnRefId> txnId
    // users <userId> txnRefs <txnRefId> state [ 0x01 CREATE]
    // [event]
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // [ticket group]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> lastSerialNumber
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALE 0x02 STOP ] 

    function reserveTicketValidation(uint256 _txnRefId, uint256 _amount) private {
        // トランザクションの参照情報の存在確認
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        txnRefExists(_userId, _txnRefId);
        // 必要な情報の取り出し
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "txnId"));
        // イベントオーナーの存在チェック
        userExists(_eventOwner);
        // イベントの存在チェック
        eventExists(_eventOwner, _eventId);
        // チケットグループの存在チェック
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // トランザクション情報の存在チェック
        txnExists(_eventOwner, _eventId, _ticketGroupId, _txnId);
        // イベントのステートチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_OPEN|EVST_READY));
        // 買った量を超えてreserveできない
        // もうすでにreserveしてる分も差し引く
        var _buyTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"));
        var _reservedTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "reservedTickets")); 
        require(_buyTickets.sub(_reservedTickets) >= _amount);
    }

    function reserveTicket(uint256 _buyTicketId, uint256 _amount) onlyOwnerUser() { 
        // チケットを参加予約する
        reserveTicketValidation(_buyTicketId, _amount); 
        var _buyer = TicketDB(ticketDB).getIdMap(msg.sender);
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "txnId"));        
 
        // ticketコンテキスト作成
        var _ticketCtxId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _eventOwner, "eventId", _eventId, "ticketCtxId"));        
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);

        
        
        
        // まとめてreserveできる
        // 参加予約する
        // reserveするとキャンセルはできなくなる
        // cashbackのアクティベートができるようになる(cachbackのアクティベートしたら他人に売れなくなる)
        // 量をまとめてしていするとシリアル番号は必ず並ぶ
        // oraclizeでreverve記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる

    }

    function transferTicketCtx() onlyOwnerUser() { 
        //　チケットコンテキストの所有者変更、無料で他人にゆずる。男前
    }

    function enableSaleTicketCtx(uint32 price) onlyOwnerUser() { 
        //　チケットコンテキストをSALABLE状態にする
        // cachebackしてたらsalableの変更はできない
        // 値段は　eventOwnerが設定したmaxPriceを超えられない。残念だったな。
    }

    function disableSaleTicketCtx() onlyOwnerUser() { //　チケットコンテキストをSALABLE状態じゃなくす
        // cachebackしてたらsalableの変更はできない
    }

    function buyTicketCtx() { 
        //　チケットコンテキストがSALABLEの場合にチケットを買うことができる
        // end to end で買うとということ
        // だれかに購入に必要な情報を教えてもらわないと、検索して探すのはほぼ無理
    }

    function activateCacheBack() onlyOwnerUser() {
        // キャッシュバックコードをoraclizeでなげるとcachebackされる
        // cashbackを受けるともう他人へ売却することはできなくなる、譲渡はできる
    }
    
    function enterTicketCtx() { // 入場記念処置イベンターがやる
        // oraclizeでr入場記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる
        //　ゆずったり、売ったりできなくなる
    }
    

    function refundTicketCtx() onlyOwnerUser() {
        // stop後の払い戻し
    }

}






