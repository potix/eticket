pragma solidity ^0.4.14;

import "./TicketInterface.sol";
import "./Token.sol";
import "./State.sol";
import "./TicketDB.sol";

contract Ticket is TicketInterface, Token {
    using State for uint32;  
    
    address ticketDB;
    
    function Ticket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != 0x0);
        ticketDB = _ticketDB;
    }

    function removeTicketDB() onlyOwner returns (bool) {
        ticketDB = address(0);
        return true;
    }

    // [user] 
    // userId
    // users <userId> "address"
    // users <userId> "name"
    // users <userId> "email"
    // users <userId> profile
    // users <userId> version
    // idMap <address> <userId>

    function isOwnerUser(uint256 _userId) returns (bool) {
        var _address = TicketDB(ticketDB).getAddress(sha3("users", _userId, "address"));
        return (msg.sender == _address);
    }

    function createAndModifyUserCommon(
        uint256 _userId,
        string _name, 
        string _email, 
        string _profile
    ) {
        var b = bytes(_name);
        require(b.length > 0 && b.length <= 100);
        b = bytes(_email);
        require(b.length <= 100);
        b = bytes(_profile);
        require(b.length <= 1000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "email"), _email);
        TicketDB(ticketDB).setString(sha3("users", _userId, "profile"), _profile);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "version"));
    }

    function createUser(
        string _name, 
        string _email,
        string _profile
        ) returns (uint256) {
        require(msg.sender != 0x0);
        var _userId = TicketDB(ticketDB).getAndIncrementId(sha3("userId"));
        TicketDB(ticketDB).setAddress(sha3("users", _userId, "address"), msg.sender);
        createAndModifyUserCommon(_userId, _name, _email, _profile);
        TicketDB(ticketDB).setIdMap(msg.sender, _userId);
        return _userId;
    }

    function modifyUser(
        string _name, 
        string _email, 
        string _profile
        ) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        createAndModifyUserCommon(_userId, _name, _email, _profile);
        return true;
    }

    // [event] 
    // userId <userId> eventId
    // users <userId> events <eventId> name
    // users <userId> events <eventId> country [ISO_3166-1 alpha-2 or alpha-3]
    // users <userId> events <eventId> tags
    // users <userId> events <eventId> description
    // users <userId> events <eventId> memorialOracleUrlOfReserved
    // users <userId> events <eventId> memorialOracleUrlOfEntered
    // users <userId> events <eventId> cashBackOracleUrl
    // users <userId> events <eventId> amountSold
    // users <userId> events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    // users <userId> events <eventId> version

    // [event reference]
    // eventRefId
    // eventRefs <eventrefId> eventOwner(userId)
    // eventRefs <eventrefId> eventId

    uint32 constant EVST_CREATE  = 0x01;
    uint32 constant EVST_SALE    = 0x02;
    uint32 constant EVST_OPEN    = 0x04;
    uint32 constant EVST_READY   = 0x08;
    uint32 constant EVST_STOP    = 0x10;
    uint32 constant EVST_CLOSE   = 0x20;
    uint32 constant EVST_COLLECT = 0x40;

    function isEventExists(uint256 _userId, uint256 _eventId) returns (bool) {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        return (_state != 0);
    }

    function createAndModifyEventCommon(
        uint256 _userId,
        uint256 _eventId,
        string _name, 
        string _country, 
        string _tags, 
        string _description, 
        string _reserveOracleUrl, 
        string _entereOracleUrl, 
        string _cashBackOracleUrl
        ) returns (uint256) {
        var b = bytes(_name);
        require(b.length > 0 && b.length <= 200);
        b = bytes(_country);
        require(b.length > 0 && b.length <= 3);
        b = bytes(_tags);
        require(b.length <= 1000);
        b = bytes(_description);
        require(b.length <= 10000);
        b = bytes(_reserveOracleUrl);
        require(b.length <= 2000);
        b = bytes(_entereOracleUrl);
        require(b.length <= 2000);
        b = bytes(_cashBackOracleUrl);
        require(b.length <= 2000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "country"), _country);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "tags"), _tags);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "description"), _description);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "reserveOracleUrl"), _reserveOracleUrl);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "entereOracleUrl"), _entereOracleUrl);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "cashBackOracleUrl"), _cashBackOracleUrl);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "amountSold"), 0);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        return _eventId;
    }
    
    function createEvent(
        string _name, 
        string _country, 
        string _tags, 
        string _description, 
        string _reserveOracleUrl, 
        string _entereOracleUrl, 
        string _cashBackOracleUrl
        ) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        var _eventId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId"));
        createAndModifyEventCommon(
            _userId,
            _eventId,
            _name, 
            _country, 
            _tags, 
            _description, 
            _reserveOracleUrl, 
            _entereOracleUrl, 
            _cashBackOracleUrl);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "amountSold"), 0);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), EVST_CREATE);
        var _eventRefId = TicketDB(ticketDB).getAndIncrementId(sha3("eventRegId"));
        TicketDB(ticketDB).setUint256(sha3("eventRefs", _eventRefId, "userId"), _userId);
        TicketDB(ticketDB).setUint256(sha3("eventRefs", _eventRefId, "eventId"), _eventId);
        return _eventId;
    }

    function modifyEvent(
        uint256 _eventId,
        string _name, 
        string _country, 
        string _tags, 
        string _description, 
        string _reserveOracleUrl, 
        string _entereOracleUrl, 
        string _cashBackOracleUrl
        ) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        createAndModifyEventCommon(
            _userId,
            _eventId,
            _name, 
            _country, 
            _tags, 
            _description, 
            _reserveOracleUrl, 
            _entereOracleUrl, 
            _cashBackOracleUrl);
        return true;
    }

    function openEvent(uint256 _eventId) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_SALE|EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_SALE|EVST_READY), EVST_OPEN));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        // reserveがenter,cashbackできるようになる
    }

    function readyEvent(uint256 _eventId) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_OPEN|EVST_CLOSE));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        // cancelができなくなる
    }

    function stopEvent(uint256 _eventId) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CREATE|EVST_SALE|EVST_OPEN|EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_OPEN|EVST_CLOSE), EVST_READY));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        // イベントを中止せざるをえなくなったとき
        // すべての購入者へトークンの返却が可能になる
        // 返却は自己申告制
        // reserveしてない人はcancelで
        // reserveしちゃった人はrefundで
        // これ以降の状態変更はない
    }

    function closeEvent(uint256 _eventId) { 
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_READY));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_READY), EVST_CLOSE));
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        // reservedとかenterとかcashbackとかとかできなくなる
    }

   function collectAmountSold(uint256 _eventId) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "state"));
        require(_state.includesState(EVST_CLOSE));
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "state"), _state.changeState((EVST_CLOSE), EVST_COLLECT));
        var _amountSold = TicketDB(ticketDB).getUint256(sha3("users", _userId, "events", _eventId, "amountSold"));
        TokenDB(tokenDB).addBalance(msg.sender, _amountSold);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "version"));
        // 購入した人のトークンが回収される
        // これをやるまでは状態として記録されているだけ
        // これ以降の状態変更はない
    }

    // [ticketGroup]
    // userId <userId> eventId <eventId> ticketGroupId
    // users <userId> events <eventId> ticketGroups <ticketGroupId> name
    // users <userId> events <eventId> ticketGroups <ticketGroupId> description
    // users <userId> events <eventId> ticketGroups <ticketGroupId> supplyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> soldTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> maxPrice
    // users <userId> events <eventId> ticketGroups <ticketGroupId> price
    // users <userId> events <eventId> ticketGroups <ticketGroupId> admountSold
    // users <userId> events <eventId> ticketGroups <ticketGroupId> lastSerialNumber
    // users <userId> events <eventId> ticketGroups <ticketGroupId> state [ 0x01 SALE 0x02 BLOCK ]
    // users <userId> events <eventId> ticketGroups <ticketGroupId> version
    
    uint32 constant TGST_SALE  = 0x01;
    uint32 constant TGST_BLOCK = 0x02;


    function isTicketGroupExists(uint256 _userId, uint256 _eventId, uint256 _ticketGroupId) returns (bool) {
        var _state = TicketDB(ticketDB).getUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"));
        return (_state != 0);
    }

    function createAndModifyTicketGroupCommon(
        uint256 _userId,
        uint256 _eventId,
        uint256 _ticketGroupId,
        string _name, 
        string _description, 
        uint32 _supplyTickets, 
        uint32 _maxPrice, 
        uint32 _price) {
        var b = bytes(_name);
        require(b.length > 0 && b.length <= 100);
        b = bytes(_description);
        require(b.length <= 1000);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "name"), _name);
        TicketDB(ticketDB).setString(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "description"), _description);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "suplyTickets"), _supplyTickets);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "maxPrice"), _maxPrice);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "price"), _price);
        TicketDB(ticketDB).incrementUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId,  "version"));
    }
    
    function createTicketGroup(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint32 _supplyTickets,
        uint32 _maxPrice,
        uint32 _price) returns (uint256) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        var _ticketGroupId = TicketDB(ticketDB).getAndIncrementId(sha3("userId", _userId, "eventId", _eventId, "ticketGroupId"));
        createAndModifyTicketGroupCommon(
            _userId,
            _eventId,
            _ticketGroupId,
            _name, 
            _description, 
            _supplyTickets, 
            _maxPrice, 
            _price);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "soldTickets"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "amountSold"), 0);
        TicketDB(ticketDB).setUint256(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "lastSerialNumber"), 0);
        TicketDB(ticketDB).setUint32(sha3("users", _userId, "events", _eventId, "ticketGroups", _ticketGroupId, "state"), TGST_SALE);
        return _ticketGroupId;
    }

    function modifyTicketGroup(
        uint256 _eventId,
        uint256 _ticketGroupId,
        string _name, 
        string _description,
        uint32 _supplyTickets,
        uint32 _maxPrice,
        uint32 _price) returns (bool) {
        var _userId = TicketDB(ticketDB).getIdMap(msg.sender);
        require(isOwnerUser(_userId));
        require(isEventExists(_userId, _eventId));
        require(isTicketGroupExists(_userId, _eventId, _ticketGroupId));
        createAndModifyTicketGroupCommon(
            _userId,
            _eventId,
            _ticketGroupId,
            _name, 
            _description, 
            _supplyTickets, 
            _maxPrice, 
            _price);
        return true;
    }


    function blockPriceTicketGroup(uint256 _eventId, uint256 ticketGroupId) {
        // チケットグループのMAX料金を変更する
    }

    function unblockPriceTicketGroup(uint256 _eventId, uint256 ticketGroupId) {
        // チケットグループのMAX料金を変更する
    }


    function changeMaxPriceTicketGroup(uint256 _eventId, uint256 ticketGroupId) {
        // チケットグループのMAX料金を変更する
    }

    function changePriceTicketGroup(uint256 _eventId, uint256 ticketGroupId) {
        // チケットグループの料金を変更する
    }

    function addTicket(uint256 _eventId, uint256 ticketGroupId) {
        // チケットグループのチケット供給量を増やす
    }

    function subTicket(uint256 _eventId, uint256 ticketGroupId) {
        // チケットグループのチケット供給量を減らす
    }


    // [ticketBuyer]
    // userId <userId> eventId <eventId> ticketGroupId <ticketGroupId> buyerId
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> buyer(userId)
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> buyTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> reservedTickets
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> buyPrioce
    // users <userId> events <eventId> ticketGroups <ticketGroupId> buyers <buyerId> totalCashBackPrice

    // [userBuyTicket]
    // userId <userId> buyTicketId
    // users <userId> buyTickets >buyTicketId> eventOwner(userId)
    // users <userId> buyTickets >buyTicketId> eventId
    // users <userId> buyTickets >buyTicketId> ticketGroupId
    // users <userId> buyTickets >buyTicketId> buyerId

    function buyTicket(uint256 _userid, uint256 ticketGroupid) {
        // ちけっとを購入する 
        // groupIdと数量をしていしてまとめて買える
        // 買うごとにbyerIdは新たに発行される
    }
    
    function cancelTicket(uint256 _userid, uint256 groupid, uint256 ticketGroupId, uint256 buyerid, uint256 amount) {
        // ちけっとをキャンセルする
        // すうまいだけのキャンセルも可能
    }

    // [ticketContext]
    // users <userId> events <eventId> ticketCtxId
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> eventOwner(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> eventId
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> ticketGroupId
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> buyer(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> prevTicketOwner(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> ticketOwner(userId)
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> reservedUrl
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> EnteredUrl
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> cashBackPrice
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> enterCode
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> serialNumber
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> BuyPrice
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> salePrice
    // users <userId> events <eventId> ticketCtxs <ticketCtxId> state [ 0x10 SALABLE, 0x01 RESERVED, 0x02 ENTERD ]

    // [userTicketCtx]
    // userId <userId> reservedTicketCtxId
    // users <userId> reservedTicketCtxs >reservedTicketCtxId> eventOwner(userId) 
    // users <userId> reservedTicketCtxs >reservedTicketCtxId> eventId
    // users <userId> reservedTicketCtxs >reservedTicketCtxId> ticketCtxId

    function reserveTicket(uint amount) { // まとめてreserveできる
        // 参加予約する
        // reserveするとキャンセルはできなくなる
        // cashbackのアクティベートができるようになる(cachbackのアクティベートしたら他人に売れなくなる)
        // 量をまとめてしていするとシリアル番号は必ず並ぶ
        // oraclizeでreverve記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる
    }

    function transferTicketCtx() { 
        //　チケットコンテキストの所有者変更、無料で他人にゆずる。男前
    }

    function enableSaleTicketCtx(uint32 price) { 
        //　チケットコンテキストをSALABLE状態にする
        // cachebackしてたらsalableの変更はできない
        // 値段は　eventOwnerが設定したmaxPriceを超えられない。残念だったな。
    }

    function disableSaleTicketCtx() { //　チケットコンテキストをSALABLE状態じゃなくす
        // cachebackしてたらsalableの変更はできない
    }

    function buyTicketCtx() { 
        //　チケットコンテキストがSALABLEの場合にチケットを買うことができる
        // end to end で買うとということ
        // だれかに購入に必要な情報を教えてもらわないと、検索して探すのはほぼ無理
    }

    function activateCacheBack() {
        // キャッシュバックコードをoraclizeでなげるとcachebackされる
        // cashbackを受けるともう他人へ売却することはできなくなる、譲渡はできる
    }
    
    function enterTicketCtx() { // 入場記念処置イベンターがやる
        // oraclizeでr入場記念URLを発行する、そのURLにアクセスすると素敵なことがあるようにできる
    }
    

    function refundTicketCtx() {
        
    }

}





