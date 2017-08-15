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
    
    struct transaction {
        ETicketDB db;
        uint256 transactionId;
        // memebers
        uint256 userId;
        uint256 eventId;
        uint256 ticketGroupId;
        uint256 eventOwnerId;
        uint256 buyTickets;
        uint256 reservedTickets;
        uint256 buyPrice;
        uint256 totalCashBackPrice;
        uint32 state;
        // parent
        ETicketTicketGroup.ticketGroup ticketGroup;
        // shadows
        uint256 __userId;
        uint256 __eventId;
        uint256 __ticketGroupId;
        uint256 __eventOwnerId;
        uint256 __buyTickets;
        uint256 __reservedTickets;
        uint256 __buyPrice;
        uint256 __totalCashBackPrice;
        uint32 __state;
    }

    function _newId(ETicketDB _db) private returns (uint256) {
        return ETicketDB(_db).getAndIncrementId(sha3("transactionId"));   
    }

    function _load(ETicketDB _db, uint256 _transactionId) private returns (transaction _transaction) {
        _transaction.db = _db;
        _transaction._transactionId = _transactionId;
        _transaction.userId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "userId"));
        _transaction.eventId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "eventId"));
        _transaction.ticketGroupId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "ticketGroupId"));
        _transaction.eventOwnerId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "eventOwnerId"));
        _transaction.buyTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyTickets"));
        _transaction.reservedTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "reservedTickets"));
        _transaction.buyPrice = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyPrice"));
        _transaction.totalCashBackPrice = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "totalCashBackPrice"));
        _transaction.state = ETicketDB(_db).getUint32(sha3("transactions", _transactionId, "state")); 
        // set shadows
        _transaction.__userId = _transaction.userId;
        _transaction.__eventId = _transaction.eventId;
        _transaction.__ticketGroupId = _transaction.ticketGroupId;
        _transaction.__eventOwnerId = _transaction.eventOwnerId;
        _transaction.__buyTickets = _transaction.buyTickets;
        _transaction.__reservedTickets = _transaction.reservedTickets;
        _transaction.__buyPrice = _transaction.buyPrice;
        _transaction.__totalCashBackPrice = _transaction.totalCashBackPrice;
        _transaction.__state = _transaction.state;
         require(_transaction.state != 0);
        // parent
        _transaction.ticketGroup = ETicketTicketGroup.getExistsTicketGroup(_db, _transaction.ticketGroupId);
    }

    function _save(transaction _transaction) private returns (bool){
        bool changed = false;
        if (_transaction.userId != _transaction.__userId) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "userId"), _transaction.userId);
            changed = true;
        }
        if (_transaction.eventId != _transaction.__eventId) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "eventId"), _transaction.eventId);
            changed = true;
        }
        if (_transaction.ticketGroupId != _transaction.ticketGroupId) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "ticketGroupId"), _transaction.ticketGroupId);
            changed = true;
        }
        if (_transaction.eventOwnerId != _transaction.eventOwnerId) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "eventOwnerId"), _transaction.eventOwnerId);
            changed = true;
        }
        if (_transaction.buyTickets != _transaction.buyTickets) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "buyTickets"), _transaction.buyTickets);
            changed = true;
        }
        if (_transaction.reservedTickets != _transaction.reservedTickets) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "reservedTickets"), _transaction.reservedTickets);
            changed = true;
        }
        if (_transaction.buyPrice != _transaction.buyPrice) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "buyPrice"), _transaction.buyPrice);
            changed = true;
        }
        if (_transaction.totalCashBackPrice != _transaction.totalCashBackPrice) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "totalCashBackPrice"), _transaction.totalCashBackPrice);
            changed = true;
        }
        if (_transaction.state != _transaction.__state) {
            ETicketDB(_transaction.db).setUint32(sha3("transactions", _transaction.ticketGroupId, "state"), _transaction.state);
            changed = true;
        }
        if (changed) {
            // XXX TODO 親？側に関数作るべき
            _transaction.ticketGroup.userEvent.user.transactionUpdateTime = now;
        }
        ETicketTicketGroup.updateEvent(_transaction.userEvent);
        return true;
    }

    function _new(
        ETicketDB _db,
        ETicketTicketGroup.ticketGroup _ticketGroup, 
        uint256 _amount,
        uint32 _state
        ) private returns (transaction _transaction) {
        _transaction.db = _db;
        _transaction.transactionId = _newId(_db);
        _transaction.userId = ETicketUser.getSenderUserId();
        _transaction.eventId = _ticketGroup.eventId;
        _transaction.ticketGroupId = _ticketGroup.ticketGroupId;
        _transaction.eventOwnerId = _ticketGroup.userId;
        _transaction.buyTickets = _ticketGroup._amount;
        _transaction.reservedTickets = 0;
        _transaction.buyPrice = 0;
        _transaction.totalCashBackPrice = 0;
        _transaction.state = _state;
        _transaction.ticketGroup = _ticketGroup;
        _save(_transaction);
    }







    
    // struct totalPrice {
    //     uint256 buyPrice;
    //     uint256 amount;
    //     uint256 total;
    // }
    
    // function getTransactionState(ETicketDB _db, uint256 _transactionId) internal returns (uint32) {
    //     return ETicketDB(_db).getUint32(sha3("transactions", _transactionId, "state"));
    // }

    // function getTransactionTotalPrice(ETicketDB _db, uint256 _transactionId, uint256 _amount) internal returns (totalPrice _totalPrice) {
    //     _totalPrice.buyPrice = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyPrice"));
    //     _totalPrice.amount = _amount;
    //     _totalPrice.total = _totalPrice.buyPrice.mul(_amount);
    // }

    // function getRemainTickets(ETicketDB _db, uint256 _transactionId) internal returns (uint256) {
    //     var _buyTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyTickets"));
    //     var _reservedTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "reservedTickets"));
    //     return _buyTickets.sub(_reservedTickets);
    // }


    
    // function subBuyTickets(ETicketDB _db, uint256 _transactionId, uint256 _amount) internal returns (bool) {
    //     ETicketDB(_db).subUint256(sha3("transactions", _transactionId, "buyTickets"), _amount); 
    //     ETicketDB(_db).incrementUint256(sha3("transactions", _transactionId, "version"));
    //     return true;
    // }
    
    
    
    
    
    
    
    
    function getExistsTransation(ETicketDB _db, uint256 _transactionId) internal returns(transaction) {
        return _load(_db, _transactionId);
    }

    function getSenderTransationInfo(ETicketDB _db, uint256 _userId, uint256 _transactionId) internal returns(transaction) {
        var _user = ETicketUser.getSenderUser(_db);
        var _transaction = _load(_db, _transactionId);
        require(_transaction.userId != _user.userId);
        return _transaction;
    }
    
    
    
    
    
    function createTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _ticketGroupId, uint256 _amount) internal returns (bool) {
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        
        
        var _ticketGroup = ETicketTicketGroup.getExistsTicketGroup(_ticketDB, _ticketGroupId);
        require(ETicketTicketGroup.isSalableTicketState(_ticketGroup));
        var salableTickets = ETicketTicketGroup.getSalableTickets(_ticketGroup);
        require(salableTickets >= _amount);
        var _totalPrice = ETicketTicketGroup.getTicketGroupTotalPrice(_ticketGroup, _amount);
        require(TokenDB(_tokenDB).getBalance(msg.sender) >= _totalPrice);
        var transaction = _new(_ticketDB, _ticketGroup, _amount, TXNST_UNSALABLE); 
        ETicketTicketGroup.addSoldTicket(transaction.ticketGroup);

        // ticketGroupの情報更新
        ETicketTicketGroup.addSoldTicket(_ticketDB, _ticketGroupInfo.ticketGroupId, _amount);
        // eventの情報更新
        ETicketEvent.addAmountSold(_ticketDB, _ticketGroupInfo.eventId, _totalPrice.total);
        // ユーザからお金を引く
        TokenDB(_tokenDB).subBalance(msg.sender, _totalPrice.total);
    }

    function setTransactionSalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _transactionInfo = getOwnerTransationInfo(_db, _userInfo.userId, _transactionId);
        require(ETicketEvent.eventStateModiableTransaction(_db, _transactionInfo.eventId));
        var state = ETicketDB(_db).getUint32(sha3("transactions", _transactionInfo.ticketGroupId, "state"));
        require(state.equalsState(TXNST_UNSALABLE));
        ETicketDB(_db).setUint32(sha3("transactions", _transactionInfo.transactionId, "state"), state.changeState(TXNST_UNSALABLE, TXNST_SALABLE));
        ETicketDB(_db).incrementUint256(sha3("transactions", _transactionInfo.transactionId, "version"));
    }

    function setTransactionUnsalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _userInfo = ETicketUser.getSenderUserInfo(_db);
        var _transactionInfo = getOwnerTransationInfo(_db, _userInfo.userId, _transactionId);
        require(ETicketEvent.eventStateModiableTransaction(_db, _transactionInfo.eventId));
        var state = ETicketDB(_db).getUint32(sha3("transactions", _transactionInfo.ticketGroupId, "state"));
        require(state.equalsState(TXNST_SALABLE));
        ETicketDB(_db).setUint32(sha3("transactions", _transactionInfo.transactionId, "state"), state.changeState(TXNST_SALABLE, TXNST_UNSALABLE));
        ETicketDB(_db).incrementUint256(sha3("transactions", _transactionInfo.transactionId, "version"));
    }
    
    function splitTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _transactionId, uint256 _amount) returns (bool) {
        var _transactionInfo = getExistsTransationInfo(_ticketDB, _transactionId);
        require(ETicketTicketGroup.ticketGroupStateSalableTicket(_ticketDB, _transactionInfo.eventId, _transactionInfo.ticketGroupId));
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        var state = ETicketDB(_ticketDB).getUint32(sha3("transactions", _transactionInfo.ticketGroupId, "state"));
        require(state.equalsState(TXNST_SALABLE));
        var remainTickets = getRemainTickets(_ticketDB, _transactionId);
        require(remainTickets >= _amount);
        var _totalPrice = getTransactionTotalPrice(_ticketDB, _transactionId, _amount);       
        require(TokenDB(_tokenDB).getBalance(msg.sender) <= _totalPrice.total);
        // チケットグループに新しい取引情報の作成
        var _newUserInfo = ETicketUser.getSenderUserInfo(_ticketDB);
        var _newTransactionId = ETicketDB(_ticketDB).getAndIncrementId(sha3("transactionId"));        
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "userId"), _newUserInfo.userId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "eventId"), _transactionInfo.eventId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "ticketGroupId"), _transactionInfo.ticketGroupId);
        ETicketDB(_ticketDB).setUint256(sha3("transactions", _newTransactionId, "eventOwnerId"), _transactionInfo.eventOwnerId);
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
        var _transactionInfo = getOwnerTransationInfo(_ticketDB, _userInfo.userId, _transactionId);
        require(ETicketEvent.eventStateCancelableTicket(_ticketDB, _transactionInfo.eventId));
        require(_amount > 0);
        var _remainTickets = getRemainTickets(_ticketDB, _transactionId);
        require(_remainTickets >= _amount);
        var _totalPrice = getTransactionTotalPrice(_ticketDB, _transactionId, _amount);
        // 取引情報の更新
        subBuyTickets(_ticketDB, _transactionId, _amount);
        // ticketGroupの情報更新
        ETicketTicketGroup.subSoldTicket(_ticketDB, _transactionInfo.ticketGroupId, _amount);
        // eventの情報更新
        ETicketEvent.subAmountSold(_ticketDB, _transactionInfo.eventId, _totalPrice.total);
        // ユーザにお金を戻す
        TokenDB(_tokenDB).addBalance(msg.sender, _totalPrice.total);
    }
}

