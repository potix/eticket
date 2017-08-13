pragma solidity ^0.4.14;

contract DB {
    mapping(bytes32 => uint256) ids;

    function getAndIncrementId(bytes32 _key) returns (uint256) {
        var _v = ids[_key];
        ids[_key] = _v + 1;
        return _v;
    }

    mapping(bytes32 => uint256) values;

    function getValue(bytes32 key) returns (uint256) {
        return values[key];
    }

    function setValue(bytes32 key, uint256 value) {
        values[key] = value;
    }
}

library Object {
    struct object {
        uint256 id;
        uint256 value1;
    }
    
    function _newId(DB _db) private returns (uint256) {
        return _db.getAndIncrementId(sha3("objectId"));
    }
    
    function _load(DB _db, uint256 _objectId) private returns (object newObject) {
        newObject.id = _objectId;
        newObject.value1 = _db.getValue(sha3("/objects", _objectId, "value1"));
    }
    
    function _save(DB _db, object _object) private returns (bool) {
        _db.setValue(sha3("/objects", _object.id, "value1"), _object.value1);
        return true;
    }

    function createObject(
        DB _db, 
        uint256 _value1
        ) internal returns (object newObject) {
        newObject.id = _newId(_db);
        newObject.value1 = _value1;
        _save(_db, newObject);
    }
    
    function multiple(DB _db, uint256 _objectId, uint256 _multiValue) internal returns (bool) {
        var _object = _load(_db, _objectId);
        _object.value1 *= _multiValue;
        _save(_db, _object);
        return true;
    }

    function sum(DB _db, uint256 _objectId) internal returns (uint256) {
        var _object = _load(_db, _objectId);
        return (_object.value1);
    }
}

contract test {
    DB db;

    function test() {
        db = new DB();
    }   
    
    function create(uint256 _value1) returns (uint256){
        var obj = Object.createObject(db, _value1);
        return obj.id;
    }
    
    function getSum(uint256 _objectId) returns (uint256) {
        return Object.sum(db, _objectId);
    }

    function setMulti(uint256 _objectId, uint256 _multiValue) returns (bool) {
        return Object.multiple(db, _objectId, _multiValue);
    }
}

