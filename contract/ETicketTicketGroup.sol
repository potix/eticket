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

    function creatableAndModifiableTicketGroup(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _state = ETicketEvent.getEventState(_db, _eventId);
        return _state.includesState(ETicketEvent.getEventStatusCreatableAndModiableTicketGroup());
    }
    
    function getTicketGroupState(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint32) {
        return ETicketDB(_db).getUint32(sha3("ticketGroups", _ticketGroupId, "state"));
    }
    
    function getSalableTickets(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint256) {
        var supplyTickets = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "suplyTickets"));
        var soldTickets = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"));
        return supplyTickets.sub(soldTickets);
    }

    function existsAndOwnerTicketGroup(ETicketDB _db, uint256 _userId, uint256 _eventId, uint256 _ticketGroupId) internal returns (bool) {
        return (ETicketEvent.existsAndOwnerEvent(_db, _userId, _eventId) &&
            (getTicketGroupState(_db, _ticketGroupId) != 0) &&
            (ETicketDB(_db).getUint32(sha3("ticketGroups", _ticketGroupId, "userId")) != _userId));
    }

    function existsTicketGroup(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId) internal returns (bool) {
        return (ETicketEvent.existsEvent(_db, _eventId) &&
            (getTicketGroupState(_db, _ticketGroupId)  != 0));
    }

    function getMaxPrice(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint256) {
        return ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "maxPrice"));
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
        var _user = ETicketUser.getSenderUser(_db);
        require(ETicketEvent.existsAndOwnerEvent(_db, _user.userId, _eventId));
        _ticketGroupId = createTicketGroupCommon(_db, _user.userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
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
        var _user = ETicketUser.getSenderUser(_db);
        require(ETicketEvent.existsAndOwnerEvent(_db, _user.userId, _eventId));
        _ticketGroupId = createTicketGroupCommon(_db, _user.userId, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupId, "state"), TGST_UNSALABLE);
    }
    
    function setTicketGroupName(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId, string _name) returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        require(Validation.validStringLength(_name, 1, 100));        
        ETicketDB(_db).setString(sha3("ticketGroups", _ticketGroupId, "name"), _name);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
    }
    
    function setTicketGroupDescription(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId, string _description) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        require(Validation.validStringLength(_description, 1, 3000));
        ETicketDB(_db).setString(sha3("ticketGroups", _ticketGroupId, "description"), _description);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function addTicketGroupSupplyTickets(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId, uint256 _addSupplyTickets) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        require(_addSupplyTickets > 0);
        ETicketDB(_db).addUint256(sha3("ticketGroups", _ticketGroupId, "supplyTickets"), _addSupplyTickets);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function subTicketGroupSupplyTickets(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId, uint256 _subSupplyTickets) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        require(_subSupplyTickets > 0);
        var _salableTicket = getSalableTickets(_db, _ticketGroupId);
        require(_salableTicket >= _subSupplyTickets);
        ETicketDB(_db).subUint256(sha3("ticketGroups", _ticketGroupId, "supplyTickets"), _subSupplyTickets);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function setTicketGroupMaxPrice(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId, uint256 _maxPrice) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        require(_maxPrice > 0);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
    }
    
    function setTicketGroupPrice(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId, uint256 _price) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        require(getMaxPrice(_db, _ticketGroupId) >= _price);
        ETicketDB(_db).setUint256(sha3("ticketGroups", _ticketGroupId, "price"), _price);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
    }

    function startTicketGroupSalable(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        var _state =  getTicketGroupState(_db, _ticketGroupId);
        require(_state.equalsState(TGST_UNSALABLE));
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupId, "state"),  _state.changeState(TGST_UNSALABLE, TGST_SALABLE));
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売開始する
    }
    
    function stopTicketGroupUnsalable(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId) internal returns (bool) {
        var _user = ETicketUser.getSenderUser(_db);
        require(existsAndOwnerTicketGroup(_db, _user.userId, _eventId, _ticketGroupId));
        require(creatableAndModifiableTicketGroup(_db, _eventId));
        var _state =  getTicketGroupState(_db, _ticketGroupId);
        require(_state.equalsState(TGST_SALABLE));
        ETicketDB(_db).setUint32(sha3("ticketGroups", _ticketGroupId, "state"), _state.changeState(TGST_SALABLE, TGST_UNSALABLE));
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId,  "version"));
        return true;
        // チケットグループを個別に販売停止する
    }
}
