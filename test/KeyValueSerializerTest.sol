pragma solidity ^0.4.11;

import "./KeyValueSerializer.sol";

contract KeyValueSerializerTest {
    using KeyValueSerializer for KeyValueSerializer.serial;

    function KeyValueSerializerTest() {
        KeyValueSerializer.serial memory s = KeyValueSerializer.initialize();
        s.addUint8("hoge", 1);
        s.addUint8("fuga", 2);
        s.addUint8("var", 2);
        s.finalize;
        bytes memory data = s.toBytes();
        s = KeyValueSerializer.wrap(data);
        uint8 v;
        bool found;
        (v, found) = s.getUint8("fuga");
    }
}
