pragma solidity ^0.4.14;

contract DB {
    // 発行したidを格納する領域        
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
    }
    
    function newObject(DB db) internal returns (object obj) {
        var objectId = db.getAndIncrementId(sha3("objectId"));
        obj.id = objectId;
        return obj;
    }

    function loadObject(DB db, uint256 objectId) internal returns (object obj) {
        obj.id = objectId;
        obj.value1 = db.getValue(sha3("/objects", objectId, "value1"));
        obj.value2 = db.getValue(sha3("/objects", objectId, "value2"));
        obj.value3 = db.getValue(sha3("/objects", objectId, "value3"));
        obj.value4 = db.getValue(sha3("/objects", objectId, "value4"));
        obj.value5 = db.getValue(sha3("/objects", objectId, "value5"));
        return obj;
    }

    function saveObject(DB db, object obj) internal returns (bool) {
        db.setValue(sha3("/objects", obj.id, "value1"), obj.value1);
        db.setValue(sha3("/objects", obj.id, "value1"), obj.value1);
        db.setValue(sha3("/objects", obj.id, "value2"), obj.value2);
        db.setValue(sha3("/objects", obj.id, "value3"), obj.value3);
        db.setValue(sha3("/objects", obj.id, "value4"), obj.value4);
        db.setValue(sha3("/objects", obj.id, "value5"), obj.value5);
        return true;
    }
    
    function initObject(object obj, uint256 value1, uint256 value2, uint256 value3, uint256 value4, uint256 value5) internal {
        obj.value1 = value1;
        obj.value2 = value2;
        obj.value3 = value3;
        obj.value4 = value4;
        obj.value5 = value5;
    } 

    function multiple(object obj, uint256 value) internal {
        obj.value1 = obj.value1 * value;
        obj.value2 = obj.value2 * value;
        obj.value3 = obj.value3 * value;
        obj.value4 = obj.value4 * value;
        obj.value5 = obj.value5 * value;
    }

    function sum(object obj) internal returns (uint256) {
        return (obj.value1 + obj.value2 + obj.value3 + obj.value4 + obj.value5);
    }
}

contract test {
    using Object for Object.object;
    DB db;

    function test() {
        db = new DB();
    }   
    
    function create(uint256 value1, uint256 value2, uint256 value3, uint256 value4, uint256 value5) returns (uint256){
        var obj = Object.newObject(db);
        obj.initObject(value1, value2, value3, value4, value5);
        Object.saveObject(db, obj);
        return obj.id;
    }
    
    function read(uint256 objectId) returns (uint256) {
        var object = Object.loadObject(db, objectId);
        return object.sum();
    }

    function write(uint256 objectId) returns (uint256) {
        var obj = Object.loadObject(db, objectId);
        obj.multiple(2);
        Object.saveObject(db, obj);
        return obj.id;
    }
}
