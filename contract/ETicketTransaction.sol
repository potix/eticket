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
        _transaction.buyTickets = _amount;
        _transaction.reservedTickets = 0;
        _transaction.buyPrice = _ticketGroup.price;
        _transaction.totalCashBackPrice = 0;
        _transaction.state = _state;
        _transaction.ticketGroup = _ticketGroup;
    }

    function _renew(
        ETicketDB _db,
        transaction _transaction, 
        uint256 _amount,
        uint32 _state
        ) private returns (transaction _newTransaction) {
        _newTransaction.db = _db;
        _newTransaction.transactionId = _newId(_db);
        _newTransaction.userId = ETicketUser.getSenderUserId();
        _newTransaction.eventId = _transaction.eventId;
        _newTransaction.ticketGroupId = _transaction.ticketGroupId;
        _newTransaction.eventOwnerId = _transaction.eventOwnerId;
        _newTransaction.buyTickets = _amount;
        _newTransaction.reservedTickets = 0;
        _newTransaction.buyPrice = _transaction.buyPrice;
        _newTransaction.totalCashBackPrice = 0;
        _newTransaction.state = _state;
        _newTransaction.ticketGroup = _transaction._ticketGroup;
    }

    function isSalableTransactionState(transaction _transaction) {
        return _transaction.state.equalsState(TXNST_SALABLE) && ETicketTicketGroup.isSalableTransactionState(_transaction.ticketGroup);
    }

    function getTransactionTotalPrice(transaction _transaction, uint256 _amount) internal returns (uint256) {
        return _transaction.buyPrice.mul(_amount);
    }

    function getRemainTickets(transaction _transaction) internal returns (uint256) {
        return _transaction.buyTickets.sub(_transaction.reservedTickets);
    }

    function subBuyTicket(transaction _transaction, uint256 _amount) internal returns (bool) {
        _transaction.buyTickets = _transaction.buyTickets - _amount;
        return true;
    }
    
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
        require(ETicketTicketGroup.isSalableTicketGroupState(_ticketGroup));
        var salableTickets = ETicketTicketGroup.getSalableTickets(_ticketGroup);
        require(salableTickets >= _amount);
        var _totalPrice = ETicketTicketGroup.getTicketGroupTotalPrice(_ticketGroup, _amount);
        require(TokenDB(_tokenDB).getBalance(msg.sender) >= _totalPrice);
        var transaction = _new(_ticketDB, _ticketGroup, _amount, TXNST_UNSALABLE); 
        ETicketTicketGroup.addSoldTicket(_transaction.ticketGroup, _amount);
        ETicketTicketGroup.addAmountSold(_transaction.ticketGroup, _totalPrice)
        TokenDB(_tokenDB).subBalance(msg.sender, _totalPrice);
        return _save(_transaction);
    }

    function setTransactionSalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _transaction = ETicketTicketGroup.getSenderTransaction(_db, _transactionId);
        require(ETicketTicketGroup.isModiableTransactionState(_db, _transaction.ticketGroup.userEvent));
        require(_transaction.state.equalsState(TXNST_UNSALABLE));
        _transaction.state = _transaction.state.changeState(TXNST_UNSALABLE, TXNST_SALABLE));
        return _save(_transaction);
    }

    function setTransactionUnsalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _transaction = ETicketTicketGroup.getSenderTransaction(_db, _transactionId);
        require(ETicketTicketGroup.isModiableTransactionState(_db, _transaction.ticketGroup.userEvent));
        require(_transaction.state.equalsState(TXNST_SALABLE));
        _transaction.state = _transaction.state.changeState(TXNST_SALABLE, TXNST_UNSALABLE));
        return _save(_transaction);
    }

    function splitTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _transactionId, uint256 _amount) returns (transaction) {
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        var _transaction = getExistsTransation(_ticketDB, _transactionId);
        require(isSalableTransactionState(_transaction));
        var _remainTickets = getRemainTickets(_transaction);
        require(remainTickets >= _amount);
        var _totalPrice = getTransactionTotalPrice(_ticketDB, _transactionId, _amount);      
        require(TokenDB(_tokenDB).getBalance(msg.sender) <= _totalPrice);
        var newTransaction = _renew(_ticketDB, _transaction, _amount, TXNST_UNSALABLE);
        subBuyTickets(_transaction, _amount);
        var transactionUser = getExistsUser(_transaction.userId);
        _save(_transaction);
        _save(_newTransaction);
        TokenDB(_tokenDB).addBalance(transactionUser.userAddress, _totalPrice);
        TokenDB(_tokenDB).subBalance(msg.sender, _totalPrice);
        return _newTransaction;
    }

    function cancelTransaction(ETicketDB _ticketDB, TokenDB _tokenDB, uint256 _transactionId, uint256 _amount) internal returns (bool) {
        require(_amount > 0);
        var _transaction = ETicketTicketGroup.getSenderTransaction(_ticketDB, _transactionId);
        require(ETicketTicketGroup.isCancelableTransactionState(_transaction.ticketGoup));
        var _remainTickets = getRemainTickets(_transaction);
        require(_remainTickets >= _amount);
        var _totalPrice = getTransactionTotalPrice(_ticketDB, _transactionId, _amount);
        subBuyTickets(_transaction, _amount);
        ETicketTicketGroup.subSoldTicket(_transaction, _amount);       
        ETicketTicketGroup.subAmountSold(_transaction, _totalPrice)
        TokenDB(_tokenDB).addBalance(msg.sender, _totalPricel);
        return _save(_transaction);
    }
}


