pragma solidity ^0.4.11;

contract gasTestLocation {
 
    byte strg; 
    
    function writeStorage(uint8 _value) {
        strg = byte(_value);
    }

    function writeMem(uint8 _value) {
        bytes memory mmry = new bytes(1);
        mmry[0] = byte(_value);
    }
    
    function writeStack(uint8 _value) {
        byte stck;
        stck = byte(_value);
    }
    
    function ReadStorage() returns (uint8) {
        return uint8(strg);
    }
    
    function writeReadStorage(uint8 _value) returns (uint8) {
        strg = byte(_value);
        return uint8(strg);
    }

    function writeReadMem(uint8 _value) returns (uint8) {
        bytes memory mmry = new bytes(1);
        mmry[0] = byte(_value);
        return uint8(mmry[0]);
    }
    
    function writeReadStack(uint8 _value) returns (uint8) {
        byte stck;
        stck = byte(_value);
        return uint8(stck);
    }
    
}

// input 1
// writeStorage
//    Transaction cost: 41788 gas. 
//    Execution cost: 20324 gas.
// writeMem
//    Transaction cost: 21867 gas. 
//    Execution cost: 403 gas.
// writeStack
//    Transaction cost: 21657 gas. 
//    Execution cost: 193 gas.
// readStorage
//    Transaction cost: 21685 gas. 
//    Execution cost: 413 gas.
// writeReadStorage
//    Transaction cost: 42008 gas. 
//    Execution cost: 20544 gas.
// writeReadMem
//    Transaction cost: 22090 gas. 
//    Execution cost: 626 gas.
// writeReadStack
//    Transaction cost: 21767 gas. 
//    Execution cost: 303 gas.
