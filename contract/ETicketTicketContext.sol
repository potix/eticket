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
    // ticketContexts <ticketContextId> cashBackCode
    // ticketContexts <ticketContextId> cashBackAmount
    // ticketContexts <ticketContextId> enterCode
    // ticketContexts <ticketContextId> serialNumber
    // ticketContexts <ticketContextId> BuyPrice
    // ticketContexts <ticketContextId> salePrice
    // ticketContexts <ticketContextId> state [ 0x01 SALABLE, 0x02 UNSALABLE, 0x04 ENTERED, 0x08 REFUNDED ]
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
    uint32 constant TKTCTX_REFUNDED   = 0x08;

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
        string cashBackCode;
        bytes32 cashBackCodeSha3;
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
        bytes32 __cashBackCodeSha3;
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
        _ticketContext.cashBackCodeSha3 = ETicketDB(_db).getStringSha3(sha3("ticketContexts", _ticketContextId, "cashBackCode"));
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
        if (_ticketContext.cashBackCodeSha3 != _ticketContext.__cashBackCodeSha3) {
            ETicketDB(_ticketContext.db).setString(sha3("ticketContexts", _ticketContext.ticketContextId, "cashBackCode"), _ticketContext.cashBackCode);
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
        string _reservedUrl,
        uint256 _serialNumber,
        uint32 _state
        ) private returns (ticketContext _ticketContext) {
        _ticketContext.db = _db;
        _ticketContext.transactionId = _newId(_db);
        _ticketContext.userId = _user.userId;
        _ticketContext.transactionId = _transaction.transactionId;
        _ticketContext.reservedUrl = _reservedUrl;
        _ticketContext.reservedUrlSha3 = sha3(_ticketContext.reservedUrl);
        _ticketContext.enteredUrl = "";
        _ticketContext.enteredUrlSha3 = sha3(_ticketContext.enteredUrl);
        _ticketContext.cashBackCode = "";
        _ticketContext.cashBackCodeSha3 = sha3(_ticketContext.cashBackCode);
        _ticketContext.cashBackAmount = 0;
        _ticketContext.enterCode = getRandomCode(_ticketContext.transactionId);
        _ticketContext.serialNumber = _serialNumber;
        _ticketContext.state = _state;
        _ticketContext.transaction = _transaction;
        _ticketContext.user = _user;
    }
    
    function isModifiableTicketContextState(ticketContext _ticketContext) internal returns (bool) {
        return _ticketContext.state.includesState(TKTCTX_SALABLE|TKTCTX_UNSALABLE) && 
               ETicketTransaction.isModifiableTicketContextState(_ticketContext.transaction);
    }
    
    function isTransferableTicketContextState(ticketContext _ticketContext) internal returns (bool) {
        return _ticketContext.state.includesState(TKTCTX_SALABLE|TKTCTX_UNSALABLE) && 
               ETicketTransaction.isTransferableTicketContextState(_ticketContext.transaction);
    }
    
    function isSalableTicketContextState(ticketContext _ticketContext) internal returns (bool) {
        return _ticketContext.state.equalsState(TKTCTX_SALABLE) && 
               ETicketTransaction.isSalableTicketContextState(_ticketContext.transaction);
    }
    
    function isCashBackTicketContextState(ticketContext _ticketContext) internal returns (bool) {
        return _ticketContext.state.includesState(TKTCTX_SALABLE|TKTCTX_UNSALABLE|TKTCTX_ENTERED) &&
               ETicketTransaction.isCashBackTicketContextState(_ticketContext.transaction);
    }
    
    function isEnterableTicketContextState(ticketContext _ticketContext) internal returns (bool) {
        return _ticketContext.state.includesState(TKTCTX_SALABLE|TKTCTX_UNSALABLE) && 
               ETicketTransaction.isEnterableTicketContextState(_ticketContext.transaction);
    }

    function isRefundableTicketContextState(ticketContext _ticketContext) internal returns (bool) {
        return _ticketContext.state.includesState(TKTCTX_SALABLE|TKTCTX_UNSALABLE|TKTCTX_ENTERED) && 
               ETicketTransaction.isRefundableTicketContextState(_ticketContext.transaction);
    }

    function getEnterOracleUrl(ticketContext _ticketContext) internal returns (string) {
        return ETicketTransaction.getEnterOracleUrl(_ticketContext.transaction);
    }

    function getCashBackOracleUrl(ticketContext _ticketContext) internal returns (string) {
        return ETicketTransaction.getCashBackOracleUrl(_ticketContext.transaction);
    }
    
    function getTransactionBuyPrice(ticketContext _ticketContext) internal returns (uint256) {
        return ETicketTransaction.getTransactionBuyPrice(_ticketContext.transaction); 
    }
    
    function getEventOwnerUser(ticketContext _ticketContext) internal returns (ETicketUser.user) {
        return ETicketTransaction.getEventOwnerUser(_ticketContext.transaction); 
    }
    
    function subAmountSold(ticketContext _ticketContext, uint256 _totalPrice) internal returns (bool) {
        return ETicketTransaction.subAmountSold(_ticketContext.transaction, _totalPrice); 
    }
    
    function getExistsTicketContext(ETicketDB _db, uint256 _ticketContextId) internal returns(ticketContext) {
        return _load(_db, _ticketContextId);
    }

    function getSenderTicketContext(ETicketDB _db, uint256 _ticketContextId) internal returns(ticketContext) {
        var _user = ETicketUser.getSenderUser(_db);
        var _ticketContext = _load(_db, _ticketContextId);
        require(_ticketContext.userId != _user.userId);
        return _ticketContext;
    }
    
    function __callback(bytes32 myid, string result) internal {
        //mapping(bytes32=>bool) validIds;
        //if (!validIds[myid]) throw;
    }
    
    function createTicketcontext(ETicketDB _db, uint256 _transactionId, uint256 _amount) internal returns (uint256[]){
        require(_amount > 0);
        var _user = ETicketUser.getSenderUser(_db);
        var _transaction = ETicketTransaction.getSenderTransaction(_db, _transactionId);
        require(ETicketTransaction.isCreatableTicketContextState(_transaction));
        require(ETicketTransaction.getRemainTickets(_transaction) >= _amount);
        uint256[] memory TicketContextIds = new uint256[](_amount); 
        var _reserveOracleUrl = ETicketTransaction.getReserveOracleUrl(_transaction);
        var _reservedUrl = "";
        if (bytes(_reserveOracleUrl).length != 0) {
            // XXX TODO oraclize
        }
        for (uint256 i = 0; i < _amount; i++) {
            var _serialNumber = ETicketTransaction.getAndIncrementSerialNumber(_transaction);
            var _ticketContext = _new(_db, _user, _transaction, _reservedUrl, _serialNumber, TKTCTX_UNSALABLE);
            _save(_ticketContext);
            TicketContextIds[i] = _ticketContext.ticketContextId;
        }
        return TicketContextIds;
    }
    
    function transferTicketCtx(ETicketDB _db, uint256 _ticketContextId, uint256 newUserId) internal returns (bool) { 
        var _ticketContext = getSenderTicketContext(_db, _ticketContextId);
        var _newUser = ETicketUser.getExistsUser(_db, newUserId);
        require(isTransferableTicketContextState(_ticketContext));
        _ticketContext.enterCode = getRandomCode(_ticketContext.ticketContextId);
        _ticketContext.state = TKTCTX_UNSALABLE;
        _ticketContext.userId = _newUser.userId;
        _ticketContext.user = _newUser;
        return _save(_ticketContext);
    }
    
    function setTicketContextSalable(ETicketDB _db, uint256 _ticketContextId) internal returns (bool) { 
        var _ticketContext = getSenderTicketContext(_db, _ticketContextId);
        require(isModifiableTicketContextState(_ticketContext));
        require(_ticketContext.state.equalsState(TKTCTX_UNSALABLE));
        require(bytes(_ticketContext.cashBackCode).length == 0);
        _ticketContext.state = _ticketContext.state.changeState(TKTCTX_UNSALABLE, TKTCTX_SALABLE);
        return _save(_ticketContext);
    }
    
    function setTicketContextUnsalable(ETicketDB _db, uint256 _ticketContextId) internal returns (bool) { 
        var _ticketContext = getSenderTicketContext(_db, _ticketContextId);
        require(isModifiableTicketContextState(_ticketContext));
        require(_ticketContext.state.equalsState(TKTCTX_SALABLE));
        _ticketContext.state = _ticketContext.state.changeState(TKTCTX_SALABLE, TKTCTX_UNSALABLE);
        return _save(_ticketContext);
    }
    
    function buyTicketContext(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _ticketContextId) internal returns (bool) {
        var _ticketContext = getExistsTicketContext(_ticketDB, _ticketContextId);
        var _user = _ticketContext.user;
        var _newUser = ETicketUser.getSenderUser(_ticketDB);
        require(isSalableTicketContextState(_ticketContext));
        require(bytes(_ticketContext.cashBackCode).length == 0);
        _ticketContext.enterCode = getRandomCode(_ticketContext.ticketContextId);
        _ticketContext.state = TKTCTX_UNSALABLE;
        _ticketContext.userId = _newUser.userId;
        _ticketContext.user = _newUser;
        var _buyPrice = getTransactionBuyPrice(_ticketContext); 
        TokenDB(_tokenDB).addBalance(_user.userAddress, _buyPrice);
        TokenDB(_tokenDB).subBalance(_newUser.userAddress, _buyPrice);
        return _save(_ticketContext);
    }

    function enterTicketContext(ETicketDB _db, uint256 _ticketContextId) internal returns (bool) { 
        var _ticketContext = getExistsTicketContext(_db, _ticketContextId);
        require(isEnterableTicketContextState(_ticketContext));
        var eventOwnerUser = getEventOwnerUser(_ticketContext);
        require(msg.sender == eventOwnerUser.userAddress);
        _ticketContext.state = _ticketContext.state.changeState((TKTCTX_SALABLE|TKTCTX_UNSALABLE), TKTCTX_ENTERED);
        var _enterOracleUrl = getEnterOracleUrl(_ticketContext);
        var _enteredUrl = "";
        if (bytes(_enterOracleUrl).length != 0) {
            // XXX TODO oraclize
        }
        return _save(_ticketContext);
    }

    function cashBackTicketContext(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _ticketContextId, string _cashBackCode) internal returns (bool) {
        require(bytes(_cashBackCode).length != 0);
        var _ticketContext = getSenderTicketContext(_ticketDB, _ticketContextId);
        require(isCashBackTicketContextState(_ticketContext));
        require(bytes(_ticketContext.cashBackCode).length == 0);
        var cashBackOracleUrl = getCashBackOracleUrl(_ticketContext);
        require(bytes(cashBackOracleUrl).length != 0);
        _ticketContext.cashBackCode = _cashBackCode;
        // XXX TODO oraclize
        // token移動
        // addTotalCashBack(cashBackPrice)
        // TokenDB(_tokenDB).addBalance(_ticketContext.user.userAddress, cashBackPrice);
        return _save(_ticketContext);
    }

    function refundTicketContext(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _ticketContextId) internal returns (bool) {
        var _ticketContext = getSenderTicketContext(_ticketDB, _ticketContextId);
        require(isRefundableTicketContextState(_ticketContext));
        var _buyPrice = getTransactionBuyPrice(_ticketContext);     
        var _totalPrice = _buyPrice.sub(_ticketContext.cashBackAmount);
        _ticketContext.state = _ticketContext.state.changeState(TKTCTX_SALABLE|TKTCTX_SALABLE|TKTCTX_ENTERED, TKTCTX_REFUNDED);
        subAmountSold(_ticketContext, _totalPrice);
        TokenDB(_tokenDB).addBalance(_ticketContext.user.userAddress, _totalPrice);
        return _save(_ticketContext);
    }
}

