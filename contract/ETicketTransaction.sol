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
    // transactions <transactionId> ticketGroupId
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
    
    uint32 constant TXNST_SALABLE   = 0x01;
    uint32 constant TXNST_UNSALABLE = 0x01;
    
    struct transaction {
        ETicketDB db;
        uint256 transactionId;
        // memebers
        uint256 userId;
        uint256 ticketGroupId;
        uint256 buyTickets;
        uint256 reservedTickets;
        uint256 buyPrice;
        uint256 totalCashBackPrice;
        uint32 state;
        // parent
        ETicketUser.user user;
        ETicketTicketGroup.ticketGroup ticketGroup;
        // shadows
        uint256 __userId;
        uint256 __ticketGroupId;
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
        _transaction.transactionId = _transactionId;
        _transaction.userId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "userId"));
        _transaction.ticketGroupId = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "ticketGroupId"));
        _transaction.buyTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyTickets"));
        _transaction.reservedTickets = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "reservedTickets"));
        _transaction.buyPrice = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "buyPrice"));
        _transaction.totalCashBackPrice = ETicketDB(_db).getUint256(sha3("transactions", _transactionId, "totalCashBackPrice"));
        _transaction.state = ETicketDB(_db).getUint32(sha3("transactions", _transactionId, "state")); 
        // set shadows
        _transaction.__userId = _transaction.userId;
        _transaction.__ticketGroupId = _transaction.ticketGroupId;
        _transaction.__buyTickets = _transaction.buyTickets;
        _transaction.__reservedTickets = _transaction.reservedTickets;
        _transaction.__buyPrice = _transaction.buyPrice;
        _transaction.__totalCashBackPrice = _transaction.totalCashBackPrice;
        _transaction.__state = _transaction.state;
         require(_transaction.state != 0);
        // parent
        _transaction.user = ETicketUser.getExistsUser(_db, _transaction.userId);
        _transaction.ticketGroup = ETicketTicketGroup.getExistsTicketGroup(_db, _transaction.ticketGroupId);
    }

    function _save(transaction _transaction) private returns (bool){
        bool changed = false;
        if (_transaction.userId != _transaction.__userId) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "userId"), _transaction.userId);
            changed = true;
        }
        if (_transaction.ticketGroupId != _transaction.ticketGroupId) {
            ETicketDB(_transaction.db).setUint256(sha3("transactions", _transaction.transactionId, "ticketGroupId"), _transaction.ticketGroupId);
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
            _transaction.user.transactionUpdateTime = now;
        }
        ETicketTicketGroup.updateTicketGroup(_transaction.ticketGroup);
        ETicketUser.updateUser(_transaction.user);
        return true;
    }

    function _new(
        ETicketDB _db,
        ETicketUser.user _user, 
        ETicketTicketGroup.ticketGroup _ticketGroup, 
        uint256 _amount,
        uint32 _state
        ) private returns (transaction _transaction) {
        _transaction.db = _db;
        _transaction.transactionId = _newId(_db);
        _transaction.userId = _user.userId;
        _transaction.ticketGroupId = _ticketGroup.ticketGroupId;
        _transaction.buyTickets = _amount;
        _transaction.reservedTickets = 0;
        _transaction.buyPrice = _ticketGroup.price;
        _transaction.totalCashBackPrice = 0;
        _transaction.state = _state;
        _transaction.ticketGroup = _ticketGroup;
        _transaction.user = _user;
    }

    function _clone(
        ETicketDB _db,
        ETicketUser.user _user, 
        transaction _transaction, 
        uint256 _amount,
        uint32 _state
        ) private returns (transaction _newTransaction) {
        _newTransaction.db = _db;
        _newTransaction.transactionId = _newId(_db);
        _newTransaction.userId = _user.userId;
        _newTransaction.ticketGroupId = _transaction.ticketGroupId;
        _newTransaction.buyTickets = _amount;
        _newTransaction.reservedTickets = 0;
        _newTransaction.buyPrice = _transaction.buyPrice;
        _newTransaction.totalCashBackPrice = 0;
        _newTransaction.state = _state;
        _newTransaction.ticketGroup = _transaction.ticketGroup;
        _transaction.user = _user;
    }
    
    function updateTransaction(transaction _transaction) internal returns (bool) {
        return _save(_transaction);
    }
    
    function isModifiableTransactionState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isModifiableTransactionState(_transaction.ticketGroup);
    }
    
    function isSalableTransactionState(transaction _transaction) internal returns (bool) {
        return _transaction.state.equalsState(TXNST_SALABLE) && 
               ETicketTicketGroup.isSalableTransactionState(_transaction.ticketGroup);
    }

    function isCancelableTransactionState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isCancelableTransactionState(_transaction.ticketGroup);
    }

    function isCreatableTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isCreatableTicketContextState(_transaction.ticketGroup);
    }
    
    function isTransferableTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isTransferableTicketContextState(_transaction.ticketGroup);
    }

    function isModifiableTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isModifiableTicketContextState(_transaction.ticketGroup);
    }

    function isSalableTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isSalableTicketContextState(_transaction.ticketGroup);
    }
    
    function isCashBackTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isCashBackTicketContextState(_transaction.ticketGroup);
    }
    
    function isEnterableTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isEnterableTicketContextState(_transaction.ticketGroup);
    }

    function isRefundableTicketContextState(transaction _transaction) internal returns (bool) {
        return ETicketTicketGroup.isRefundableTicketContextState(_transaction.ticketGroup);
    }

    function getAndIncrementSerialNumber(transaction _transaction) internal returns (uint256) {
        return ETicketTicketGroup.getAndIncrementSerialNumbertransaction(_transaction.ticketGroup);
    }
    
    function getReserveOracleUrl(transaction _transaction) internal returns (string) {
        return  ETicketTicketGroup.getReserveOracleUrl(_transaction.ticketGroup);
    }

    function getEnterOracleUrl(transaction _transaction) internal returns (string) {
        return  ETicketTicketGroup.getEnterOracleUrl(_transaction.ticketGroup);
    }

    function getCashBackOracleUrl(transaction _transaction) internal returns (string) {
        return  ETicketTicketGroup.getCashBackOracleUrl(_transaction.ticketGroup);
    }

    function getTransactionBuyPrice(transaction _transaction) internal returns (uint256) {
        return _transaction.buyPrice;
    }

    function getTransactionTotalPrice(transaction _transaction, uint256 _amount) internal returns (uint256) {
        return _transaction.buyPrice.mul(_amount);
    }

    function getRemainTickets(transaction _transaction) internal returns (uint256) {
        return _transaction.buyTickets.sub(_transaction.reservedTickets);
    }

    function getEventOwnerUser(transaction _transaction) internal returns (ETicketUser.user) {
        return ETicketTicketGroup.getEventOwnerUser(_transaction.ticketGroup);
    }

    function subBuyTickets(transaction _transaction, uint256 _amount) internal returns (bool) {
        _transaction.buyTickets = _transaction.buyTickets.sub(_amount);
        return true;
    }
    
    function subSoldTicket(transaction _transaction, uint256 _amount) internal returns (bool) {
        return ETicketTicketGroup.subSoldTicket(_transaction.ticketGroup, _amount); 
    }
    
    function subAmountSold(transaction _transaction, uint256 _totalPrice) internal returns (bool) {
        return ETicketTicketGroup.subAmountSold(_transaction.ticketGroup, _totalPrice); 
    }
    
    function getExistsTransaction(ETicketDB _db, uint256 _transactionId) internal returns(transaction) {
        return _load(_db, _transactionId);
    }

    function getSenderTransaction(ETicketDB _db, uint256 _transactionId) internal returns(transaction) {
        var _user = ETicketUser.getSenderUser(_db);
        var _transaction = _load(_db, _transactionId);
        require(_transaction.userId != _user.userId);
        return _transaction;
    }
    
    function createTransaction(
        ETicketDB _ticketDB, 
        TokenDB _tokenDB, 
        uint256 _ticketGroupId, 
        uint256 _amount
        ) internal returns (uint256) {
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        var _ticketGroup = ETicketTicketGroup.getExistsTicketGroup(_ticketDB, _ticketGroupId);
        require(ETicketTicketGroup.isSalableTicketGroupState(_ticketGroup));
        require(ETicketTicketGroup.getSalableTickets(_ticketGroup) >= _amount);
        var _totalPrice = ETicketTicketGroup.getTicketGroupTotalPrice(_ticketGroup, _amount);
        require(TokenDB(_tokenDB).getBalance(msg.sender) >= _totalPrice);
        var _transaction = _new(_ticketDB, ETicketUser.getSenderUser(_ticketDB), _ticketGroup, _amount, TXNST_UNSALABLE); 
        ETicketTicketGroup.addSoldTicket(_transaction.ticketGroup, _amount);
        ETicketTicketGroup.addAmountSold(_transaction.ticketGroup, _totalPrice);
        TokenDB(_tokenDB).subBalance(msg.sender, _totalPrice);
        _save(_transaction);
        return _transaction.transactionId;
    }

    function setTransactionSalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _transaction = getSenderTransaction(_db, _transactionId);
        require(isModifiableTransactionState(_transaction));
        require(_transaction.state.equalsState(TXNST_UNSALABLE));
        _transaction.state = _transaction.state.changeState(TXNST_UNSALABLE, TXNST_SALABLE);
        return _save(_transaction);
    }

    function setTransactionUnsalable(ETicketDB _db, uint256 _transactionId) internal returns (bool) {
        var _transaction = getSenderTransaction(_db, _transactionId);
        require(isModifiableTransactionState(_transaction));
        require(_transaction.state.equalsState(TXNST_SALABLE));
        _transaction.state = _transaction.state.changeState(TXNST_SALABLE, TXNST_UNSALABLE);
        return _save(_transaction);
    }

    function buyTransaction(
        ETicketDB _ticketDB, 
        TokenDB _tokenDB, 
        uint256 _transactionId, 
        uint256 _amount
        ) returns (uint256) {
        require(Validation.validUint256Range(_amount, 1, MAX_BUYABLE_TICKETS));
        var _transaction = getExistsTransaction(_ticketDB, _transactionId);
        require(isSalableTransactionState(_transaction));
        require(getRemainTickets(_transaction) >= _amount);
        var _totalPrice = getTransactionTotalPrice(_transaction, _amount);      
        require(TokenDB(_tokenDB).getBalance(msg.sender) <= _totalPrice);
        var _newTransaction = _clone(_ticketDB, ETicketUser.getSenderUser(_ticketDB), _transaction, _amount, TXNST_UNSALABLE);
        subBuyTickets(_transaction, _amount);
        _save(_transaction);
        _save(_newTransaction);
        TokenDB(_tokenDB).addBalance(_transaction.user.userAddress, _totalPrice);
        TokenDB(_tokenDB).subBalance(_newTransaction.user.userAddress, _totalPrice);
        return _newTransaction.transactionId;
    }

    function cancelTransaction(
        ETicketDB _ticketDB, 
        TokenDB _tokenDB, 
        uint256 _transactionId, 
        uint256 _amount
        ) internal returns (bool) {
        require(_amount > 0);
        var _transaction = getSenderTransaction(_ticketDB, _transactionId);
        require(isCancelableTransactionState(_transaction));
        require(getRemainTickets(_transaction) >= _amount);
        var _totalPrice = getTransactionTotalPrice(_transaction, _amount);
        subBuyTickets(_transaction, _amount);
        subSoldTicket(_transaction, _amount);       
        subAmountSold(_transaction, _totalPrice);
        TokenDB(_tokenDB).addBalance(msg.sender, _totalPrice);
        return _save(_transaction);
    }
}


