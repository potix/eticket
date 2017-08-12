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
    // events <eventId> tags
    // events <eventId> description
    // events <eventId> reserveOracleUrl
    // events <eventId> enterOracleUrl
    // events <eventId> cashBackOracleUrl
    // events <eventId> amountSold
    // events <eventId> readyTimestamp
    // events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // events <eventId> version

    uint256 public constant WAIT_SECONDS = 90000;

    uint32 public constant EVST_CREATE  = 0x01;
    uint32 public constant EVST_SALE    = 0x02;
    uint32 public constant EVST_OPEN    = 0x04;
    uint32 public constant EVST_READY   = 0x08;
    uint32 public constant EVST_STOP    = 0x10;
    uint32 public constant EVST_CLOSE   = 0x20;
    uint32 public constant EVST_COLLECT = 0x40;
    
    struct eventInfo {
        uint256 userId;
        uint256 eventId;
    }
    
    function getEventStateCreatableAndModiableTicketGroup() internal returns (uint32) {
        return EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY;
    }

    function getEventStateSalableTicket() internal returns (uint32) {
        return EVST_SALE|EVST_OPEN|EVST_READY;
    }

    function getEventState(ETicketDB _db, uint256 _eventId) internal returns (uint32) {
        ETicketDB(_db).getUint32(sha3("events", _eventId, "state"));
    }
    
    function getOwnerEventInfo(ETicketDB _db, uint256 _userId, uint256 _eventId) internal returns (eventInfo _eventInfo) {
        require(getEventState(_db, _eventId) != 0);
        require(ETicketDB(_db).getUint256(sha3("events", _eventId, "userId")) == _userId);
        _eventInfo.userId = _userId;
        _eventInfo.eventId = _eventId;
    }

    function addAmountSold(ETicketDB _db, uint256 _eventId, uint256 _addAmountSold) internal returns (bool) {
        ETicketDB(_db).addUint256(sha3("events", _eventId, "admountSold"), _addAmountSold);
        ETicketDB(_db).incrementUint256(sha3("events", _eventId, "version"));
        return true;
    }

    function subAmountSold(ETicketDB _db, uint256 _eventId, uint256 _subAmountSould) internal returns (bool) {
        ETicketDB(_db).subUint256(sha3("events", _eventId, "admountSold"), _subAmountSould);
        ETicketDB(_db).incrementUint256(sha3("events", _eventId, "version"));
        return true;
    }

    function createEventCommon(
        ETicketDB _db, 
        uint256 _userId, 
        string _name, 
        string _country, 
        string _description
        ) private returns (uint256 _eventId) {
        require(Validation.validStringLength(_name, 1, 200));        
        require(Validation.validStringLength(_country, 1, 3));        
        require(Validation.validStringLength(_description, 0, 15000));  
        _eventId = ETicketDB(_db).getAndIncrementId(sha3("eventId"));
        ETicketDB(_db).setUint256(sha3("events", _eventId, "userId"), _userId);
        ETicketDB(_db).setString(sha3("events", _eventId, "name"), _name);
        ETicketDB(_db).setString(sha3("events", _eventId, "country"), _country);
        ETicketDB(_db).setString(sha3("events", _eventId, "description"), _description);
        ETicketDB(_db).setUint256(sha3("events", _eventId, "amountSold"), 0);
        ETicketDB(_db).setUint256(sha3("events", _eventId, "readyTimestamp"), 0);
        ETicketDB(_db).incrementUint256(sha3("events", _eventId, "version"));
    }
    
    function createEventWithSalable(
        ETicketDB _db, 
        string _name,
        string _country,
        string _description
        ) internal returns (uint256 _eventId) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        _eventId = createEventCommon(_db, _userInfo.userId,  _name,  _country,  _description);
        ETicketDB(_db).setUint32(sha3("events", _eventId, "state"), EVST_SALE);
    }

    function createEventWithUnsalable(
        ETicketDB _db,
        string _name,
        string _country,
        string _description
        ) internal returns (uint256 _eventId) {
        var _user = ETicketUser.getSenderUserInfo(_db);
        _eventId = createEventCommon(_db, _user.userId,  _name,  _country,  _description);
        ETicketDB(_db).setUint32(sha3("events", _eventId, "state"), EVST_CREATE);
    }

    function setEventName(ETicketDB _db, uint256 _eventId, string _name) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        require(Validation.validStringLength(_name, 1, 200));        
        ETicketDB(_db).setString(sha3("events", _eventInfo.eventId, "name"), _name);
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
    }

    function setEventCountry(ETicketDB _db, uint256 _eventId, string _country) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        require(Validation.validStringLength(_country, 1, 3));        
        ETicketDB(_db).setString(sha3("events", _eventInfo.eventId, "country"), _country);
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
    }

    function setEventDescription(ETicketDB _db, uint256 _eventId, string _description) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        require(Validation.validStringLength(_description, 0, 15000));        
        ETicketDB(_db).setString(sha3("events", _eventInfo.eventId, "description"), _description);
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
    }

    function setEventReserveOracleUrl(ETicketDB _db, uint256 _eventId, string _reserveOracleUrl) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        require(Validation.validStringLength(_reserveOracleUrl, 0, 2000));        
        ETicketDB(_db).setString(sha3("events", _eventInfo.eventId, "reserveOracleUrl"), _reserveOracleUrl);
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
    }

    function setEventEnterOracleUrl(ETicketDB _db, uint256 _eventId, string _enterOracleUrl) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        require(Validation.validStringLength(_enterOracleUrl, 0, 2000));        
        ETicketDB(_db).setString(sha3("events", _eventInfo.eventId, "enterOracleUrl"), _enterOracleUrl);
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
    }

    function setEventCashbackOracleUrl(ETicketDB _db, uint256 _eventId, string _cashbackOracleUrl) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        require(Validation.validStringLength(_cashbackOracleUrl, 0, 2000));        
        ETicketDB(_db).setString(sha3("events", _eventInfo.eventId, "cashbackOracleUrl"), _cashbackOracleUrl);
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
    }

    function saleEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        var _state = getEventState(_db, _eventInfo.eventId);
        require(_state.includesState(EVST_CREATE|EVST_OPEN));
        ETicketDB(_db).setUint32(sha3("events", _eventInfo.eventId, "state"), _state.changeState((EVST_CREATE|EVST_OPEN), EVST_SALE));
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
        // チケットが購入できるようになる
    }

    function openEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        var _state = getEventState(_db, _eventInfo.eventId);
        require(_state.includesState(EVST_SALE|EVST_READY));
        ETicketDB(_db).setUint32(sha3("events", _eventInfo.eventId, "state"), _state.changeState((EVST_SALE|EVST_READY), EVST_OPEN));
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
        // reserveがenter,cashbackできるようになる
    }

    function readyEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        var _state = getEventState(_db, _eventInfo.eventId);
        require(_state.includesState(EVST_OPEN|EVST_CLOSE));
        if (_state.equalsState(EVST_OPEN)) {
            ETicketDB(_db).setUint256(sha3("events", _eventInfo.eventId, "readyTimestamp"), now);
        }
        ETicketDB(_db).setUint32(sha3("events", _eventInfo.eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
        // 25時間後cancelができなくなる
    }

    function stopEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        var _state = getEventState(_db, _eventInfo.eventId);
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        ETicketDB(_db).setUint32(sha3("events", _eventInfo.eventId, "state"), _state.changeState((EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY), EVST_STOP));
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
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

    function closeEvent(ETicketDB _db, uint256 _eventId) internal returns (bool) { 
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _eventInfo = getOwnerEventInfo(_db, _userInfo.userId, _eventId);
        var _state = getEventState(_db, _eventInfo.eventId);
        require(_state.equalsState(EVST_READY));
        // 25時間以上経過していないとcloseできない
        var _readyTimestamp = ETicketDB(_db).getUint256(sha3("events", _eventInfo.eventId, "readyTimestamp"));
        require(now > _readyTimestamp.add(WAIT_SECONDS));
        ETicketDB(_db).setUint32(sha3("events", _eventInfo.eventId, "state"), _state.changeState(EVST_READY, EVST_CLOSE));
        ETicketDB(_db).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
        // reservedとかenterとかcashbackとかとかできなくなる
        // ticketGroupの情報も変更できなくなる
    }

   function collectEvent(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _eventId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_ticketDB);
        var _eventInfo = getOwnerEventInfo(_ticketDB, _userInfo.userId, _eventId);
        var _state = getEventState(_ticketDB, _eventInfo.eventId);
        require(_state.equalsState(EVST_CLOSE));
        ETicketDB(_ticketDB).setUint32(sha3("events", _eventInfo.eventId, "state"), _state.changeState(EVST_CLOSE, EVST_COLLECT));
        var _amountSold = ETicketDB(_ticketDB).getUint256(sha3("events", _eventInfo.eventId, "amountSold"));
        TokenDB(_tokenDB).addBalance(msg.sender, _amountSold);
        ETicketDB(_ticketDB).incrementUint256(sha3("events", _eventInfo.eventId, "version"));
        return true;
        // 購入した人のトークンが回収される
        // これをやるまでは状態として記録されているだけ
        // これ以降の状態変更はない
    }
}

