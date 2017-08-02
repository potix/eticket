pragma solidity ^0.4.11;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./ValueFinder.sol";
import "./Random.sol";
import "./Convert.sol";

contract ETicketToken is StandardToken, Ownable, Random {
    // ticket関連ストレージコントラクトとそれを操作するライブラリロジックの分離
    // メインコントラクトは、ライブラリ関数を呼ぶだけにする
    // その際、ストレージコントラクトを渡す。
    
    // トークンとアプリケーション実装も分離
    // トークンはクラウドセールでも使えるように
    
    // 差分だけの更新ができるようにしたい
    // version情報だけをチェックできるようにしたい
    // いまのところ、リストデータを返すすべがない。
    // jsonでも作れれば話は違うけど。

    // cancelやイベント中止で主催者のトークンが足りない場合エラーになるけど
    // 一旦プールに入れておいて、回収を呼び出すまではとりだせないようにしたほうがいいかも
    // 回収を呼び出せる条件にイベントがcloseしていることを盛り込む
    
    // requireでエラー起こすより、リターンコード定義して返したほうがいい
    // requireは状態変更したが、入力的におかしい場合に留める

    using ValueFinder for ValueFinder.finder;
         
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    uint8 constant TS_SALE   = 0x10;
    uint8 constant TS_BUY    = 0x01;
    uint8 constant TS_JOIN   = 0x02;
    uint8 constant TS_ENTER  = 0x04;

    uint8 constant ES_OPENED    = 1;
    uint8 constant ES_STOPPED   = 2;
    uint8 constant ES_CLOSED    = 3;
    uint8 constant ES_COLLECTED = 4; // TODO 回収

    // publish ticket
    struct publishEventTicket {
        uint    groupId;
        address owner;
        int64   firstSoldPrice;
        uint32  price;
        string  cashBackOraclizeResponse;
        uint32  cashBack;
        string  joinOraclizeResponse;
        uint32  joinCode;
        uint8   status;
        uint64  version;
    }
    mapping (address => mapping(uint => publishEventTicket[])) publishEventTickets;

    // publish event
    struct publishEvent {
        string name;
        string attributes;
        string cashBackOraclizeUrl;
        string joinOraclizeUrl;
        uint32 maxPrice;
        uint8  status;
        uint groupCount;
        uint64 version;
    }
    mapping (address => publishEvent[]) publishEvents;

    // user
    struct user {
        string userNumber;
        string name;
        string attributes;
        uint64 version;
    }
    mapping (address => user) users;

    // search for user
    struct userRef {
        address user;
    }
    userRef[] userRefs;

    // search for event
    struct eventRef {
        address publisher;
        uint eventId;
    }
    eventRef[] eventRefs;

    // search for user ticket
    struct userTicketRef {
        address publisher;
        uint    eventId;
        uint    ticketId;
    }
    mapping (address => userTicketRef[]) userTicketRefs;

    modifier userRefExists(uint _userRefId) {
        require(_userRefId < userRefs.length);
        _;
    }

    modifier eventRefExists(uint _eventRefId) {
        require(_eventRefId < eventRefs.length);
        _;
    }
    
    modifier userTicketRefExists(address _address, uint _userTicketRefId) {
        require(_userTicketRefId < userTicketRefs[_address].length);
        _;
    }
    
    modifier userExists(address _address) {
        require(bytes(users[_address].name).length != 0);
        _;
    }

    modifier userNotExists(address _address) {
        require(bytes(users[_address].name).length == 0);
        _;
    }
    
    modifier eventExists(address _address, uint _eventId) {
        require(bytes(users[_address].name).length != 0);
        var _events = publishEvents[_address];
        require(_eventId < publishEvents[_address].length);
        require(bytes(_events[_eventId].name).length != 0);
        _;
    }

    modifier ticketExists(address _address, uint _eventId, uint _ticketId) {
        require(bytes(users[_address].name).length != 0);
        var _events = publishEvents[_address];
        require(_eventId < _events.length);
        require(bytes(_events[_eventId].name).length != 0);
        var _tickets = publishEventTickets[_address][_eventId];
        require(_ticketId < _tickets.length);
        require(_tickets[_ticketId].owner != address(0));
        _;
    }
    
    function getRandomCode() private returns (uint32){ 
        return uint32(getRandom() % 4294967291);
    }

    function ETicketToken() {
        totalSupply = 6000000000000000;
        balances[msg.sender] = totalSupply;
        name = "ETicketToken";
        decimals = 18;
        symbol = "ETT";
    }



    // user ref operation
    function getUserRefsMaxId() 
    returns (uint) {
        return userRefs.length - 1;
    }

    function getUserRef(uint _userRefId) 
    userRefExists(_userRefId) 
    returns (address) {
        var _user = userRefs[_userRefId].user;
        return _user;        
    }
    
    

    // event ref operation
    function getEventRefsMaxId() 
    returns (uint) {
        return eventRefs.length - 1;
    }

    function getEventRef(uint _eventRefId) 
    eventRefExists(_eventRefId) 
    returns (address, uint) {
        var eventRef = eventRefs[_eventRefId];
        var _publisher = eventRef.publisher;
        var _eventId = eventRef.eventId;
        return (_publisher, _eventId);        
    }



    // user ticket ref operation
    function getUserTicketRefsMaxId()
    returns (uint) {
        return userTicketRefs[msg.sender].length - 1;
    }

    function getUserTicketRef(uint _userTicketRefId) 
    userTicketRefExists(msg.sender, _userTicketRefId) 
    returns (address, uint, uint) {
        var userTicketRef =  userTicketRefs[msg.sender][_userTicketRefId];
        var _publisher = userTicketRef.publisher;
        var _eventId = userTicketRef.eventId;
        var _ticketId = userTicketRef.eventId;
        return (_publisher, _eventId, _ticketId);        
    }



    // user operation
    function getUser(address _address) 
    userExists(_address) 
    returns (string, string, string, uint64) {
        return (users[_address].userNumber, users[_address].name, users[_address].attributes, users[_address].version);
    }

    function createUser(string _name, string _attributes) 
    userNotExists(msg.sender)  {
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("email");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("profile");
        require(_found && !_isNull && _value.length != 0);
        users[msg.sender] = user({
            userNumber: Convert.bytes32ToHexString(sha3(msg.sender)),
            name: _name,
            attributes: _attributes,
            version:  0
        });
        // create user ref
        userRefs.push(userRef({
            user: msg.sender
        }));
    }

    function modifyUser(string _name, string _attributes) 
    userExists(msg.sender)  {
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("email");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("profile");
        require(_found && !_isNull && _value.length != 0);
        var _user = users[msg.sender];
        _user.name = _name;
        _user.attributes = _attributes;
        _user.version++;
    }



    // publish event operation
    function getPublishEventsMaxId(address _address, uint _eventId) 
    userExists(_address)
    returns (uint) {
        return publishEvents[_address].length - 1;
    }

    function getPublishEvent(address _address, uint _eventId) 
    eventExists(_address, _eventId) 
    returns (string, string, uint32, uint8, uint, uint64) {
        var _event = publishEvents[_address][_eventId];
        return (_event.name, _event.attributes, _event.maxPrice, _event.status, _event.groupCount, _event.version);
    }

    function createPublishEvent(string _name, string _attributes, uint32 _maxPrice) 
    userExists(msg.sender) 
    returns (uint){
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("description");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("country");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findArrayString("tags", 0);
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("startDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("endDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("place");
        require(_found && !_isNull && _value.length != 0);
        // create publish event
        var events = publishEvents[msg.sender];
        var _eventId = events.length;
        events.push(publishEvent ({
            name: _name,
            attributes: _attributes,
            cashBackOraclizeUrl: "",
            joinOraclizeUrl: "",
            maxPrice :_maxPrice,
            status: ES_OPENED,
            groupCount: 0,
            version: 0
        }));
        // create event ticket ref
        eventRefs.push(eventRef({
            publisher: msg.sender,
            eventId: _eventId
        }));
        return _eventId;
    }

    function modifyPublishEvent(uint _eventId, string _name, string _attributes, uint32 _maxPrice)
    eventExists(msg.sender, _eventId)  {
        require(bytes(_name).length != 0);
        var finder = ValueFinder.initFinder(_attributes);
        var (_found, _isNull, _value) = finder.findString("description");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("country");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findArrayString("tags", 0);
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("startDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("endDateTime");
        require(_found && !_isNull && _value.length != 0);
        (_found, _isNull, _value) = finder.findString("place");
        require(_found && !_isNull && _value.length != 0);
        var _event = publishEvents[msg.sender][_eventId];
        _event.name = _name;
        _event.attributes = _attributes;
        _event.maxPrice = _maxPrice;
        _event.version++;
    }

    function getOraclizeUrlPublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) 
    returns (string, string) {
        var _event = publishEvents[msg.sender][_eventId];
        return (_event.cashBackOraclizeUrl, _event.joinOraclizeUrl);
    }
    
    function setOraclizeUrlPublishEvent(uint _eventId, string _cashBackOraclizeUrl, string _joinOraclizeUrl)
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        _event.cashBackOraclizeUrl = _cashBackOraclizeUrl;
        _event.joinOraclizeUrl = _joinOraclizeUrl;
    }
    
    function stopPublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        _event.status = ES_STOPPED;
        _event.version++;
        // XXXXXXX
        // XXX haraimodoshi    最初に売った価格を現在の所有者に返却する
        // XXX owner != publisher  ticket -> cancel
    }

    function closePublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        require(_event.status == ES_OPENED);
        _event.status = ES_CLOSED;
        _event.version++;
    }

    function reopenPublishEvent(uint _eventId) 
    eventExists(msg.sender, _eventId) {
        var _event = publishEvents[msg.sender][_eventId];
        require(_event.status == ES_CLOSED);
        _event.status = ES_CLOSED;
        _event.version++;
    }

    // publish event ticket operation
    function getPublishEventTicketsMaxId(address _address, uint _eventId)
    eventExists(_address, _eventId)
    returns (uint) {
        return publishEventTickets[_address][_eventId].length - 1;
    }

    function getPublishEventTicketValidation(address _address, uint _eventId, uint _ticketId) private 
    ticketExists(_address, _eventId, _ticketId)
    returns (bool) {
        return true;
    }

    function getPublishEventTicketLogic(address _address, uint _eventId, uint _ticketId) private
    returns (uint, uint32, uint32, string, uint32, uint8, uint64) {
        require(getPublishEventTicketValidation(_address, _eventId, _ticketId) == true);
        var _ticket = publishEventTickets[_address][_eventId][_ticketId];
        require(_address == msg.sender);
        require(_address == _ticket.owner);
        return (_ticket.groupId, _ticket.price, _ticket.cashBack, _ticket.joinOraclizeResponse, _ticket.joinCode, _ticket.status _ticket.version);
    }
    
    function getPublishEventTicket(address _address, uint _eventId, uint _ticketId) 
    returns (uint, uint32, uint32, string, uint32, uint8, uint64) {
        return getPublishEventTicketLogic(_address, _eventId, _ticketId);
    }

    function getExtraPublishEventTicket(uint _eventId, uint _ticketId) 
    ticketExists(msg.sender, _eventId, _ticketId) 
    returns (int64, address, string, uint64) {
        var _ticket = publishEventTickets[msg.sender][_eventId][_ticketId];
        return (_ticket.firstSoldPrice, _ticket.owner, _ticket.cashBackOraclizeResponse, _ticket.version);
    }

    function createPublishEventTicketGroupLogic(uint _eventId, uint _amount, uint32 _price)  {
        require(_amount != 0);
        var _event = publishEvents[msg.sender][_eventId];
        require(_price <= _event.maxPrice);
        var _tickets = publishEventTickets[msg.sender][_eventId];
        var _groupId = _event.groupCount;
        uint _ticketId;
        var _ticketRefs = userTicketRefs[msg.sender];
        for (uint i = 0; i < _amount; i++) {
            _ticketId = _tickets.length;
            _tickets.push(publishEventTicket({
                groupId: _groupId,
                owner: msg.sender,
                firstSoldPrice: -1,
                price: _price,
                cashBackOraclizeResponse: "",
                cashBack: 0,
                joinOraclizeResponse: "",
                joinCode : 0,
                status: TS_SALE|TS_BUY,
                version: 0
            }));
            // create user ticket ref
            _ticketRefs.push(userTicketRef ({
                publisher: msg.sender,
                eventId: _eventId,
                ticketId: _ticketId
            }));
            _event.groupCount++;
        }
    }

    function createPublishEventTicketGroup(uint _eventId, uint _amount, uint32 _price) 
    eventExists(msg.sender, _eventId) {
        return createPublishEventTicketGroupLogic(_eventId, _amount, _price); 
    }

    function getSummaryPublishEventTickets(uint _eventId)
    eventExists(msg.sender, _eventId) 
    returns (uint _ticketCount, uint _buyCount, uint _joinCount, uint _enterCount, uint _totalSoldPrice, uint32 _minPrice, uint32 _maxPrice) {
        _ticketCount = 0;
        _buyCount = 0;
        _joinCount = 0;
        _enterCount = 0;
        _totalSoldPrice = 0;
        _minPrice = 0xffffffff;
        _maxPrice = 0;
        for (uint i; i < publishEventTickets[msg.sender][_eventId].length; i++) {
            var _ticket = publishEventTickets[msg.sender][_eventId][i];
            if (_ticketCount == 0){
                _minPrice = _ticket.price;
                _maxPrice = _ticket.price;
            } else {
                if (_ticket.price < _minPrice) {
                    _minPrice = _ticket.price;
                } else if (_ticket.price > _maxPrice) {
                    _maxPrice = _ticket.price;
                }
            }
            if ((_ticket.status & TS_BUY) != 0) {
                _buyCount++;                
            }  else if ((_ticket.status & TS_JOIN) != 0) {
                _joinCount++;                
            }  else if ((_ticket.status & TS_ENTER) != 0) {
                _enterCount++;                
            }
            if (_ticket.firstSoldPrice != -1) {
                _totalSoldPrice += uint(_ticket.firstSoldPrice);
            }
            _ticketCount++;
        }
    }
    
    // ticket operation
    uint8 constant CHECK_OPT_USE_OWNER     = 0x01;
    uint8 constant CHECK_OPT_USE_GROUP     = 0x02;
    uint8 constant CHECK_OPT_USE_MAX_PRICE = 0x04;

    function checkSaleTicketsLogic(address _publisher, uint _eventId, uint8 _buyOptions, address _owner, uint8 _groupId, uint32 _maxPrice) private
    returns (uint, uint32)
    {
        publishEventTicket[] memory _tickets = publishEventTickets[_publisher][_eventId];
        publishEventTicket memory _ticket;
        uint _saleTicketCount = 0;
        uint i;
        uint32 _minPrice = 0;
        for (i; i < _tickets.length; i++) {
            _ticket =_tickets[i];
            if (_ticket.owner != msg.sender) {
                continue;
            }
            if ((_ticket.status & (TS_SALE|TS_BUY)) == (TS_SALE|TS_BUY)) {
                continue;
            }
            if ((_buyOptions & CHECK_OPT_USE_OWNER) != 0 && _ticket.owner != _owner) {
                continue;
            }
            if ((_buyOptions & CHECK_OPT_USE_GROUP) != 0 && _ticket.groupId != _groupId) {
                continue;
            }
            if ((_buyOptions & CHECK_OPT_USE_MAX_PRICE) != 0 && _ticket.price > _maxPrice) {
                continue;
            }
            if (_saleTicketCount == 0) {
                _minPrice = _ticket.price;
            } else {
                if (_ticket.price < _minPrice) {
                    _minPrice = _ticket.price;
                }
            }
            _saleTicketCount++; 
        }    
        return (_saleTicketCount, _minPrice);
    }
    
    function checkSaleTickets(address _publisher, uint _eventId, uint8 _buyOptions, address _owner, uint8 _groupId, uint32 _maxPrice)
    eventExists(_publisher, _eventId) 
    returns (uint, uint32) {
        return checkSaleTicketsLogic(_publisher, _eventId, _buyOptions, _owner, _groupId, _maxPrice);
    }
 
    uint8 constant BUY_OPT_USE_OWNER     = 0x01;
    uint8 constant BUY_OPT_USE_GROUP     = 0x02;
    uint8 constant BUY_OPT_USE_MAX_PRICE = 0x04;
    uint8 constant BUY_OPT_CONTINUOUS    = 0x08;
    
    uint8 constant BUY_RESPNSE_OK               = 1;
    uint8 constant BUY_RESPNSE_NOT_ENOUGH_TOKEN = 2;
    uint8 constant BUY_RESPNSE_NO_TICKET        = 3;
    
    function buyTicketsLogic(address _publisher, uint _eventId, uint _amount, uint8 _buyOptions, address _ticketOwner, uint8 _groupId, uint32 _maxPrice) private
    returns (uint8) {
        publishEventTicket[] memory _tickets = publishEventTickets[_publisher][_eventId];
        publishEventTicket memory  _ticket;
        uint _i;
        uint[] memory _candidateTickets = new uint[](_amount);
        uint _candidateTicketsIndex = 0;
        uint _totalNeedPrice = 0;
        for (_i; _i < _tickets.length; _i++) {
            _ticket = _tickets[_i];
            if (_ticket.owner != msg.sender) {
                continue;
            }
            if ((_ticket.status & (TS_SALE|TS_BUY)) == (TS_SALE|TS_BUY)) {
                continue;
            }
            if ((_buyOptions & BUY_OPT_USE_OWNER) != 0 && _ticket.owner != _ticketOwner) {
                continue;
            }
            if ((_buyOptions & BUY_OPT_USE_GROUP) != 0 && _ticket.groupId != _groupId) {
                continue;
            }
            if ((_buyOptions & BUY_OPT_USE_MAX_PRICE) != 0 && _ticket.price > _maxPrice) {
                continue;
            }
            if (_candidateTicketsIndex > 0 && (_buyOptions & BUY_OPT_CONTINUOUS) != 0 && _candidateTickets[_candidateTicketsIndex - 1] + 1 != _i) {
                _candidateTicketsIndex = 0;
                _totalNeedPrice = 0;
                continue;
            }
            _candidateTickets[_candidateTicketsIndex] = _i;
            _candidateTicketsIndex++;
            _totalNeedPrice += _tickets[_i].price;
            if (_candidateTicketsIndex == _amount) {
                break;
            }
        }
        if (balances[msg.sender] < _totalNeedPrice) {
            return BUY_RESPNSE_NOT_ENOUGH_TOKEN;            
        }
        if (_candidateTicketsIndex != _amount) {
            return BUY_RESPNSE_NO_TICKET;
        }
        for (_i = 0; _i < _candidateTicketsIndex; _i++) {
            _ticket = _tickets[_i];    
            balances[msg.sender] -= uint256(_ticket.price);        
            balances[_ticket.owner] += uint256(_ticket.price);
            if (_ticket.firstSoldPrice == -1) {
               _ticket.firstSoldPrice = int64(_ticket.price);
            }
            _ticket.status &= ~TS_SALE;
            _ticket.owner = msg.sender;
            _ticket.version++;
        }
        return BUY_RESPNSE_OK;
    }
    
    function buyTickets(address _publisher, uint _eventId, uint _amount, uint8 _buyOptions, address _ticketOwner, uint8 _groupId, uint32 _maxPrice)
    eventExists(_publisher, _eventId) 
    returns (uint8) {
        return buyTicketsLogic(_publisher, _eventId, _amount, _buyOptions, _ticketOwner, _groupId, _maxPrice);
    }

    function changePriceTicket(address _publisher, uint _eventId, uint _ticketId, uint32 _price) 
    ticketExists(_publisher, _eventId, _ticketId) {
        var _event = publishEvents[_publisher][_eventId];
        var _ticket = publishEventTickets[_publisher][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == msg.sender);
        require((_ticket.status & TS_BUY) != 0);
        _ticket.price = _price;
        _ticket.version++;
    }

    function sellTicket(address _publisher, uint _eventId, uint _ticketId) 
    ticketExists(_publisher, _eventId, _ticketId) {
        var _event = publishEvents[_publisher][_eventId];
        var _ticket = publishEventTickets[_publisher][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == msg.sender);
        require((_ticket.status & TS_BUY) != 0);
        _ticket.status |= TS_SALE;
        _ticket.version++;
    }  

    function cancelTicket(address _publisher, uint _eventId, uint _ticketId) 
    ticketExists(_publisher, _eventId, _ticketId) {
        var _event = publishEvents[_publisher][_eventId];
        var _ticket = publishEventTickets[_publisher][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == msg.sender);
        require((_ticket.status & TS_BUY) != 0);
        require(balances[_publisher] > uint(_ticket.firstSoldPrice));
        balances[msg.sender] += uint256(_ticket.firstSoldPrice);        
        balances[_publisher] -= uint256(_ticket.firstSoldPrice);        
        _ticket.price = uint32(_ticket.firstSoldPrice);
        _ticket.status |= TS_SALE;
        _ticket.owner = _publisher;
        _ticket.version++;
    }

    function transferTicket(address _publisher, uint _eventId, uint _ticketId, address _to)
    ticketExists(_publisher, _eventId, _ticketId) {
        var _event = publishEvents[_publisher][_eventId];
        var _ticket = publishEventTickets[_publisher][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == msg.sender);
        require((_ticket.status & TS_BUY) != 0);
        _ticket.status &= ~TS_SALE;
        _ticket.owner = _to;
        _ticket.version++;
    }

    function joinEvent(address _publisher, uint _eventId, uint _ticketId) 
    ticketExists(_publisher, _eventId, _ticketId) {
        var _event = publishEvents[_publisher][_eventId];
        var _ticket = publishEventTickets[_publisher][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == msg.sender);
        require((_ticket.status & TS_BUY) != 0);
        if (bytes(_event.joinOraclizeUrl).length == 0) {
            _ticket.joinCode = getRandomCode();
            _ticket.status &= ~TS_BUY;
            _ticket.status |= TS_JOIN;
            _ticket.version++;
        } else {
            // XXXX TODO enter oracle
            // update _ticket.joinCode and _ticket.joinOraclizeResponse and _ticket.status snf _ticket version in callback
        }
    }
    
    function enterEvent(address _ticketOwner, uint32 _joinCode, uint _eventId, uint _ticketId) 
    ticketExists(msg.sender, _eventId, _ticketId){
        var _event = publishEvents[msg.sender][_eventId];
        var _ticket = publishEventTickets[msg.sender][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == _ticketOwner);
        require((_ticket.status & TS_JOIN) != 0);
        require(_ticket.joinCode == _joinCode);
        _ticket.status &= ~TS_JOIN;
        _ticket.status |= TS_ENTER;  
        _ticket.version++;
    }
    
    function activateCacheBackCode(address _publisher, uint _eventId, uint _ticketId, string _code) {
        var _event = publishEvents[_publisher][_eventId];
        var _ticket = publishEventTickets[_publisher][_eventId][_ticketId];
        require(_event.status == ES_OPENED);
        require(_ticket.owner == msg.sender);
        require((_ticket.status & (TS_JOIN | TS_ENTER)) != 0);
        require(bytes(_ticket.cashBackOraclizeResponse).length == 0);
        // XXXX TODO activate oracle
        // update _ticket.activateOraclizeResponse and _ticket.version in callback
    }
    
}



