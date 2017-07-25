pragma solidity ^0.4.11;


/*
 * [ format ]
 *
 * header
 * length(32byte)
 *
 * body
 *           1byte    2byte           .....
 * uint8     1     keyLength(2byte) key(string) value(1byte)
 * uint16    2     keyLength(2byte) key(string) value(2byte)
 * uint32    4     keyLength(2byte) key(string) value(4byte)
 * uint64    8     keyLength(2byte) key(string) value(8byte)
 * uint128   16    keyLength(2byte) key(string) value(16yte)
 * uint256   32    keyLength(2byte) key(string) value(32byte)
 *
 * int8      71    keyLength(2byte) key(string) value(1byte)
 * int16     72    keyLength(2byte) key(string) value(2byte)
 * int32     74    keyLength(2byte) key(string) value(4byte)
 * int64     78    keyLength(2byte) key(string) value(8byte)
 * int128    86    keyLength(2byte) key(string) value(16byte)
 * int256    102   keyLength(2byte) key(string) value(32byte)
 *
 * bytes1    141   keyLength(2byte) key(string) value(1byte)
 * bytes2    142   keyLength(2byte) key(string) value(2byte)
 * bytes4    144   keyLength(2byte) key(string) value(4byte)
 * bytes8    148   keyLength(2byte) key(string) value(8byte)
 * bytes16   156   keyLength(2byte) key(string) value(16byte)
 * bytes32   172   keyLength(2byte) key(string) value(32byte)
 *
 * bytes     180   keyLength(2byte) key(string) valueLenSize(1byte) valueLength(2byte) value(bytes)
 * string    181   keyLength(2byte) key(string) valueLenSize(1byte) valueLength(2byte) value(string)
 *
 * end       255
 *
 */
library KeyValueSerializer {

    struct serial {
        bytes   data;
        uint    offset;
        bool    writable;
    }

    function initialize() internal returns (serial s) {
        s.offset = 0;
        s.writable = true;
    }

    function finalize(serial s) internal {
        require(s.writable);
        s.data[s.offset] = 190;
        s.writable = false;
    }




    function saveKeySize(serial s, uint16 size) private {
        bytes2 bSize = bytes2(size);
        for (uint8 i = 0; i < 2; i++) {
            s.data[s.offset + i] = bSize[i];
        }
        s.offset += 2;
    }

    function saveKey(serial s, bytes bKey, uint16 len) private {
        for (uint16 i = 0; i < len; i++) {
            s.data[s.offset + i] = bKey[i];
        }
        s.offset += len;
    }

    function addKey(serial s, string key) private {
        bytes memory bKey = bytes(key);
        saveKeySize(s, uint16(bKey.length));
        saveKey(s, bKey,  uint16(bKey.length));
    }


    function addUint8(serial s, string key, uint8 v) internal {
        require(s.writable && bytes(key).length < 65536);
        s.data[s.offset] = 1;
        s.offset++;
        addKey(s, key);
        s.data[s.offset] = byte(v);
        s.offset++;
    }

    function toBytes(serial s) internal returns (bytes d) {
        d = s.data;
    }








    function wrap(bytes d) internal returns (serial s) {
        s.data = d;
        s.offset = 0;
        s.writable = false;
    }

    function loadKeySize(serial s) internal returns (uint16 size) {
        for (uint8 i = 0; i < 2; i++) {
            size += uint8(s.data[s.offset + i]);
            if (i != 2) {
                size <<= 8;
            }
        }
        s.offset += 2;
    }


    function equalsKey(serial s, bytes bKeyA) private returns (bool equal) {
        uint16 keySize = loadKeySize(s);
        if (uint16(bKeyA.length) != keySize) {
            equal = false;
            s.offset += keySize;
            return;
        }
        for (uint16 i = 0; i < keySize; i++) {
            if (bKeyA[i] != s.data[s.offset + i]) {
                equal = false;
                s.offset += keySize;
                return;
            }
        }
        equal = true;
        s.offset += keySize;
        return;
    }


    function getUint8(serial s, string key) internal returns (uint8 v, bool found) {
        require(!s.writable && bytes(key).length < 65536);
        while(true) {
            byte t = s.data[s.offset];
            s.offset = 1;
            if (t == 1) {
                if (equalsKey(s, bytes(key)) == false) {
                       s.offset += 1;
                       continue;
                }
                v = uint8(s.data[s.offset]);
                found = true;
                return;
            } else if (t == 255) {
                v = 0;
                found = false;
                return;
            }
        }
    }

}