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
        uint256 value2;
        uint256 value3;
        uint256 value4;
        uint256 value5;
        uint256 _originValue1;
        uint256 _originValue2;
        uint256 _originValue3;
        uint256 _originValue4;
        uint256 _originValue5;
    }
    
    function _newId(DB _db) private returns (uint256) {
        return _db.getAndIncrementId(sha3("objectId"));
    }
    
    function _load(DB _db, uint256 _objectId) private returns (object newObject) {
        newObject.id = _objectId;
        newObject.value1 = _db.getValue(sha3("/objects", _objectId, "value1"));
        newObject.value2 = _db.getValue(sha3("/objects", _objectId, "value2"));
        newObject.value3 = _db.getValue(sha3("/objects", _objectId, "value3"));
        newObject.value4 = _db.getValue(sha3("/objects", _objectId, "value4"));
        newObject.value5 = _db.getValue(sha3("/objects", _objectId, "value5"));
        newObject._originValue1 = newObject.value1;
        newObject._originValue2 = newObject.value2;
        newObject._originValue3 = newObject.value3;
        newObject._originValue4 = newObject.value4;
        newObject._originValue5 = newObject.value5;
    }
    
    function _save(DB _db, object _object) private returns (bool) {
        if (_object.value1 != _object._originValue1) {
            _db.setValue(sha3("/objects", _object.id, "value1"), _object.value1);
        }
        if (_object.value2 != _object._originValue2) {
            _db.setValue(sha3("/objects", _object.id, "value2"), _object.value2);
        }
        if (_object.value3 != _object._originValue3) {
            _db.setValue(sha3("/objects", _object.id, "value3"), _object.value3);
        }
        if (_object.value4 != _object._originValue4) {
            _db.setValue(sha3("/objects", _object.id, "value4"), _object.value4);
        }
        if (_object.value5 != _object._originValue5) {
            _db.setValue(sha3("/objects", _object.id, "value5"), _object.value5);
        }
        return true;
    }

    function createObject(
        DB _db, 
        uint256 _value1, 
        uint256 _value2, 
        uint256 _value3, 
        uint256 _value4, 
        uint256 _value5
        ) internal returns (object newObject) {
        newObject.id = _newId(_db);
        newObject.value1 = _value1;
        newObject.value2 = _value2;
        newObject.value3 = _value3;
        newObject.value4 = _value4;
        newObject.value5 = _value5;
        _save(_db, newObject);
    }
    
    function multiple(DB _db, uint256 _objectId, uint256 _multiValue) internal returns (bool) {
        var _object = _load(_db, _objectId);
        _object.value1 *= _multiValue;
        //_object.value2 *= _multiValue;
        //_object.value3 *= _multiValue;
        //_object.value4 *= _multiValue;
        //_object.value5 *= _multiValue;
        _save(_db, _object);
        return true;
    }

    function sum(DB _db, uint256 _objectId) internal returns (uint256) {
        var _object = _load(_db, _objectId);
        return (_object.value1 + _object.value2 + _object.value3 + _object.value4 + _object.value5);
    }
}

contract test {
    DB db;

    function test() {
        db = new DB();
    }   
    
    function create(uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4, uint256 _value5) returns (uint256){
        var obj = Object.createObject(db, _value1, _value2, _value3, _value4, _value5);
        return obj.id;
    }
    
    function getSum(uint256 _objectId) returns (uint256) {
        return Object.sum(db, _objectId);
    }

    function setMulti(uint256 _objectId, uint256 _multiValue) returns (bool) {
        return Object.multiple(db, _objectId, _multiValue);
    }
}


