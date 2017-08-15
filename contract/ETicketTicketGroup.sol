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

    struct ticketGroup {
        EticketDB _db;
        uint256 ticketGroupId;
        // members
        uint256 userId;
        uint256 eventId;
        string name;
        bytes32 nameSha3;
        string description;
        bytes32 descriptionSha3;
        uint256 supplyTickets;
        uint256 soldTickets;
        uint256 maxPrice;
        uint256 price;
        uint256 lastSerialNumber;
        uint32 state;
        // parent
        ETicketEvent.userEvent userEvent
        // shadows
        uint256 __userId;
        uint256 __eventId;
        bytes32 __nameSha3;
        bytes32 __descriptionSha3;
        uint256 __supplyTickets;
        uint256 __soldTickets;
        uint256 __maxPrice;
        uint256 __price;
        uint256 __lastSerialNumber;
        uint32 __state;
        uint256 __transactionupdateTime;
    }
    
    function _newId(ETicketDB _db) private returns (uint256) {
        return ETicketDB(_db).getAndIncrementId(sha3("ticketGroupId"));   
    }

    function _load(ETicketDB _db, uint256 _ticketGroupId) private returns (ticketGroup _ticketGroup) {
        _ticketGroup.db = _db;
        _ticketGroup._ticketGroupId = _ticketGroupId;
        _ticketGroup.userId = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "userId"));
        _ticketGroup.eventId = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "eventId"));
        // not supported string
        _ticketGroup.nameSha3 = ETicketDB(_db).getStringSha3(sha3("ticketGroups", _ticketGroupId, "name")); 
        _ticketGroup.descriptionSha3 = ETicketDB(_db).getStringSha3(sha3("ticketGroups", _ticketGroupId, "description")); 
        _ticketGroup.supplyTickets = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "supplyTickets")); 
        _ticketGroup.soldTickets = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets")); 
        _ticketGroup.maxPrice = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "maxPrice")); 
        _ticketGroup.price = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "price")); 
        _ticketGroup.lastSerialNumber = ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "lastSerialNumber")); 
        _ticketGroup.state = ETicketDB(_db).getUint32(sha3("ticketGroups", _ticketGroupId, "state")); 
       // set shadows
        _ticketGroup.__userId = _ticketGroup.userId;
        _ticketGroup.__eventId = _ticketGroup.eventId;
        _ticketGroup.__supplyTickets = _ticketGroup.supplyTickets;
        _ticketGroup.__soldTickets = _ticketGroup.soldTickets;
        _ticketGroup.__maxPrice = _ticketGroup.maxPrice;
        _ticketGroup.__price = _ticketGroup.price;
        _ticketGroup.__lastSerialNumber = _ticketGroup.lastSerialNumber;
        _ticketGroup.__state = _ticketGroup.state;
        _ticketGroup.__transactionupdateTime = _ticketGroup.transactionupdateTime;
         require(_ticketGroup.state != 0);
        // parent
        _ticketGroup.userEvent = ETicketEvent.getExistsEvent(_db, _ticketGroup.eventId);
    }

    function _save(ticketGroup _ticketGroup) private returns (bool){
        bool changed = false;
        if (_ticketGroup.userId != _ticketGroup.__userId) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "userId"), _ticketGroup.userId);
            changed = true;
        }
        if (_ticketGroup.eventId != _ticketGroup.__eventId) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "eventId"), _ticketGroup.eventId);
            changed = true;
        }
        if (_ticketGroup.nameSha3 != _ticketGroup.__nameSha3) {
            ETicketDB(_ticketGroup.db).setString(sha3("ticketGroups", _ticketGroup.ticketGroupId, "name"), _ticketGroup.name);
            changed = true;
        }
        if (_ticketGroup.descriptionSha3 != _ticketGroup.__descriptionSha3) {
            ETicketDB(_ticketGroup.db).setString(sha3("ticketGroups", _ticketGroup.ticketGroupId, "description"), _ticketGroup.description);
            changed = true;
        }
        if (_ticketGroup.supplyTickets != _ticketGroup.__supplyTickets) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "supplyTickets"), _ticketGroup.supplyTickets);
            changed = true;
        }
        if (_ticketGroup.soldTickets != _ticketGroup.__soldTickets) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "soldTickets"), _ticketGroup.soldTickets);
            changed = true;
        }
        if (_ticketGroup.maxPrice != _ticketGroup.__maxPrice) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "maxPrice"), _ticketGroup.maxPrice);
            changed = true;
        }
        if (_ticketGroup.price != _ticketGroup.__price) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "price"), _ticketGroup.price);
            changed = true;
        }
        if (_ticketGroup.lastSerialNumber != _ticketGroup.__lastSerialNumber) {
            ETicketDB(_ticketGroup.db).setUint256(sha3("ticketGroups", _ticketGroup.ticketGroupId, "lastSerialNumber"), _ticketGroup.lastSerialNumber);
            changed = true;
        }
        if (_ticketGroup.state != _ticketGroup.__state) {
            ETicketDB(_ticketGroup.db).setUint32(sha3("ticketGroups", _ticketGroup.ticketGroupId, "state"), _ticketGroup.state);
            changed = true;
        }
        if (changed) {
            // XXX TODO event側に関数作るべき
            _ticketGroup.userEvent.ticketGroupUpdateTime = now;
        }
        ETicketEvent.updateEvent(_ticketGroup.userEvent);
        return true;
    }

    function _new(
        ETicketDB _db,
        ETicketEvent.userEvent _userEvent, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        uint32 _state,
        ) private returns (ticketGroup _ticketGroup) {
        _ticketGroup.db = _db;
        _ticketGroup.ticketGroupId = _newId(_db);
        _ticketGroup.userId = _userEvent.user.userId;
        _ticketGroup.eventId = _userEvent.eventId;
        _ticketGroup.name = _name;
        _ticketGroup.nameSha3 = sha3(_name);
        _ticketGroup.description = _description;
        _ticketGroup.descriptionSha3 = sha3(_description);
        _ticketGroup.supplyTickets = _supplyTickets;
        _ticketGroup.soldTickets = 0;
        _ticketGroup.maxPrice = _maxPrice;
        _ticketGroup.price = _price;
        _ticketGroup.state = _state;
        _ticketGroup.userEvent = _userEvent;
        _save(_ticketGroup);
    }





    // struct totalPrice {
    //     uint256 price;
    //     uint256 amount;
    //     uint256 total;
    // }

    // function getTicketGroupState(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint32) {
    //     return ETicketDB(_db).getUint32(sha3("ticketGroups", _ticketGroupId, "state"));
    // }
    
    
    // function getTicketGroupMaxPrice(ETicketDB _db, uint256 _ticketGroupId) internal returns (uint256) {
    //     return ETicketDB(_db).getUint256(sha3("ticketGroups", _ticketGroupId, "maxPrice"));
    // }



    // function ticketGroupStateSalableTicket(ETicketDB _db, uint256 _eventId, uint256 _ticketGroupId) returns (bool) {
    //     var _ticketGroupState = getTicketGroupState(_db, _ticketGroupId); 
    //     return ETicketEvent.eventStateSalableTicket(_db, _eventId) &&
    //         _ticketGroupState.equalsState(TGST_SALABLE);
    // }

    function addSoldTicket(ticketGroup _ticketGroup) internal returns (bool) {
        _ticketGroup
        ETicketDB(_db).addUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"), _addAmount);
        ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId, "version"));
        return true;
    }
    
    // function subSoldTicket(ETicketDB _db, uint256 _ticketGroupId, uint256 _subAmount) internal returns (bool) {
    //     ETicketDB(_db).subUint256(sha3("ticketGroups", _ticketGroupId, "soldTickets"), _subAmount);
    //     ETicketDB(_db).incrementUint256(sha3("ticketGroups", _ticketGroupId, "version"));
    //     return true;
    // }


    function isSalableTicketState(ticketGroup _ticketGroup) returns (bool) {
        return _ticketGroup.state.equalsState(TGST_SALABLE) && ETicketEvent.isSalableTicketState(_ticketGroup.userEvent); 
    }
    
    function getTicketGroupTotalPrice(ticketGroup _ticketGroup, uint256 _amount) internal returns (uint256) {
        return _ticketGroup.price.mul(_amount);
    }

    function getSalableTickets(ticketGroup _ticketGroup) internal returns (uint256) {
        return ticketGroup.supplyTickets.sub(ticketGroup.soldTickets);
    }

    function getExistsTicketGroup(ETicketDB _db, uint256 _ticketGroupId) internal returns (ticketGroup) {
        return _load(_db, _ticketGroupId);
    }

    function getSenderTicketGroup(ETicketDB _db, uint256 _ticketGroupId) internal returns (ticketGroup) {
        var _user = ETicketUser.getSenderUser(_db);
        var _ticketGroup =  _load(_db, _ticketGroupId);
        require(_ticketGroup.userId != _user.userId);
        return _ticketGroup
    }

    function createTicketGroupCommon(
        ETicketDB _db,
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price,
        uint32 _state
        ) private returns (ticketGroup _ticketGroup) {
        require(Validation.validStringLength(_name, 1, 100));        
        require(Validation.validStringLength(_description, 1, 3000));
        require(_maxPrice >= _price);
        var _userEvent = ETicketEvent.getSenderEvent(_db, _eventId); 
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_userEvent));
        var _ticketGroup = _new(_db, _userEvent, _name, _description, _supplyTickets, _maxPrice, _price, _state);
        _save(_ticketGroup);
        return _ticketGroup;
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
        return createTicketGroupCommon(_db, _eventId, _name, _description, _supplyTickets, _maxPrice, _price, TGST_SALABLE);
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
        return createTicketGroupCommon(_db, _eventId, _name, _description, _supplyTickets, _maxPrice, _price, TGST_UNSALABLE);
    }

    function setTicketGroupName(ETicketDB _db, uint256 _ticketGroupId, string _name) returns (bool) {
        require(Validation.validStringLength(_name, 1, 100));        
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        _ticketGroup.name = _name;
        _ticketGroup.nameSha3 = sha3(_name);
        return _save(_ticketGroup);
    }
    
    function setTicketGroupDescription(ETicketDB _db, uint256 _ticketGroupId, string _description) internal returns (bool) {
        require(Validation.validStringLength(_description, 1, 3000));
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        _ticketGroup.description = _description;
        _ticketGroup.descriptionSha3 = sha3(_description);
        return _save(_ticketGroup);
    }

    function addTicketGroupSupplyTickets(ETicketDB _db, uint256 _ticketGroupId, uint256 _addSupplyTickets) internal returns (bool) {
        require(_addSupplyTickets > 0);
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        _ticketGroup.supplyTickets = _ticketGroup.supplyTickets.add(_addSupplyTickets);
        return _save(_ticketGroup);
    }

    function subTicketGroupSupplyTickets(ETicketDB _db, uint256 _ticketGroupId, uint256 _subSupplyTickets) internal returns (bool) {
        require(_subSupplyTickets > 0);
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        require(getSalableTickets(_ticketGroup) >= _subSupplyTickets);
        _ticketGroup.supplyTickets = _ticketGroup.supplyTickets.sub(_subSupplyTickets);
        return _save(_ticketGroup);
    }
    
    function setTicketGroupMaxPrice(ETicketDB _db, uint256 _ticketGroupId, uint256 _maxPrice) internal returns (bool) {
        require(_maxPrice > 0);
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        _ticketGroup.maxPrice = _maxPrice;
        return _save(_ticketGroup);
    }
    
    function setTicketGroupPrice(ETicketDB _db, uint256 _ticketGroupId, uint256 _price) internal returns (bool) {
        require(_price > 0);
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        require(_ticketGroup.maxPrice >= _price);
        _ticketGroup.price = price;
        return _save(_ticketGroup);
    }

    function startTicketGroupSalable(ETicketDB _db, uint256 _ticketGroupId) internal returns (bool) {
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        require(_ticketGroup.state.equalsState(TGST_UNSALABLE));
        _ticketGroup.state = _ticketGroup.state.changeState(TGST_UNSALABLE, TGST_SALABLE);
        return _save(_ticketGroup);
    }
    
    function stopTicketGroupUnsalable(ETicketDB _db, uint256 _ticketGroupId) internal returns (bool) {
        var _ticketGroup = getSenderTicketGroup(_db, _ticketGroupId);
        require(ETicketEvent.isCreatableAndModiableTicketGroupState(_ticketGroup.userEvent));
        require(_ticketGroup.state.equalsState(TGST_SALABLE));
        _ticketGroup.state = _ticketGroup.state.changeState(TGST_SALABLE, TGST_UNSALABLE);
        return _save(_ticketGroup);
    }
}

