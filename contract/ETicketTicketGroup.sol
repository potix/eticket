pragma solidity ^0.4.14;

import "./Validation.sol";
import "./State.sol";
import "./ETicketUser.sol";
import "./ETicketEvent.sol";
import "./ETicketDB.sol";
import "./TokenDB.sol";

library ETicketTicketGroup {
    using State for uint32;  
    using SafeMath for uint256;  

    // == create/modify ==
    // [ticketGroup]
    // ticketGroupId
    // ticketGroups <ticketGroupId> userId
    // ticketGroups <ticketGroupId> eventId
    // ticketGroups <ticketGroupId> name
    // ticketGroups <ticketGroupId> description
    // ticketGroups <ticketGroupId> supplyTickets
    // ticketGroups <ticketGroupId> soldTickets
    // ticketGroups <ticketGroupId> maxPrice
    // ticketGroups <ticketGroupId> price
    // ticketGroups <ticketGroupId> lastSerialNumber
    // ticketGroups <ticketGroupId> state [ 0x01 SALABLE 0x02 UNSALABLE ]
    // ticketGroups <ticketGroupId> version
    // == related ==
    // events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]

    uint32 constant TGST_UNSALABLE = 0x01;
    uint32 constant TGST_SALABLE   = 0x02;

    struct ticketGroupInfo {
        uint256 userId;
        uint256 eventId;
        uint256 ticketGroupId;
    }

    struct totalPrice {
        uint256 price;
        uint256 amount;
        uint256 total;
    }
    
    function getTicketGroupStateSalableTicket() returns (uint32) {
        return TGST_SALABLE;
    }

    function creatableAndModifiableTicketGroup(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _state = ETicketEvent.getEventState(_db, _eventId);
        return _state.includesState(ETicketEvent.getEventStateCreatableAndModiableTicketGroup());
    }
    
    function getTicketGroupState(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint32) {
        return ETicketDB(_db).getUint32(sha3("ticketGroups", _ticketGroupId, "state"));
    }
    
    function getSalableTickets(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint256) {
        var supplyTickets = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "suplyTickets"));
        var soldTickets = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"));
        return supplyTickets.sub(soldTickets);
    }

    function getOwnerTicketGroupInfo(ETicketDB _db, uint256 _userId, uint256 _ticketGroupId) internal returns (ticketGroupInfo _ticketGroupInfo) {
        require(getTicketGroupState(_db, _ticketGroupId) != 0);
        require(ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "userId")) == _userId);
        var _eventInfo = ETicketEvent.getOwnerEventInfo(_db, _userId, ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "eventId")));
        _ticketGroupInfo.userId = _userId;
        _ticketGroupInfo.eventId = _eventInfo.eventId;
        _ticketGroupInfo.ticketGroupId = _ticketGroupId;
    }

    function getMaxPrice(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint256) {
        return ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "maxPrice"));
    }
    
    function getTotalPrice(ETicketDB _db, uint256 _ticketGroupId, uint256 _amount) internal returns (totalPrice _totalPrice) {
        _totalPrice.price = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "price"));
        _totalPrice.amount = _amount;
        _totalPrice.total = _totalPrice.price.mul(_amount);
    }
    
    function addSoldTicket(ETicketDB _db, uint256 _ticketGroupId, uint256 _addAmount) internal returns (bool) {
        ETicketDB(_db).addUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"), _addAmount);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId, "version"));
        return true;
    }
    
    function subSoldTicket(ETicketDB _db, uint256 _ticketGroupId, uint256 _subAmount) internal returns (bool) {
        ETicketDB(_db).subUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"), _subAmount);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId, "version"));
        return true;
    }
    
    function createTicketGroupCommon(
        ETicketDB _db,
        uint256 _userId,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) private returns (uint256) {
        require(Validation.validStringLength(_name, 1, 100));        
        require(Validation.validStringLength(_description, 1, 3000));
        require(_maxPrice >= _price);
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        var _ticketGroupId = ETicketDB(_db).getAndIncrementId(sha3("ticketGroupId"));
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "userId"), _userId);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "eventId"), _eventId);
        ETicketDB(_db).setString(sha3("ticketGroups", _ticketGroupId, "name"), _name);
        ETicketDB(_db).setString(sha3("ticketGroups", _ticketGroupId, "description"), _description);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "suplyTickets"), _supplyTickets);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "price"), _price);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"), 0);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "lastSerialNumber"), 0);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return _ticketGroupId;
    }

    function createTicketGroupWithSalable(
        ETicketDB _db,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) internal returns (uint256 _ticketGroupId) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = ETicketEvent.getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        _ticketGroupId = createTicketGroupCommon(_db, _userInfo.userId, _eventInfo.eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupId, "state"), TGST_SALABLE);
    }
    
    function createTicketGroupWithUnsalable(
        ETicketDB _db,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) returns (uint256 _ticketGroupId) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = ETicketEvent.getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        _ticketGroupId = createTicketGroupCommon(_db, _userInfo.userId, _eventInfo.eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupId, "state"), TGST_UNSALABLE);
    }
    
    function setTicketGroupName(ETicketDB _db, uint256 _ticketGroupId, string _name) returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        require(Validation.validStringLength(_name, 1, 100));        
        ETicketDB(_db).setString(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "name"), _name);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
    }
    
    function setTicketGroupDescription(ETicketDB _db, uint256 _ticketGroupId, string _description) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        require(Validation.validStringLength(_description, 1, 3000));
        ETicketDB(_db).setString(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "description"), _description);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
    }

    function addTicketGroupSupplyTickets(ETicketDB _db, uint256 _ticketGroupId, uint256 _addSupplyTickets) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        require(_addSupplyTickets > 0);
        ETicketDB(_db).addUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "supplyTickets"), _addSupplyTickets);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
    }

    function subTicketGroupSupplyTickets(ETicketDB _db, uint256 _ticketGroupId, uint256 _subSupplyTickets) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        require(_subSupplyTickets > 0);
        var _salableTicket = getSalableTickets(_db, _ticketGroupInfo.ticketGroupId);
        require(_salableTicket >= _subSupplyTickets);
        ETicketDB(_db).subUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "supplyTickets"), _subSupplyTickets);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
    }

    function setTicketGroupMaxPrice(ETicketDB _db, uint256 _ticketGroupId, uint256 _maxPrice) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        require(_maxPrice > 0);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "maxPrice"), _maxPrice);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
    }
    
    function setTicketGroupPrice(ETicketDB _db, uint256 _ticketGroupId, uint256 _price) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        require(getMaxPrice(_db, _ticketGroupInfo.ticketGroupId) >= _price);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "price"), _price);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
    }

    function startTicketGroupSalable(ETicketDB _db, uint256 _ticketGroupId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        var _state =  getTicketGroupState(_db, _ticketGroupInfo.ticketGroupId);
        require(_state.equalsState(TGST_UNSALABLE));
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "state"),  _state.changeState(TGST_UNSALABLE, TGST_SALABLE));
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売開始する
    }
    
    function stopTicketGroupUnsalable(ETicketDB _db, uint256 _ticketGroupId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _ticketGroupInfo = getOwnerTicketGroupInfo(_db, _userInfo.userId, _ticketGroupId);
        require(creatableAndModifiableTicketGroup(_db, _ticketGroupInfo.eventId));
        var _state =  getTicketGroupState(_db, _ticketGroupInfo.ticketGroupId);
        require(_state.equalsState(TGST_SALABLE));
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId, "state"), _state.changeState(TGST_SALABLE, TGST_UNSALABLE));
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupInfo.ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売停止する
    }
}

