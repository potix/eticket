pragma solidity ^0.4.14;

import "./Validation.sol";
import "./State.sol";
import "./ETicketUser.sol";
import "./ETicketDB.sol";
import "./TokenDB.sol";

library ETicketEvent {
    using State for uint32;  
    using SafeMath for uint256;  

    // == create/modify ==
    // [event] 
    // eventId
    // events <eventId> userId
    // events <eventId> name
    // events <eventId> country [ISO_3166-1 alpha-2 or alpha-3]
    // events <eventId> description
    // events <eventId> reserveOracleUrl
    // events <eventId> enterOracleUrl
    // events <eventId> cashBackOracleUrl
    // events <eventId> amountSold
    // events <eventId> readyTimestamp
    // events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // events <eventId> ticketGroupUPdateTime

    uint256 public constant WAIT_SECONDS = 90000;

    uint32 public constant EVST_CREATE  = 0x01;
    uint32 public constant EVST_SALE    = 0x02;
    uint32 public constant EVST_OPEN    = 0x04;
    uint32 public constant EVST_READY   = 0x08;
    uint32 public constant EVST_STOP    = 0x10;
    uint32 public constant EVST_CLOSE   = 0x20;
    uint32 public constant EVST_COLLECT = 0x40;
    
    struct userEvent {
        ETicketDB db;
        uint256 eventId;
        // members
        uint256 userId;
        string name;
        string country;
        string description;
        string reserveOracleUrl;
        string enterOracleUrl;
        string cashbackOracleUrl;
        uint256 amountSold;
        uint256 readyTime;
        uint32 state;
        uint256 ticketGroupUPdateTime;
        // parent
        ETicketUser.user user;
        // shadows
        uint256 __userId;
        uint256 __amountSold;
        uint256 __readyTime;
        uint32 __state;
        uint256 __ticketGroupUPdateTime;
    }

    function _newId(ETicketDB _db) private returns (uint256) {
        return ETicketDB(_db).getAndIncrementId(sha3("eventId"));   
    }

    function _load(ETicketDB _db, uint256 _eventId) private returns (userEvent _userEvent) {
        _userEvent.db = _db;
        _userEvent.eventId = _eventId;
        _userEvent.userId = ETicketDB(_db).getUint256(sha3("events", _eventId, "userId"));
        // not supported string
        //_userEvent.name = ETicketDB(_db).getString(sha3("events", _eventId, "name")); 
        //_userEvent.country = ETicketDB(_db).getString(sha3("events", _eventId, "country")); 
        //_userEvent.description = ETicketDB(_db).getString(sha3("events", _eventId, "description")); 
        //_userEvent.reserveOracleUrl = ETicketDB(_db).getString(sha3("events", _eventId, "reserveOracleUrl")); 
        //_userEvent.enterOracleUrl = ETicketDB(_db).getString(sha3("events", _eventId, "enterOracleUrl")); 
        //_userEvent.cashbackOracleUrl = ETicketDB(_db).getString(sha3("events", _eventId, "cashbackOracleUrl")); 
        _userEvent.amountSold = ETicketDB(_db).getUint256(sha3("events", _eventId, "amountSold")); 
        _userEvent.readyTime = ETicketDB(_db).getUint256(sha3("events", _eventId, "readyTime")); 
        _userEvent.state = ETicketDB(_db).getUint32(sha3("events", _eventId, "state")); 
        _userEvent.ticketGroupUPdateTime = ETicketDB(_db).getUint256(sha3("events", _eventId, "ticketGroupUPdateTime")); 
        // set shadows
        _userEvent.__userId = _userEvent.userId;
        _userEvent.__amountSold = _userEvent.amountSold;
        _userEvent.__readyTime = _userEvent.readyTime;
        _userEvent.__state = _userEvent.state;
        _userEvent.__ticketGroupUPdateTime = _userEvent.ticketGroupUPdateTime;
        // parent
        _userEvent.user = ETicketUser.getExistsUser(_db, _userEvent.userId);
    }

    function _save(userEvent _userEvent) private returns (bool){
        bool changed = false;
        if (_userEvent.userId != _userEvent.__userId) {
            ETicketDB(_userEvent.db).setUint256(sha3("events", _userEvent.eventId, "userId"), _userEvent.userId);
            changed = true;
        }
        if (bytes(_userEvent.name).length != 0) {
            ETicketDB(_userEvent.db).setString(sha3("events", _userEvent.eventId, "name"), _userEvent.name);
            changed = true;
        }
        if (bytes(_userEvent.country).length != 0) {
            ETicketDB(_userEvent.db).setString(sha3("events", _userEvent.eventId, "country"), _userEvent.country);
            changed = true;
        }
        if (bytes(_userEvent.description).length != 0) {
            ETicketDB(_userEvent.db).setString(sha3("events", _userEvent.eventId, "description"), _userEvent.description);
            changed = true;
        }
        if (bytes(_userEvent.reserveOracleUrl).length != 0) {
            ETicketDB(_userEvent.db).setString(sha3("events", _userEvent.eventId, "reserveOracleUrl"), _userEvent.reserveOracleUrl);
            changed = true;
        }
        if (bytes(_userEvent.enterOracleUrl).length != 0) {
            ETicketDB(_userEvent.db).setString(sha3("events", _userEvent.eventId, "enterOracleUrl"), _userEvent.enterOracleUrl);
            changed = true;
        }
        if (bytes(_userEvent.cashbackOracleUrl).length != 0) {
            ETicketDB(_userEvent.db).setString(sha3("events", _userEvent.eventId, "cashbackOracleUrl"), _userEvent.cashbackOracleUrl);
            changed = true;
        }
        if (_userEvent.amountSold != _userEvent.__amountSold) {
            ETicketDB(_userEvent.db).setUint256(sha3("events", _userEvent.eventId, "amountSold"), _userEvent.amountSold);
            changed = true;
        }
        if (_userEvent.readyTime != _userEvent.__readyTime) {
            ETicketDB(_userEvent.db).setUint256(sha3("events", _userEvent.eventId, "readyTime"), _userEvent.readyTime);
            changed = true;
        }
        if (_userEvent.state != _userEvent.__state) {
            ETicketDB(_userEvent.db).setUint32(sha3("events", _userEvent.eventId, "state"), _userEvent.state);
            changed = true;
        }
        if (_userEvent.ticketGroupUPdateTime != _userEvent.__ticketGroupUPdateTime) {
            ETicketDB(_userEvent.db).setUint256(sha3("events", _userEvent.eventId, "ticketGroupUPdateTime"), _userEvent.ticketGroupUPdateTime);
            changed = true;
        }
        if (changed) {
            // XXX TODO user側に関数作るべき
            _userEvent.user.eventUpdateTime = now;
        }
        ETicketUser.update(_userEvent.user);
        return true;
    }

    function _new(
        ETicketDB _db, 
        ETicketUser.user _user, 
        string _name, 
        string _country, 
        string _description,
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashbackOracleUrl,
        uint32 _state
        ) private returns (userEvent _userEvent) {
        _userEvent.db = _db;
        _userEvent.eventId = _newId(_db);
        _userEvent.userId = _user.userId;
        _userEvent.name = _name;
        _userEvent.country = _country;
        _userEvent.description = _description;
        _userEvent.reserveOracleUrl = _reserveOracleUrl;
        _userEvent.enterOracleUrl = _enterOracleUrl;
        _userEvent.cashbackOracleUrl = _cashbackOracleUrl;
        _userEvent.amountSold = 0;
        _userEvent.readyTime = now;
        _userEvent.state = _state;
        _userEvent.ticketGroupUPdateTime = now;
        _userEvent.user = _user;
        _save(_userEvent);
    }

    function getExistsEventInfo(ETicketDB _db, uint256 _eventId) internal returns (userEvent) {
        var _userEvent = _load(_db, _eventId);
        require(_userEvent.state != 0);
        return _userEvent;
    }

    function getSenderEvent(ETicketDB _db,  uint256 _eventId) internal returns (userEvent) {
        var user = ETicketUser.getSenderUser(_db);
        var _userEvent = _load(_db, _eventId);
        require(_userEvent.state != 0);
        require(_userEvent.userId != user.userId);
        return _userEvent;
    }




    

    // function eventStateCreatableAndModiableTicketGroup(userEvent _userEvent) internal returns (bool) {
    //     var _state = getEventState(_db, _eventId);
    //     return _state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY);
    // }

    // function eventStateSalableTicket(ETicketDB _db, uint256 _eventId) internal returns (bool) {
    //     var _state = getEventState(_db, _eventId);
    //     return _state.includesState(EVST_SALE|EVST_OPEN|EVST_READY);
    // }

    // function eventStateModiableTransaction(ETicketDB _db, uint256 _eventId) internal returns (bool) {
    //     var _state = getEventState(_db, _eventId);
    //     return _state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY);
    // }
    
    // function eventStateCancelableTicket(ETicketDB _db, uint256 _eventId) internal returns (bool) {
    //     var _state = getEventState(_db, _eventId);
    //     if (!_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY|EVST_STOP)) {
    //         return false;
    //     }
    //     if (_state.equalsState(EVST_READY)) {
    //         var _readyTimestamp = getEventReadyTimestamp(_db, _eventId);
    //         if (now <= _readyTimestamp.add(WAIT_SECONDS)) {
    //             return false;
    //         }  
    //     }
    //     return true;
    // }

    // function addAmountSold(ETicketDB _db, uint256 _eventId, uint256 _addAmountSold) internal returns (bool) {
    //     ETicketDB(_db).addUint256(sha3("events", _eventId, "admountSold"), _addAmountSold);
    //     ETicketDB(_db).incrementUint256(sha3("events", _eventId, "version"));
    //     return true;
    // }

    // function subAmountSold(ETicketDB _db, uint256 _eventId, uint256 _subAmountSould) internal returns (bool) {
    //     ETicketDB(_db).subUint256(sha3("events", _eventId, "admountSold"), _subAmountSould);
    //     ETicketDB(_db).incrementUint256(sha3("events", _eventId, "version"));
    //     return true;
    // }






    function createEventCommon(
        ETicketDB _db, 
        string _name, 
        string _country, 
        string _description,
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashbackOracleUrl,
        uint32 _state
        ) private returns (userEvent) {
        require(Validation.validStringLength(_name, 1, 200));        
        require(Validation.validStringLength(_country, 1, 3));        
        require(Validation.validStringLength(_description, 0, 15000)); 
        var _user = ETicketUser.getSenderUser(_db);
        var _userEvent = _new(_db, _user, _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashbackOracleUrl, _state);
        _save(_userEvent);
        return _userEvent;        
    }
    
    function createEventWithSalable(
        ETicketDB _db, 
        string _name, 
        string _country, 
        string _description,
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashbackOracleUrl
        ) internal returns (userEvent) {
        return createEventCommon(_db, _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashbackOracleUrl, EVST_SALE);
    }

    function createEventWithUnsalable(
        ETicketDB _db,
        string _name, 
        string _country, 
        string _description,
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashbackOracleUrl
        ) internal returns (userEvent) {
        return createEventCommon(_db, _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashbackOracleUrl, EVST_CREATE);
    }

    function setEventName(ETicketDB _db, uint256 _eventId, string _name) internal returns (bool) {
        require(Validation.validStringLength(_name, 1, 200));        
        var _userEvent = getSenderEvent(_db, _eventId);
        _userEvent.name = _name;
        return _save(_userEvent);
    }

    function setEventCountry(ETicketDB _db, uint256 _eventId, string _country) internal returns (bool) {
        require(Validation.validStringLength(_country, 1, 3));        
        var _userEvent = getSenderEvent(_db, _eventId);
        _userEvent.country = _country;
        return _save(_userEvent);
    }

    function setEventDescription(ETicketDB _db, uint256 _eventId, string _description) internal returns (bool) {
        require(Validation.validStringLength(_description, 0, 15000));
        var _userEvent = getSenderEvent(_db, _eventId);
        _userEvent.description = _description;
        return _save(_userEvent);
    }

    function setEventReserveOracleUrl(ETicketDB _db, uint256 _eventId, string _reserveOracleUrl) internal returns (bool) {
        require(Validation.validStringLength(_reserveOracleUrl, 0, 2000));        
        var _userEvent = getSenderEvent(_db, _eventId);
        _userEvent.reserveOracleUrl = _reserveOracleUrl;
        return _save(_userEvent);
    }

    function setEventEnterOracleUrl(ETicketDB _db, uint256 _eventId, string _enterOracleUrl) internal returns (bool) {
        require(Validation.validStringLength(_enterOracleUrl, 0, 2000));        
        var _userEvent = getSenderEvent(_db, _eventId);
        _userEvent.enterOracleUrl = _enterOracleUrl;
        return _save(_userEvent);
    }

    function setEventCashbackOracleUrl(ETicketDB _db, uint256 _eventId, string _cashbackOracleUrl) internal returns (bool) {
        require(Validation.validStringLength(_cashbackOracleUrl, 0, 2000));        
        var _userEvent = getSenderEvent(_db, _eventId);
        _userEvent.cashbackOracleUrl = _cashbackOracleUrl;
        return _save(_userEvent);
    }
    
    function saleEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userEvent = getSenderEvent(_db, _eventId);
        require(_userEvent.state.includesState(EVST_CREATE|EVST_OPEN));
        _userEvent.state.changeState((EVST_CREATE|EVST_OPEN), EVST_SALE);
        return _save(_userEvent);
    }

    function openEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userEvent = getSenderEvent(_db, _eventId);
        require(_userEvent.state.includesState(EVST_SALE|EVST_READY));
        _userEvent.state.changeState((EVST_SALE|EVST_READY), EVST_OPEN);
        return _save(_userEvent);
    }

    function readyEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userEvent = getSenderEvent(_db, _eventId);
        require(_userEvent.state.includesState(EVST_OPEN|EVST_CLOSE));
         if (_userEvent.state.equalsState(EVST_OPEN)) {
            _userEvent.readyTime = now;
        }
        _userEvent.state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY);
        return _save(_userEvent);
    }

    function stopEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userEvent = getSenderEvent(_db, _eventId);
        require(_userEvent.state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        _userEvent.state.changeState((EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY), EVST_STOP);
        return _save(_userEvent);
    }

    function closeEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) { 
        var _userEvent = getSenderEvent(_db, _eventId);
        require(_userEvent.state.equalsState(EVST_READY));
        require(now > _userEvent.readyTime.add(WAIT_SECONDS));
        _userEvent.state.changeState(EVST_READY, EVST_CLOSE);
        return _save(_userEvent);
    }

   function collectEvent(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _eventId) internal returns (bool) {
        var _userEvent = getSenderEvent(_ticketDB, _eventId);
        require(_userEvent.state.equalsState(EVST_CLOSE));
        _userEvent.state.changeState(EVST_CLOSE, EVST_COLLECT);
        TokenDB(_tokenDB).addBalance(msg.sender, _userEvent.amountSold);
        return _save(_userEvent);
    }
}

