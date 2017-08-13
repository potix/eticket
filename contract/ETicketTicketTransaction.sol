pragma solidity ^0.4.14;

import "./Validation.sol";
import "./State.sol";
import "./ETicketUser.sol";
import "./ETicketEvent.sol";
import "./ETicketTicketGroup.sol";
import "./ETicketDB.sol";
import "./TokenDB.sol";

library ETicketTransaction {
    using State for uint32;  
    using SafeMath for uint256;
    
    // == create/modify ==
    // [transaction]
    // transactionId
    // transactions <transactionId> userId
    // transactions <transactionId> eventId
    // transactions <transactionId> ticketGroupId
    // transactions <transactionId> eventOwnerId
    // transactions <transactionId> buyTickets
    // transactions <transactionId> reservedTickets
    // transactions <transactionId> buyPrice
    // transactions <transactionId> totalCashBackPrice
    // transactions <transactionId> state [ 0x01 SALABLE 0x02 UNSALABLE ]
    // == related == 
    // [event]
    // events <eventId> amountSold
    // events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // [ticket group]
    // ticketGroups <ticketGroupId> supplyTickets
    // ticketGroups <ticketGroupId> soldTickets
    // ticketGroups <ticketGroupId> price
    // ticketGroups <ticketGroupId> admountSold
    // ticketGroups <ticketGroupId> state [ 0x01 SALABLE 0x02 UNSALABLE ] 

    uint256 constant MAX_BUYABLE_TICKETS = 20;
    
    uint32 constant TXNST_SALABLE = 0x01;
    uint32 constant TXNST_UNSALABLE = 0x01;
    
    struct transactionInfo {
        uint256 userId;
        uint256 eventId;
        uint256 ticketGroupId;
        uint256 transactionId;
        uint256 eventOwnerId;
    }
    
    struct totalPrice {
        uint256 buyPrice;
        uint256 amount;
        uint256 total;
    }
    
    function getTransactionState(ETicketDB _db, uint256 _transactionId) internal returns (uint32) {
        return ETicketDB(_db).getUint32(sha3("transactions", _transactionId, "state"));
    }

    function getTransactionTotalPrice(ETicketDB _db, uint256 _transactionId, uint256 _amount) internal returns (totalPrice _totalPrice) {
        _totalPrice.buyPrice = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyPrice"));
        _totalPrice.amount = _amount;
        _totalPrice.total = _totalPrice.buyPrice.mul(_amount);
    }

    function getRemainTickets(ETicketDB _db, uint256 _transactionId) internal returns (uint256) {
        var _buyTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyTickets"));
        var _reservedTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "reservedTickets"));
        return _buyTickets.sub(_reservedTickets);
    }

    function getExistsTransationInfo(ETicketDB _db, uint256 _transactionId) internal returns(transactionInfo _transactionInfo) {
        require(getTransactionState(_db, _transactionId) != 0);
        var _userId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "userId"));
        var _ticketGroupId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "ticketGroupId"));
        var _eventOwnerId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "eventOwnerId"));
        var _ticketGroupInfo = ETicketTicketGroup.getOwnerTicketGroupInfo(_db, _eventOwnerId, _ticketGroupId);
        _transactionInfo.userId = _userId;
        _transactionInfo.eventId = _ticketGroupInfo.eventId;
        _transactionInfo.ticketGroupId = _ticketGroupInfo.ticketGroupId;
        _transactionInfo.transactionId = _transactionId;
        _transactionInfo.eventOwnerId = _eventOwnerId;
    }

    function getOwnerTransationInfo(ETicketDB _db, uint256 _userId, uint256 _transactionId) internal returns(transactionInfo _transactionInfo) {
        require(getTransactionState(_db, _transactionId) != 0);
        require(ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "userId")) == _userId);
        var _eventOwnerId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "eventOwnerId"));
        var _ticketGroupId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "ticketGroupId"));
        var _ticketGroupInfo = ETicketTicketGroup.getOwnerTicketGroupInfo(_db, _eventOwnerId, _ticketGroupId);
        _transactionInfo.userId = _userId;
        _transactionInfo.eventId = _ticketGroupInfo.eventId;
        _transactionInfo.ticketGroupId = _ticketGroupInfo.ticketGroupId;
        _transactionInfo.transactionId = _transactionId;
        _transactionInfo.eventOwnerId = _eventOwnerId;
    }
    
    function subBuyTickets(ETicketDB _db, uint256 _transactionId, uint256 _amount) internal returns (bool) {
        ETicketDB(_db).subUint256(sha3("transactions", _transactionId, "buyTickets"), _amount); 
        ETicketDB(_db).incrementUint256(sha3("transactions", _transactionId, "version"));
        return true;
    }
    
    function createTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _ticketGroupId, uint256 _amount) internal returns (bool) {
        var _ticketGroupInfo = ETicketTicketGroup.getExistsTicketGroupInfo(_ticketDB, _ticketGroupId);
        require(ETicketTicketGroup.ticketGroupStateSalableTicket(_ticketDB, _ticketGroupInfo.eventId, _ticketGroupInfo.ticketGroupId));
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        var salableTickets = ETicketTicketGroup.getSalableTickets(_ticketDB, _ticketGroupInfo.ticketGroupId);
        require(salableTickets >= _amount);
        var _totalPrice = ETicketTicketGroup.getTicketGroupTotalPrice(_ticketDB, _ticketGroupInfo.ticketGroupId, _amount);
        require(TokenDB(_tokenDB).getBalance(msg.sender) >= _totalPrice.total);
        // チケットグループに取引情報を作成する
        var _userId = ETicketDB(_ticketDB).getIdMap(msg.sender);
        var _transactionId = ETicketDB(_ticketDB).getAndIncrementId(sha3("transactionId"));        
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "userId"), _userId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "eventId"), _ticketGroupInfo.eventId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "ticketGroupId"), _ticketGroupInfo.ticketGroupId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "eventOwnerId"), _ticketGroupInfo.userId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "buyTickets"), _amount);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "reservedTickets"), 0);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "buyPrice"), _totalPrice.price);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _transactionId, "totalCashBackPrice"), 0);
        ETicketDB(_ticketDB).setUint32(sha3("transactions", _transactionId, "state"), TXNST_UNSALABLE);
        ETicketDB(_ticketDB).incrementUint256(sha3("transactions", _transactionId, "version"));
        // ticketGroupの情報更新
        ETicketTicketGroup.addSoldTicket(_ticketDB, _ticketGroupInfo.ticketGroupId, _amount);
        // eventの情報更新
        ETicketEvent.addAmountSold(_ticketDB, _ticketGroupInfo.eventId, _totalPrice.total);
        // ユーザからお金を引く
        TokenDB(_tokenDB).subBalance(msg.sender, _totalPrice.total);
    }

    function setTransactionSalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _transationInfo = getOwnerTransationInfo(_db, _userInfo.userId, _transactionId);
        require(ETicketEvent.eventStateModiableTransaction(_db, _transationInfo.eventId));
        var state = ETicketDB(_db).getUint32(sha3("transactions", _transationInfo.ticketGroupId, "state"));
        require(state.equalsState(TXNST_UNSALABLE));
        ETicketDB(_db).setUint32(sha3("transactions", _transationInfo.transactionId, "state"), state.changeState(TXNST_UNSALABLE, TXNST_SALABLE));
        ETicketDB(_db).incrementUint256(sha3("transactions", _transationInfo.transactionId, "version"));
    }

    function setTransactionUnsalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _transationInfo = getOwnerTransationInfo(_db, _userInfo.userId, _transactionId);
        require(ETicketEvent.eventStateModiableTransaction(_db, _transationInfo.eventId));
        var state = ETicketDB(_db).getUint32(sha3("transactions", _transationInfo.ticketGroupId, "state"));
        require(state.equalsState(TXNST_SALABLE));
        ETicketDB(_db).setUint32(sha3("transactions", _transationInfo.transactionId, "state"), state.changeState(TXNST_SALABLE, TXNST_UNSALABLE));
        ETicketDB(_db).incrementUint256(sha3("transactions", _transationInfo.transactionId, "version"));
    }
    
    function splitTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _transactionId, uint256 _amount) returns (bool) {
        var _transationInfo = getExistsTransationInfo(_ticketDB, _transactionId);
        require(ETicketTicketGroup.ticketGroupStateSalableTicket(_ticketDB, _transationInfo.eventId, _transationInfo.ticketGroupId));
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        var state = ETicketDB(_ticketDB).getUint32(sha3("transactions", _transationInfo.ticketGroupId, "state"));
        require(state.equalsState(TXNST_SALABLE));
        var remainTickets = getRemainTickets(_ticketDB, _transactionId);
        require(remainTickets >= _amount);
        var _totalPrice = getTransactionTotalPrice(_ticketDB, _transactionId, _amount);       
        require(TokenDB(_tokenDB).getBalance(msg.sender) <= _totalPrice.total);
        // チケットグループに新しい取引情報の作成
        var _newUserInfo = ETicketUser.getSenderUserInfo(_ticketDB);
        var _newTransactionId = ETicketDB(_ticketDB).getAndIncrementId(sha3("transactionId"));        
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "userId"), _newUserInfo.userId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "eventId"), _transationInfo.eventId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "ticketGroupId"), _transationInfo.ticketGroupId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "eventOwnerId"), _transationInfo.eventOwnerId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "buyTickets"), _amount);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "buyPrioce"), _totalPrice.buyPrice);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "reservedTickets"), 0);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "totalCashBackPrice"), 0);
        ETicketDB(_ticketDB).setUint32(sha3("transactions", _newTransactionId, "state"), TXNST_UNSALABLE);
        ETicketDB(_ticketDB).incrementUint256(sha3("transactions", _newTransactionId, "version"));
        // 元の取引情報を更新する
        subBuyTickets(_ticketDB, _transactionId, _amount);
        // 元の買い手の所持金を増やす
        TokenDB(_tokenDB).addBalance(_newUserInfo.userAddress, _totalPrice.total);
        // 新たな書いての所持金を減らす
        TokenDB(_tokenDB).subBalance(msg.sender, _totalPrice.total);
    }

    function cancelTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _transactionId, uint256 _amount) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_ticketDB);
        var _transationInfo = getOwnerTransationInfo(_ticketDB, _userInfo.userId, _transactionId);
        require(ETicketEvent.eventStateCancelableTicket(_ticketDB, _transationInfo.eventId));
        require(_amount > 0);
        var _remainTickets = getRemainTickets(_ticketDB, _transactionId);
        require(_remainTickets >= _amount);
        var _totalPrice = getTransactionTotalPrice(_ticketDB, _transactionId, _amount);
        // 取引情報の更新
        subBuyTickets(_ticketDB, _transactionId, _amount);
        // ticketGroupの情報更新
        ETicketTicketGroup.subSoldTicket(_ticketDB, _transationInfo.ticketGroupId, _amount);
        // eventの情報更新
        ETicketEvent.subAmountSold(_ticketDB, _transationInfo.eventId, _totalPrice.total);
        // ユーザにお金を戻す
        TokenDB(_tokenDB).addBalance(msg.sender, _totalPrice.total);
    }
}
