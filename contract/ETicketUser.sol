pragma solidity ^0.4.14;

import "./Validation.sol";
import "./ETicketDB.sol";

library ETicketUser {
    // [user] 
    // userId
    // users <userId> address
    // users <userId> name
    // users <userId> email
    // users <userId> profile
    // users <userId> eventUpdateTime
    // users <userId> transactionUpdateTime
    // users <userId> ticketContextUpdateTime
    // idMap <address> <userId>

    struct user {
        ETicketDB db;
        // members
        uint256 userId;
        address userAddress;
        string  name;
        string  email;
        string  profile;
        uint256 eventUpdateTime;
        uint256 transactionUpdateTime;
        uint256 ticketContextUpdateTime;
        // shadow values
        address __userAddress;
        uint256 __eventUpdateTime;
        uint256 __transactionUpdateTime;
        uint256 __ticketContextUpdateTime;
    }

    function _newId(ETicketDB _db) private returns (uint256) {
        return ETicketDB(_db).getAndIncrementId(sha3("userId"));   
    }

    function _load(ETicketDB _db, uint256 _userId) private returns (user _user) {
        _user.db = _db;
        _user.userId = _userId;
        _user.userAddress = ETicketDB(_db).getAddress(sha3("users", _userId, "address")); 
        // not supported string
        //_user.name = ETicketDB(_db).getString(sha3("users", _userId, "name")); 
        //_user.email = ETicketDB(_db).getString(sha3("users", _userId, "email")); 
        //_user.profile = ETicketDB(_db).getString(sha3("users", _userId, "profile")); 
        _user.eventUpdateTime = ETicketDB(_db).getUint256(sha3("users", _userId, "eventUpdateTime")); 
        _user.transactionUpdateTime = ETicketDB(_db).getUint256(sha3("users", _userId, "transactionUpdateTime")); 
        _user.ticketContextUpdateTime = ETicketDB(_db).getUint256(sha3("users", _userId, "ticketContextUpdateTime")); 
        // set shadow values
        _user.__userAddress = _user.userAddress;
        _user.__eventUpdateTime = _user.eventUpdateTime;
        _user.__transactionUpdateTime = _user.transactionUpdateTime;
        _user.__ticketContextUpdateTime = _user.ticketContextUpdateTime;
    }

    function _save(user _user) private returns (bool){
        if (_user.userAddress != _user.__userAddress) {
            ETicketDB(_user.db).setAddress(sha3("users", _user.userId, "address"), _user.userAddress);
        }
        if (bytes(_user.name).length != 0) {
            ETicketDB(_user.db).setString(sha3("users", _user.userId, "name"), _user.name);
        }
        if (bytes(_user.email).length != 0) {
            ETicketDB(_user.db).setString(sha3("users", _user.userId, "email"), _user.email);
        }
        if (bytes(_user.profile).length != 0) {
            ETicketDB(_user.db).setString(sha3("users", _user.userId, "profile"), _user.profile);
        }
        if (_user.eventUpdateTime != _user.__eventUpdateTime) {
            ETicketDB(_user.db).setUint256(sha3("users", _user.userId, "eventUpdateTime"), _user.eventUpdateTime);
        }
        if (_user.transactionUpdateTime != _user.__transactionUpdateTime) {
            ETicketDB(_user.db).setUint256(sha3("users", _user.userId, "transactionUpdateTime"), _user.transactionUpdateTime);
        }
        if (_user.ticketContextUpdateTime != _user.__ticketContextUpdateTime) {
            ETicketDB(_user.db).setUint256(sha3("users", _user.userId, "ticketContextUpdateTime"), _user.ticketContextUpdateTime);
        }
        return true;
    }

    function _new(
        ETicketDB _db, 
        string _name, 
        string _email, 
        string _profile
        ) private returns (user _user) {
        _user.db = _db;
        _user.userId = _newId(_db);
        _user.name = _name;
        _user.email = _email;
        _user.profile = _profile;
        _user.eventUpdateTime = now;
        _user.transactionUpdateTime = now;
        _user.ticketContextUpdateTime = now;
        
    }
    
    function getExistsUser(ETicketDB _db, uint256 _userId) internal returns(user) {
        var _user = _load(_db, _userId);
        require(_userId == _user.userId);  
        assert(Validation.validAddress(_user.userAddress));
        return _user;
    }
    
    function getSenderUser(ETicketDB _db) internal returns(user) {
        require(Validation.validAddress(msg.sender));
        var _userId = ETicketDB(_db).getIdMap(msg.sender);
        var _user = _load(_db, _userId);
        require(msg.sender == _user.userAddress);  
        return _user;
    }
    
    function update(user _user) internal returns(bool) {
        return _save(_user);
    }
    
    function createUser(
        ETicketDB _db, 
        string _name, 
        string _email, 
        string _profile
        ) internal returns (user) {
        require(Validation.validAddress(msg.sender));
        require(Validation.validStringLength(_name, 1, 100));        
        require(Validation.validStringLength(_email, 0, 100));        
        require(Validation.validStringLength(_profile, 0, 1000));  
        var _user = _new(_db, _name, _email, _profile);
        _save(_user);
        ETicketDB(_db).setIdMap(msg.sender, _user.userId);
        return _user;        
    }

    function setUserName(ETicketDB _db, string _name) internal returns (bool) {
        require(Validation.validStringLength(_name, 1, 100)); 
        var _user = getSenderUser(_db);
        _user.name = _name;
        return _save(_user);
    }

    function setUserEmail(ETicketDB _db, string _email) internal returns (bool) {
        require(Validation.validStringLength(_email, 0, 100));        
        var _user = getSenderUser(_db);
        _user.email = _email;
        return _save(_user);
    }

    function setUserProfile(ETicketDB _db, string _profile) internal returns (bool) {
        require(Validation.validStringLength(_profile, 0, 1000));        
        var _user = getSenderUser(_db);
        _user.profile = _profile;
        return _save(_user);
    }
}

