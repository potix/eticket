pragma solidity ^0.4.14;

import "./TicketInterface.sol";
import "./Token.sol";
import "./State.sol";
import "./TicketDB.sol";

contract Ticket is TicketInterface, Token {
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

    // [user] 
    // userId
    // users <userId> "address"
    // users <userId> "name"
    // users <userId> "email"
    // users <userId> profile
    // users <userId> version
    // idMap <address> <userId>
    
    function userExists(uint256 _userId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "state"));
        require(_state != 0);
    }

    function onlyOwnerUser(uint256 _userId) private {
        var _address = TicketDB(ticketDB).getAddress(sha3("users", _userId, "address"));
        require(msg.sender == _address);
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

    function setUserName(string _name) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        validStringLength(_name, 1, 100);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "name"), _name);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
        return true;
    }

    function setUserEmail(string _email) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        validStringLength(_email, 0, 100);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "email"), _email);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
        return true;
    }

    function setUserProfile(string _profile) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
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

    uint32 constant EVST_CREATE  = 0x01;
    uint32 constant EVST_SALE    = 0x02;
    uint32 constant EVST_OPEN    = 0x04;
    uint32 constant EVST_READY   = 0x08;
    uint32 constant EVST_STOP    = 0x10;
    uint32 constant EVST_CLOSE   = 0x20;
    uint32 constant EVST_COLLECT = 0x40;

    function eventExists(uint256 _userId, uint256 _eventId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state != 0);
    }

    function createEvent(string _name, string _country, string _description) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        var _eventId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId"));
        validStringLength(_name, 1, 200);        
        validStringLength(_country, 1, 3);        
        validStringLength(_description, 0, 15000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "country"), _country);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "description"), _description);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "amountSold"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "readyTimestamp"), 0);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), EVST_CREATE);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        var _eventRefId = TicketDB(ticketDB).getAndIncrementId(sha3("eventRegId"));
        TicketDB(ticketDB).setUint256(sha3("eventRefs", _eventRefId, "userId"), _userId);
        TicketDB(ticketDB).setUint256(sha3("eventRefs", _eventRefId, "eventId"), _eventId);
        return _eventId;
    }

    function setEventName(uint256 _eventId, string _name) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        validStringLength(_name, 1, 200);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "name"), _name);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventCountry(uint256 _eventId, string _country) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        validStringLength(_country, 1, 3);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "country"), _country);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventDescription(uint256 _eventId, string _description) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        validStringLength(_description, 0, 15000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "description"), _description);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventReserveOracleUrl(uint256 _eventId, string _reserveOracleUrl) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        validStringLength(_reserveOracleUrl, 0, 2000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "reserveOracleUrl"), _reserveOracleUrl);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventEnterOracleUrl(uint256 _eventId, string _enterOracleUrl) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        validStringLength(_enterOracleUrl, 0, 2000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "enterOracleUrl"), _enterOracleUrl);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function setEventCashbackOracleUrl(uint256 _eventId, string _cashbackOracleUrl) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        validStringLength(_cashbackOracleUrl, 0, 2000);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "cashbackOracleUrl"), _cashbackOracleUrl);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
    }

    function saleEvent(uint256 _eventId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_OPEN));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_CREATE|EVST_OPEN), EVST_SALE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // チケットが販売できるようになる
    }

    function openEvent(uint256 _eventId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_SALE|EVST_READY), EVST_OPEN));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // reserveがenter,cashbackできるようになる
    }

    function readyEvent(uint256 _eventId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_OPEN|EVST_CLOSE));
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "readyTimestamp"), now);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // 1日後cancelができなくなる
    }

    function stopEvent(uint256 _eventId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
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

    function closeEvent(uint256 _eventId) returns (bool) { 
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
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

   function collectAmountSold(uint256 _eventId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
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
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALE_START 0x02 STOP_STOP ]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> version
    // == related ==
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]

    uint32 constant TGST_SALE_START = 0x01;
    uint32 constant TGST_SALE_STOP  = 0x02;

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
        uint256 _price) returns (uint256) {
        onlyOwnerUser(_userId);
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
        uint256 _price) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _ticketGroupId = createTicketGroupCommon(_userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), TGST_SALE_START);
        return _ticketGroupId;
    }
    
    function createTicketGroupWithNotSale(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        var _ticketGroupId = createTicketGroupCommon(_userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), TGST_SALE_STOP);
        return _ticketGroupId;
    }
    
    function setTicketGroupName(uint256 _eventId, uint256 _ticketGroupId, string _name) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        validStringLength(_name, 1, 100);        
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "name"), _name);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }
    
    function setTicketGroupDescription(uint256 _eventId, uint256 _ticketGroupId, string _description) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        validStringLength(_description, 1, 3000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "description"), _description);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function addTicketGroupSupplyTickets(uint256 _eventId, uint256 _ticketGroupId, uint256 _addSupplyTickets) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        require(_addSupplyTickets > 0);
        TicketDB(ticketDB).addUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "supplyTickets"), _addSupplyTickets);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function subTicketGroupSupplyTickets(uint256 _eventId, uint256 _ticketGroupId, uint256 _subSupplyTickets) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
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

    function setTicketGroupMaxPrice(uint256 _eventId, uint256 _ticketGroupId, uint256 _maxPrice) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        // maxPriceをpriceより小さくして設定するとpriceの値がmaxPriceより大きくなることがあるけど許容する
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function setTicketGroupPrice(uint256 _eventId, uint256 _ticketGroupId, uint256 _price) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
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
    
    function stopTicketGroupSale(uint256 _eventId, uint256 _ticketGroupId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        _state =  TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state.equalsState(TGST_SALE_START));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), _state.changeState(TGST_SALE_START, TGST_SALE_STOP));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売停止する
    }

    function startTicketGroupSale(uint256 _eventId, uint256 _ticketGroupId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        _state =  TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state.equalsState(TGST_SALE_STOP));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"),  _state.changeState(TGST_SALE_STOP, TGST_SALE_START));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売開始する
    }

    // == create/modify ==
    // [ticketBuyer]
    // userId <userId> eventId <eventId> ticketGroupId <ticketGroupId> buyerId
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> buyer(userId)
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> buyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> reservedTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> buyPrioce
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> totalCashBackPrice
    // [userBuyTicket]
    // userId <userId> buyTicketId
    // users <userId> buyTickets >buyTicketId> eventOwner(userId)
    // users <userId> buyTickets >buyTicketId> eventId
    // users <userId> buyTickets >buyTicketId> ticketGroupId
    // users <userId> buyTickets >buyTicketId> buyerId
    // == related == 
    // [event]
    // users <userId> events <eventId> amountSold
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // [ticket group]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> supplyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> soldTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> price
    // users <userId> events <eventId> ticketGroups <ticketGroupId> admountSold
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALE 0x02 STOP ] 

    function buyTicketValidate(uint256 _eventOwner, uint256 _eventId,  uint256 _ticketGroupId, uint256 _amount) returns (bool, string) {
        userExists(_eventOwner);
        eventExists(_eventOwner, _eventId);
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // イベントのステートチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_OPEN|EVST_READY));
        // チケットグループのステータスチェック
        _state =  TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state.equalsState(TGST_SALE_START));
        // amountが0ではない
        require(_amount > 0);
        // 残りチケット枚数を確認
        var _supplyTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"));
        var _soldTickets =  TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"));
        if (_supplyTickets.sub(_soldTickets) < _amount) {
            // 売り切れ
            return (false, "sold out");
        }   
        // 買い手の所持金確認
        var _price = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "price"));
        var _balance = TokenDB(tokenDB).getBalance(msg.sender);
        var _totalPrice = _price.mul(_amount);
        if (_balance < _totalPrice) {
            // 資金不足
            return (false "no enough funds");
        }
        return (true, "");      
    }

    function buyTicket(uint256 _eventOwner, uint256 _eventId,  uint256 _ticketGroupId, uint256 _amount) returns (bool, string) {
        var (result, message) = buyTicketValidate(_eventOwner, _eventId, _ticketGroupId, _amount);
        if (!result) {
            return (result, message);
        }
        var _price = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "price"));
        var _totalPrice = _price.mul(_amount);
        // buyer情報を作る
        // reservedTicketsとtotalCashBackPriceは必要になってから作る
        var _buyerId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _eventOwner, "eventId", _eventId, "ticketGroupId", _ticketGroupId, "buyerId"));        
        var _buyerUser = TicketDB(ticketDB).getIdMap(msg.sender);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "buyers", _buyerId, "buyer"), _buyerUser);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "buyers", _buyerId, "buyTickets"), _amount);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "buyers", _buyerId, "buyPrioce"), _price);
        // ユーザが買ったチケットを辿れるようにする
        var _buyTicketId =  TicketDB(ticketDB).getAndIncrementId(sha3("userId", _buyerUser, "buyTicketId"));
        TicketDB(ticketDB).setUint256(sha3("users", _buyerUser, "buyTickets", _buyTicketId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _buyerUser, "buyTickets", _buyTicketId, "eventId"), _eventId);
        TicketDB(ticketDB).setUint256(sha3("users", _buyerUser, "buyTickets", _buyTicketId, "ticketGroupId"), _ticketGroupId);
        TicketDB(ticketDB).setUint256(sha3("users", _buyerUser, "buyTickets", _buyTicketId, "buyerId"), _buyerId);
        // ticketGroupの情報更新
        TicketDB(ticketDB).addUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"), _amount);
        // eventの情報更新
        TicketDB(ticketDB).addUint256(sha3("users", _eventOwner, "events", _eventId, "admountSold"), _totalPrice);
        // ユーザからお金を引く
        TokenDB(tokenDB).subBalance(msg.sender, _totalPrice);
    }

    function cancelTicket(uint256 _buyTicketId, uint256 _amount) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);

        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _userId, "buyTickets", _buyTicketId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "buyTickets", _buyTicketId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "buyTickets", _buyTicketId, "ticketGroupId"));
        var buyerId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "buyTickets", _buyTicketId, "buyerId"));

        // イベントのステートチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_OPEN|EVST_STOP|EVST_READY));
        // EVST_READYのばあいは1日以上時間が経過しているとキャンセルできない
        

        // amountが0ではない
        require(_amount > 0);
        

        
        
        eventExists(_userId, _eventId);
        ticketGroupExists(_userId, _eventId, _ticketGroupId);



        // ちけっとをキャンセルする
        // すうまいだけのキャンセルも可能
    }


    // [ticketContext]
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

    // [userTicketCtx]
    // userId <userId> reservedTicketCtxId
    // users <userId> reservedTicketCtxs >reservedTicketCtxId> eventOwner(userId) 
    // users <userId> reservedTicketCtxs >reservedTicketCtxId> eventId
    // users <userId> reservedTicketCtxs >reservedTicketCtxId> ticketCtxId

    function reserveTicket(uint amount) { // まとめてreserveできる
        // 参加予約する
        // reserveするとキャンセルはできなくなる
        // cashbackのアクティベートができるようになる(cachbackのアクティベートしたら他人に売れなくなる)
        // 量をまとめてしていするとシリアル番号は必ず並ぶ
        // oraclizeでreverve記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる
    }

    function transferTicketCtx() { 
        //　チケットコンテキストの所有者変更、無料で他人にゆずる。男前
    }

    function enableSaleTicketCtx(uint32 price) { 
        //　チケットコンテキストをSALABLE状態にする
        // cachebackしてたらsalableの変更はできない
        // 値段は　eventOwnerが設定したmaxPriceを超えられない。残念だったな。
    }

    function disableSaleTicketCtx() { //　チケットコンテキストをSALABLE状態じゃなくす
        // cachebackしてたらsalableの変更はできない
    }

    function buyTicketCtx() { 
        //　チケットコンテキストがSALABLEの場合にチケットを買うことができる
        // end to end で買うとということ
        // だれかに購入に必要な情報を教えてもらわないと、検索して探すのはほぼ無理
    }

    function activateCacheBack() {
        // キャッシュバックコードをoraclizeでなげるとcachebackされる
        // cashbackを受けるともう他人へ売却することはできなくなる、譲渡はできる
    }
    
    function enterTicketCtx() { // 入場記念処置イベンターがやる
        // oraclizeでr入場記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる
        //　ゆずったり、売ったりできなくなる
    }
    

    function refundTicketCtx() {
        
    }

}






