pragma solidity ^0.4.14;

import "./Validation.sol";
import "./ETicketDB.sol";

library ETicketUser {
    // [user] 
    // userId
    // users <userId> "address"
    // users <userId> "name"
    // users <userId> "email"
    // users <userId> profile
    // users <userId> version
    // idMap <address> <userId>

    struct user {
        address userAddress;
        uint256 userId;
    }

    function getIdAddrByAddr(ETicketDB _db, address _address) private returns(user _user) {
        _user.userId = ETicketDB(_db).getIdMap(_address);
        _user.userAddress = ETicketDB(_db).getAddress(sha3("users", _user.userId , "address"));
    }

    function getIdAddrById(ETicketDB _db, uint256 _userId) private returns(user _user) {
        _user.userAddress = ETicketDB(_db).getUint32(sha3("users", _userId, "address"));
        _user.userId = ETicketDB(_db).getIdMap(_user.userAddress);
    }
    
    function getSenderUser(ETicketDB _db) internal returns(user _user) {
        require(Validation.validAddress(msg.sender));
        _user = getIdAddrByAddr(_db, msg.sender);
        require(msg.sender == _user.userAddress);  
    }
    
    function getExistsUser(ETicketDB _db, uint256 _userId) internal returns(user _user) {
        _user = getIdAddrById(_db, _userId);
        require(_userId == _user.userId);  
        assert(Validation.validAddress(_user.userAddress));
    }

    function createUser(
        ETicketDB _db, 
        string _name, 
        string _email, 
        string _profile
        ) internal returns (uint256 _userId) {
        require(Validation.validAddress(msg.sender));
        require(Validation.validStringLength(_name, 1, 100));        
        require(Validation.validStringLength(_email, 0, 100));        
        require(Validation.validStringLength(_profile, 0, 1000));        
        _userId = ETicketDB(_db).getAndIncrementId(sha3("userId"));
        ETicketDB(_db).setIdMap(msg.sender, _userId);
        ETicketDB(_db).setAddress(sha3("users", _userId, "address"), msg.sender);
        ETicketDB(_db).setString(sha3("users", _userId, "name"), _name);
        ETicketDB(_db).setString(sha3("users", _userId, "email"), _email);
        ETicketDB(_db).setString(sha3("users", _userId, "profile"), _profile);
        ETicketDB(_db).incrementUint256(sha3("users", _userId, "version"));
        return _userId;
    }

    function setUserName(ETicketDB _db, string _name) internal returns (bool) {
        var _user = getSenderUser(_db);
        require(Validation.validStringLength(_name, 1, 100));        
        ETicketDB(_db).setString(sha3("users", _user.userId, "name"), _name);
        ETicketDB(_db).incrementUint256(sha3("users", _user.userId, "version"));
        return true;
    }

    function setUserEmail(ETicketDB _db, string _email) internal returns (bool) {
        var _user = getSenderUser(_db);
        require(Validation.validStringLength(_email, 0, 100));        
        ETicketDB(_db).setString(sha3("users", _user.userId, "email"), _email);
        ETicketDB(_db).incrementUint256(sha3("users", _user.userId, "version"));
        return true;
    }

    function setUserProfile(ETicketDB _db, string _profile) internal returns (bool) {
        var _user = getSenderUser(_db);
        require(Validation.validStringLength(_profile, 0, 1000));        
        ETicketDB(_db).setString(sha3("users", _user.userId, "profile"), _profile);
        ETicketDB(_db).incrementUint256(sha3("users", _user.userId, "version"));
        return true;
    }
}

