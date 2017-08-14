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

    struct userInfo {
        address userAddress;
        uint256 userId;
    }

    function getIdAddrByAddr(ETicketDB _db, address _address) private returns(userInfo _userInfo) {
        _userInfo.userId = ETicketDB(_db).getIdMap(_address);
        _userInfo.userAddress = ETicketDB(_db).getAddress(sha3("users", _userInfo.userId , "address"));
    }

    function getIdAddrById(ETicketDB _db, uint256 _userId) private returns(userInfo _userInfo) {
        _userInfo.userAddress = ETicketDB(_db).getUint32(sha3("users", _userId, "address"));
        _userInfo.userId = ETicketDB(_db).getIdMap(_userInfo.userAddress);
    }
    
    function getSenderUserInfo(ETicketDB _db) internal returns(userInfo _userInfo) {
        require(Validation.validAddress(msg.sender));
        _userInfo = getIdAddrByAddr(_db, msg.sender);
        require(msg.sender == _userInfo.userAddress);  
    }
    
    function getExistsUserInfo(ETicketDB _db, uint256 _userId) internal returns(userInfo _userInfo) {
        _userInfo = getIdAddrById(_db, _userId);
        require(_userId == _userInfo.userId);  
        assert(Validation.validAddress(_userInfo.userAddress));
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
        var _userInfo = getSenderUserInfo(_db);
        require(Validation.validStringLength(_name, 1, 100));        
        ETicketDB(_db).setString(sha3("users", _userInfo.userId, "name"), _name);
        ETicketDB(_db).incrementUint256(sha3("users", _userInfo.userId, "version"));
        return true;
    }

    function setUserEmail(ETicketDB _db, string _email) internal returns (bool) {
        var _userInfo = getSenderUserInfo(_db);
        require(Validation.validStringLength(_email, 0, 100));        
        ETicketDB(_db).setString(sha3("users", _userInfo.userId, "email"), _email);
        ETicketDB(_db).incrementUint256(sha3("users", _userInfo.userId, "version"));
        return true;
    }

    function setUserProfile(ETicketDB _db, string _profile) internal returns (bool) {
        var _userInfo = getSenderUserInfo(_db);
        require(Validation.validStringLength(_profile, 0, 1000));        
        ETicketDB(_db).setString(sha3("users", _userInfo.userId, "profile"), _profile);
        ETicketDB(_db).incrementUint256(sha3("users", _userInfo.userId, "version"));
        return true;
    }
}

