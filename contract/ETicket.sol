pragma solidity ^0.4.14;

import "./ETicketInterface.sol";
import "./Token.sol";
import "./State.sol";
import "./ETicketTicketContext.sol";
import "./ETicketTransaction.sol";
import "./ETicketTicketGroup.sol";
import "./ETicketEvent.sol";
import "./ETicketUser.sol";
import "./ETicketDB.sol";

contract ETicket is ETicketInterface, Token {
    address ticketDB;
    
    function Ticket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != 0x0);
        ticketDB = _ticketDB;
    }

    function removeTicketDB() onlyOwner returns (bool) {
        ticketDB = address(0);
        return true;
    }
    
    // user

    function createUser(string _name, string _email, string _profile) returns (uint256) {
        return ETicketUser.createUser(ticketDB, _name, _email, _profile);
    }

    function setUserName(string _name) returns (bool) {
        return ETicketUser.setUserName(ticketDB, _name);
    }

    function setUserEmail(string _email) returns (bool) {
       return ETicketUser.setUserEmail(ticketDB, _email);
    }

    function setUserProfile(string _profile) returns (bool) {
       return ETicketUser.setUserProfile(ticketDB, _profile);
    }

    // event

    function createEventWithSalable(
        string _name, 
        string _country, 
        string _description, 
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashBackOracleUrl
        )  returns (uint256) {
        return ETicketEvent.createEventWithSalable(ticketDB, _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashBackOracleUrl);
    }

    function createEventWithUnsalable(
        string _name, 
        string _country, 
        string _description, 
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashBackOracleUrl
        )  returns (uint256) {
        return ETicketEvent.createEventWithUnSale(ticketDB, _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashBackOracleUrl);

    }

    function setEventName(uint256 _eventId, string _name) returns (bool) {
        return ETicketEvent.setEventName(ticketDB, _eventId, _name);
    }

    function setEventCountry(uint256 _eventId, string _country) returns (bool) {
        return ETicketEvent.setEventCountry(ticketDB, _eventId, _country);
    }

    function setEventDescription(uint256 _eventId, string _description)  returns (bool) {
        return ETicketEvent.setEventDescription(ticketDB, _eventId, _description);
    }

    function setEventReserveOracleUrl(uint256 _eventId, string _reserveOracleUrl)  returns (bool) {
        return ETicketEvent.setEventReserveOracleUrl(ticketDB, _eventId, _reserveOracleUrl);
    }

    function setEventEnterOracleUrl(uint256 _eventId, string _enterOracleUrl)  returns (bool) {
        return ETicketEvent.setEventEnterOracleUrl(ticketDB, _eventId, _enterOracleUrl);
    }

    function setEventCashBackOracleUrl(uint256 _eventId, string _cashbackOracleUrl) returns (bool) {
        return ETicketEvent.setEventCashBackOracleUrl(ticketDB, _eventId, _cashbackOracleUrl);
    }

    function saleEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.saleEvent(ticketDB, _eventId);
    }

    function openEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.openEvent(ticketDB, _eventId);
    }

    function readyEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.readyEvent(ticketDB, _eventId);
    }

    function stopEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.stopEvent(ticketDB, _eventId);
    }

    function closeEvent(uint256 _eventId) returns (bool) { 
        return ETicketEvent.closeEvent(ticketDB, _eventId);
    }

   function collectEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.collectEvent(ticketDB, _eventId);
    }

    // ticketGroup

    function createTicketGroupWithSalable(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) returns (uint256) {
        return ETicketTicketGroup.createTicketGroupWithSalable(ticketDB, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
    }
    
    function createTicketGroupWithUnsalable(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) returns (uint256) {
        return ETicketTicketGroup.createTicketGroupWithUnsalable(ticketDB, _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
    }
    
    function setTicketGroupName(uint256 _eventId, uint256 _ticketGroupId, string _name) returns (bool) {
        return ETicketTicketGroup.setTicketGroupName(ticketDB, _ticketGroupId, _name);
    }
    
    function setTicketGroupDescription(uint256 _eventId, uint256 _ticketGroupId, string _description) returns (bool) {
        return ETicketTicketGroup.setTicketGroupDescription(ticketDB, _ticketGroupId, _description);
    }

    function addTicketGroupSupplyTickets(uint256 _eventId, uint256 _ticketGroupId,  uint256 _supplyTickets) returns (bool) {
        return ETicketTicketGroup.addTicketGroupSupplyTickets(ticketDB, _ticketGroupId, _supplyTickets);
    }

    function subTicketGroupSupplyTickets(uint256 _eventId, uint256 _ticketGroupId, uint256 _supplyTickets) returns (bool) {
        return ETicketTicketGroup.subTicketGroupSupplyTickets(ticketDB, _ticketGroupId, _supplyTickets);
    }

    function setTicketGroupMaxPrice(uint256 _eventId, uint256 _ticketGroupId, uint256 _maxPrice) returns (bool) {
        return ETicketTicketGroup.setTicketGroupMaxPrice(ticketDB, _ticketGroupId, _maxPrice);
    }

    function setTicketGroupPrice(uint256 _eventId, uint256 _ticketGroupId, uint256 _price)  returns (bool) {
        return ETicketTicketGroup.setTicketGroupPrice(ticketDB, _ticketGroupId, _price);
    }

    function setTicketGroupSalable(uint256 _eventId, uint256 _ticketGroupId) returns (bool) {
        return ETicketTicketGroup.setTicketGroupSalable(ticketDB, _ticketGroupId);
    }
    
    function setTicketGroupUnsalable(uint256 _eventId, uint256 _ticketGroupId) returns (bool) {
        return ETicketTicketGroup.setTicketGroupUnsalable(ticketDB, _ticketGroupId);
    }

    // transaction
    
    function createTransaction(uint256 _ticketGroupId, uint256 _amount) returns (uint256) {
        return ETicketTransaction.createTransaction(ticketDB, tokenDB, _ticketGroupId, _amount); 
    }
        
    function setTransactionSalable(uint256 _transactionId) returns (bool) {
        return ETicketTransaction.setTransactionSalable(ticketDB, _ticketGroupId); 
    }
    
    function setTransactionUnsalable(uint256 _transactionId) returns (bool) {
        return ETicketTransaction.setTransactionUnsalable(ticketDB, _ticketGroupId); 
    }
    
    function splitTransaction(uint256 _ticketGroupId, uint256 _amount) returns (uint256) {
        return ETicketTransaction.splitTransaction(ticketDB, tokenDB, _ticketGroupId, _amount); 
    }  
   
    function cancelTransaction(uint256 _ticketGroupId, uint256 _amount) returns (uint256) {
        return ETicketTransaction.cancelTransaction(ticketDB, tokenDB, _ticketGroupId, _amount); 
    }  
   
    // ticketContext  
 
    function reserveTicketValidation(uint256 _txnRefId, uint256 _amount) private {
        // トランザクションの参照情報の存在確認
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        txnRefExists(_userId, _txnRefId);
        // 必要な情報の取り出し
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _userId, "txnRefs", _txnRefId, "txnId"));
        // イベントオーナーの存在チェック
        userExists(_eventOwner);
        // イベントの存在チェック
        eventExists(_eventOwner, _eventId);
        // チケットグループの存在チェック
        ticketGroupExists(_eventOwner, _eventId, _ticketGroupId);
        // トランザクション情報の存在チェック
        txnExists(_eventOwner, _eventId, _ticketGroupId, _txnId);
        // イベントのステートチェック
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _eventOwner, "events", _eventId, "state"));
        require(_state.includesState(EVST_OPEN|EVST_READY));
        // 買った量を超えてreserveできない
        // もうすでにreserveしてる分も差し引く
        var _buyTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "buyTickets"));
        var _reservedTickets = TicketDB(ticketDB).getUint256(sha3("users", _eventOwner, "events", _eventId, "ticketGroups", _ticketGroupId, "txns", _txnId, "reservedTickets")); 
        require(_buyTickets.sub(_reservedTickets) >= _amount);
    }

    function reserveTicket(uint256 _buyTicketId, uint256 _amount) onlyOwnerUser() { 
        // チケットを参加予約する
        reserveTicketValidation(_buyTicketId, _amount); 
        var _buyer = TicketDB(ticketDB).getIdMap(msg.sender);
        var _eventOwner = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "eventOwner"));
        var _eventId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "eventId"));
        var _ticketGroupId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "ticketGroupId"));
        var _txnId = TicketDB(ticketDB).getUint256(sha3("users", _buyer, "buyTickets", _buyTicketId, "txnId"));        
 
        // ticketコンテキスト作成
        var _ticketCtxId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _eventOwner, "eventId", _eventId, "ticketCtxId"));        
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);
        TicketDB(ticketDB).setUint256(sha3("users", _eventOwner, "events", _eventId, "ticketCtxs", _ticketCtxId, "eventOwner"), _eventOwner);

        
        
        
        // まとめてreserveできる
        // 参加予約する
        // reserveするとキャンセルはできなくなる
        // cashbackのアクティベートができるようになる(cachbackのアクティベートしたら他人に売れなくなる)
        // 量をまとめてしていするとシリアル番号は必ず並ぶ
        // oraclizeでreverve記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる

    }

    function transferTicketCtx() onlyOwnerUser() { 
        //　チケットコンテキストの所有者変更、無料で他人にゆずる。男前
    }

    function enableSaleTicketCtx(uint32 price) onlyOwnerUser() { 
        //　チケットコンテキストをSALABLE状態にする
        // cachebackしてたらsalableの変更はできない
        // 値段は　eventOwnerが設定したmaxPriceを超えられない。残念だったな。
    }

    function disableSaleTicketCtx() onlyOwnerUser() { //　チケットコンテキストをSALABLE状態じゃなくす
        // cachebackしてたらsalableの変更はできない
    }
    
    
    
    
    
    
    
    

    function buyTicketCtx() { 
        //　チケットコンテキストがSALABLEの場合にチケットを買うことができる
        // end to end で買うとということ
        // だれかに購入に必要な情報を教えてもらわないと、検索して探すのはほぼ無理
    }

    function activateCacheBack() onlyOwnerUser() {
        // キャッシュバックコードをoraclizeでなげるとcachebackされる
        // cashbackを受けるともう他人へ売却することはできなくなる、譲渡はできる
    }
    
    function enterTicketCtx() { // 入場記念処置イベンターがやる
        // oraclizeでr入場記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる
        //　ゆずったり、売ったりできなくなる
    }
    

    function refundTicketCtx() onlyOwnerUser() {
        // stop後の払い戻し
    }

}







