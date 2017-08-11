pragma solidity ^0.4.14;

import "./Validation.sol";
import "./State.sol";
import "./ETicketUser.sol";
import "./ETicketEvent.sol";
import "./ETicketDB.sol";
import "./TokenDB.sol";

library EticketEvent {
    using State for uint32;  
    using SafeMath for uint256;  





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

    uint32 constant TGST_UNSALABLE = 0x01;
    uint32 constant TGST_SALABLE   = 0x02;

    function ticketGroupExists(uint256 _userId, uint256 _eventId, uint256 _ticketGroupId) private {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        require(_state != 0);
    }
    
    function createTicketGroupCommon(
        ETicketDB _db,
        uint256 _userId,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) private returns (uint256) {
        validStringLength(_name, 1, 100);        
        validStringLength(_description, 1, 3000);
        require(_maxPrice >= _price);
        // イベントのステータスチェック
        var _state = EticketEvent.getEventState(_db, _eventId);
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        
        var _ticketGroupId = TicketDB(ticketDB).getAndIncrementId(sha3("ticketGroupId"));
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

    function createTicketGroupWithSalable(
        ETicketDB _db,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) returns (uint256 _ticketGroupId) {
        var _user = EticketUser.getSenderUser(_db);
        require(EticketEvent.existsAndOwnerEvent(_db, _user.userId, _eventId));
        _ticketGroupId = createTicketGroupCommon(_db, _user.userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        TicketDB(ticketDB).setUint32(sha3("ticketGroups", _ticketGroupId, "state"), TGST_SALABLE);
    }
    
    function createTicketGroupWithUnsalable(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price) onlyOwnerUser() returns (uint256) {
        var _user = EticketUser.getSenderUser(_db);
        require(EticketEvent.existsAndOwnerEvent(_db, _user.userId, _eventId));
        _ticketGroupId = createTicketGroupCommon(_db, _user.userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        TicketDB(ticketDB).setUint32(sha3("ticketGroups", _ticketGroupId, "state"), TGST_UNSALABLE);
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
    
}

