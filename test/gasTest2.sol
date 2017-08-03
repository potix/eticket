pragma solidity ^0.4.11;

contract gasTestMultistorage {
    string value1;
    string value2;
    string value3;
    
    function setString(string _value1, string _value2, string _value3){
        value1 = _value1;
        value2 = _value2;
        value3 = _value3;
    }
    
    function getString() returns (string, string, string) {
        return (value1, value2, value3);
    }
}

// input "aaa", "bbb", "ccc"
// setString
//   Transaction cost: 85273 gas. 
//   Execution cost: 61889 gas.
// getString
//   Transaction cost: 23938 gas. 
//   Execution cost: 2666 gas.

contract gasTestStruct1 {
    struct value {
        string value1;
        string value2;
        string value3;
    }
    
    value v;
    
    function setString(string _value1, string _value2, string _value3){
        v = value({
            value1: _value1,
            value2: _value2,
            value3: _value3
        });
    }
    
    function getString() returns (string, string, string) {
        return (v.value1, v.value2, v.value3);
    }
}

// input "aaa", "bbb", "ccc"
// setString
//   Transaction cost: 85405 gas. 
//   Execution cost: 62021 gas.
// getString
//   Transaction cost: 23956 gas. 
//   Execution cost: 2684 gas.

contract gasTestStruct2 {
    struct value {
        string value1;
        string value2;
        string value3;
    }
    
    value v;
    
    function setString(string _value1, string _value2, string _value3){
        v.value1 = _value1;
        v.value2 = _value2;
        v.value3 = _value3;
    }
    
    function getString() returns (string, string, string) {
        return (v.value1, v.value2, v.value3);
    }
}

// input "aaa", "bbb", "ccc"
// setString
//   Transaction cost: 85291 gas. 
//   Execution cost: 61907 gas.
// getString
//   Transaction cost: 23956 gas. 
//   Execution cost: 2684 gas.



