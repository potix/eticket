pragma solidity ^0.4.14;

import "./Validation.sol";
import "./Random.sol";
import "./State.sol";
import "./ETicketUser.sol";
import "./ETicketEvent.sol";
import "./ETicketTicketGroup.sol";
import "./ETicketTransaction.sol";
import "./ETicketDB.sol";
import "./TokenDB.sol";

library ETicketTicketContext {
    using State for uint32;  
    using SafeMath for uint256;

    // == create/modify ==
    // [ticketContexts]
    // ticketContextId
    // ticketContexts <ticketContextId> userId
    // ticketContexts <ticketContextId> transactionId
    // ticketContexts <ticketContextId> reservedUrl
    // ticketContexts <ticketContextId> enteredUrl
    // ticketContexts <ticketContextId> cashBackAmount
    // ticketContexts <ticketContextId> enterCode
    // ticketContexts <ticketContextId> serialNumber
    // ticketContexts <ticketContextId> BuyPrice
    // ticketContexts <ticketContextId> salePrice
    // ticketContexts <ticketContextId> state [ 0x10 CASHEBACKED, 0x01 SALABLE, 0x02 UNSALABLE, 0x04 ENTERED ]
    // == related == 
    // [transaction]
    // transactions <ticketContextId> buyTickets
    // transactions <ticketContextId> reservedTickets
    // transactions <ticketContextId> state [ 0x01 SALABLE 0x02 UNSALABLE ]
    // [ticket group]
    // ticketGroups <ticketGroupId> lastSerialNumber
    // ticketGroups <ticketGroupId> state [ 0x01 SALE 0x02 STOP ]
    // [event]
    // events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    
    uint32 constant TKTCTX_SALABLE    = 0x01;
    uint32 constant TKTCTX_UNSALABLE  = 0x02;
    uint32 constant TKTCTX_ENTERED    = 0x04;
    uint32 constant TKTCTX_CASHBACKED = 0x10;

    struct ticketContext {
        ETicketDB db;
        uint256 ticketContextId;
        // memebers
        uint256 userId;
        uint256 transactionId;
        string reservedUrl;
        bytes32 reservedUrlSha3;
        string enteredUrl;
        bytes32 enteredUrlSha3;
        uint256 cashBackAmount;
        uint32 enterCode;
        uint256 serialNumber;
        uint32 state;
        // parent
        ETicketUser.user user;
        ETicketTransaction.transaction transaction;
        // shadows
        uint256 __userId;
        uint256 __transactionId;
        bytes32 __reservedUrlSha3;
        bytes32 __enteredUrlSha3;
        uint256 __cashBackAmount;
        uint32 __enterCode;
        uint256 __serialNumber;
        uint32 __state;
    }
    
    function getRandomCode(uint256 nonce) private returns (uint32){ 
        return uint32(Random.getRandom(nonce) % 4294967291);
    }
    
    function _newId(ETicketDB _db) private returns (uint256) {
        return ETicketDB(_db).getAndIncrementId(sha3("ticketContextId"));   
    }

    function _load(ETicketDB _db, uint256 _ticketContextId) private returns (ticketContext _ticketContext) {
        _ticketContext.db = _db;
        _ticketContext.ticketContextId = _ticketContextId;
        _ticketContext.userId = ETicketDB(_db).getUint256(sha3("ticketContexts", _ticketContextId, "userId"));
        _ticketContext.transactionId = ETicketDB(_db).getUint256(sha3("ticketContexts", _ticketContextId, "transactionId"));
        _ticketContext.reservedUrlSha3 = ETicketDB(_db).getStringSha3(sha3("ticketContexts", _ticketContextId, "reservedUrl"));
        _ticketContext.enteredUrlSha3 = ETicketDB(_db).getStringSha3(sha3("ticketContexts", _ticketContextId, "enteredUrl"));
        _ticketContext.cashBackAmount = ETicketDB(_db).getUint256(sha3("ticketContexts", _ticketContextId, "cashBackAmount"));
        _ticketContext.enterCode = ETicketDB(_db).getUint32(sha3("ticketContexts", _ticketContextId, "enterCode"));
        _ticketContext.serialNumber = ETicketDB(_db).getUint256(sha3("ticketContexts", _ticketContextId, "serialNumber"));
        _ticketContext.state = ETicketDB(_db).getUint32(sha3("ticketContexts", _ticketContextId, "state")); 
        // set shadows
        _ticketContext.__userId = _ticketContext.userId;
        _ticketContext.__transactionId = _ticketContext.transactionId;
        _ticketContext.__reservedUrlSha3 = _ticketContext.reservedUrlSha3;
        _ticketContext.__enteredUrlSha3 = _ticketContext.enteredUrlSha3;
        _ticketContext.__cashBackAmount = _ticketContext.cashBackAmount;
        _ticketContext.__enterCode = _ticketContext.enterCode;
        _ticketContext.__serialNumber = _ticketContext.serialNumber;
        _ticketContext.__state = _ticketContext.state;
         require(_ticketContext.state != 0);
        // parent
        _ticketContext.transaction = ETicketTransaction.getExistsTransaction(_db, _ticketContext.transactionId);
        _ticketContext.user = ETicketUser.getExistsUser(_db, _ticketContext.userId);
    }

    function _save(ticketContext _ticketContext) private returns (bool){
        bool changed = false;
        if (_ticketContext.userId != _ticketContext.__userId) {
            ETicketDB(_ticketContext.db).setUint256(sha3("ticketContexts", _ticketContext.ticketContextId, "userId"), _ticketContext.userId);
            changed = true;
        }
        if (_ticketContext.transactionId != _ticketContext.__transactionId) {
            ETicketDB(_ticketContext.db).setUint256(sha3("ticketContexts", _ticketContext.ticketContextId, "transactionId"), _ticketContext.transactionId);
            changed = true;
        }
        if (_ticketContext.reservedUrlSha3 != _ticketContext.__reservedUrlSha3) {
            ETicketDB(_ticketContext.db).setString(sha3("ticketContexts", _ticketContext.ticketContextId, "reservedUrl"), _ticketContext.reservedUrl);
            changed = true;
        }
        if (_ticketContext.enteredUrlSha3 != _ticketContext.__enteredUrlSha3) {
            ETicketDB(_ticketContext.db).setString(sha3("ticketContexts", _ticketContext.ticketContextId, "enteredUrl"), _ticketContext.enteredUrl);
            changed = true;
        }
        if (_ticketContext.cashBackAmount != _ticketContext.cashBackAmount) {
            ETicketDB(_ticketContext.db).setUint256(sha3("ticketContexts", _ticketContext.ticketContextId, "cashBackAmount"), _ticketContext.cashBackAmount);
            changed = true;
        }
        if (_ticketContext.enterCode != _ticketContext.enterCode) {
            ETicketDB(_ticketContext.db).setUint256(sha3("ticketContexts", _ticketContext.ticketContextId, "enterCode"), _ticketContext.enterCode);
            changed = true;
        }
        if (_ticketContext.serialNumber != _ticketContext.serialNumber) {
            ETicketDB(_ticketContext.db).setUint256(sha3("ticketContexts", _ticketContext.ticketContextId, "serialNumber"), _ticketContext.serialNumber);
            changed = true;
        }
        if (_ticketContext.state != _ticketContext.__state) {
            ETicketDB(_ticketContext.db).setUint32(sha3("ticketContexts", _ticketContext.ticketContextId, "state"), _ticketContext.state);
            changed = true;
        }
        if (changed) {
            // XXX TODO 親？側に関数作るべき
            _ticketContext.user.ticketContextUpdateTime = now;
        }
        ETicketTransaction.updateTransaction(_ticketContext.transaction);
        ETicketUser.updateUser(_ticketContext.user);
        return true;
    }

    function _new(
        ETicketDB _db,
        ETicketUser.user _user, 
        ETicketTransaction.transaction _transaction,
        uint256 _serialNumber,
        uint32 _state
        ) private returns (ticketContext _ticketContext) {
        _ticketContext.db = _db;
        _ticketContext.transactionId = _newId(_db);
        _ticketContext.userId = _user.userId;
        _ticketContext.transactionId = _transaction.transactionId;
        _ticketContext.reservedUrl = "";
        _ticketContext.reservedUrlSha3 = sha3(_ticketContext.reservedUrl);
        _ticketContext.enteredUrl = "";
        _ticketContext.enteredUrlSha3 = sha3(_ticketContext.enteredUrl);
        _ticketContext.cashBackAmount = 0;
        _ticketContext.enterCode = getRandomCode(_ticketContext.transactionId);
        _ticketContext.serialNumber = _serialNumber;
        _ticketContext.state = _state;
        _ticketContext.transaction = _transaction;
        _ticketContext.user = _user;
    }
    
    function createTicketcontext(ETicketDB _db, uint256 _transactionId, uint256 _amount) internal returns (uint256[]){
        require(_amount > 0);
        var _user = ETicketUser.getSenderUser(_db);
        var _transaction = ETicketTransaction.getSenderTransaction(_db, _transactionId);
        require(ETicketTransaction.isCreatableTicketContextState(_transaction));
        require(ETicketTransaction.getRemainTickets(_transaction) >= _amount);
        uint256[] memory TicketContextIds = new uint256[](_amount); 
        for (uint256 i = 0; i < _amount; i++) {
            var _serialNumber = ETicketTransaction.getAndIncrementSerialNumber(_transaction);
            var _ticketContext = _new(_db, _user, _transaction, _serialNumber, TKTCTX_UNSALABLE);
            _save(_ticketContext);
            TicketContextIds[i] = _ticketContext.ticketContextId;
        }
        return TicketContextIds;
    }
    
    
    
}

