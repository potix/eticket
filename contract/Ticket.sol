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

    // utility function
    
    uint256 constant UINT32_MAX = 0xffffffff; 

    function validStringLength(string _value, uint min, uint max) private {
        var b = bytes(_value);
        require(b.length >= min && b.length <= max);
    }

    function validUint256Range(uint256 _value, uint256 min, uint256 max) private {
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
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return true;
        // cancelができなくなる
    }

    function stopEvent(uint256 _eventId) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
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

    // [ticketGroup]
    // userId <userId> eventId <eventId> ticketGroupId
    // users <userId> events <eventId> ticketGroups <ticketGroupId> name
    // users <userId> events <eventId> ticketGroups <ticketGroupId> description
    // users <userId> events <eventId> ticketGroups <ticketGroupId> supplyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> soldTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> maxPrice
    // users <userId> events <eventId> ticketGroups <ticketGroupId> price
    // users <userId> events <eventId> ticketGroups <ticketGroupId> admountSold
    // users <userId> events <eventId> ticketGroups <ticketGroupId> lastSerialNumber
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALE 0x02 STOP ]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> version
    
    uint32 constant TGST_SALE = 0x01;
    uint32 constant TGST_STOP = 0x02;

    function ticketGroupExists(uint256 _userId, uint256 _eventId, uint256 _ticketGroupId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state != 0);
    }

    function createTicketGroup(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint32 _supplyTickets,
        uint32 _maxPrice,
        uint32 _price) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        onlyOwnerUser(_userId);
        eventExists(_userId, _eventId);
        var _ticketGroupId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId", _eventId, "ticketGroupId"));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        validStringLength(_name, 1, 100);        
        validStringLength(_description, 1, 3000);
        validUint256Range(_supplyTickets, 0, UINT32_MAX);        
        validUint256Range(_maxPrice, 0, UINT32_MAX);        
        validUint256Range(_price, 0, UINT32_MAX);        
        require(_maxPrice >= _price);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "description"), _description);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"), _supplyTickets);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "price"), _price);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "amountSold"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "lastSerialNumber"), 0);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), TGST_SALE);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
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
        // 発行上限は超えられない    
        var _supplyTickets = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"));
        require(UINT32_MAX >= _supplyTickets + _addSupplyTickets);
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
        // 現在の発行枚数を超えて減らすことはできない。        
        var _supplyTickets = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"));
        require(_supplyTickets >= _subSupplyTickets);
        //　すでに売れているチケットを超えて減らすことはできあない
        var _soldTickets =  TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"));
        require(_supplyTickets - _subSupplyTickets >= _soldTickets);
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
        validUint256Range(_maxPrice, 0, UINT32_MAX);        
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
        validUint256Range(_price, 0, UINT32_MAX);
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
        require(_state.equalsState(TGST_SALE));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), _state.changeState((TGST_SALE), TGST_STOP));
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
        require(_state.equalsState(TGST_STOP));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"),  _state.changeState((TGST_STOP), TGST_SALE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売開始する
    }

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

    function buyTicket(uint256 _userid, uint256 ticketGroupid) {
        // ちけっとを購入する 
        // groupIdと数量をしていしてまとめて買える
        // 買うごとにbyerIdは新たに発行される
    }
    
    function cancelTicket(uint256 _userid, uint256 groupid, uint256 ticketGroupId, uint256 buyerid, uint256 amount) {
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
    }
    

    function refundTicketCtx() {
        
    }

}






