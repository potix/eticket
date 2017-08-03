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

contract getTestStatuctMapping {
    struct value {
        string value1;
        string value2;
        string value3;
    }
    value sv;
    mapping (string => string) mv;

    function setStruct(string _value1, string _value2, string _value3) {
        sv.value1 = _value1; 
        sv.value2 = _value2; 
        sv.value3 = _value3; 
    }

    function getStruct() returns (string _value1, string _value2, string _value3) {
        return (sv.value1, sv.value2 = _value2, sv.value3); 
    }

    function setMapping(string _value1, string _value2, string _value3) {
        mv["value1"] = _value1;  
        mv["value2"] = _value2;  
        mv["value3"] = _value3;  
    }

    function getMapping() returns (string _value1, string _value2, string _value3) {
        return (mv["value1"], mv["value2"], mv["value2"]);
    }
    
}

// input "aaa", "bbb", "ccc"
// setStruct
//    Transaction cost: 85291 gas. 
//    Execution cost: 61907 gas.
// setMapping
//    Transaction cost: 85628 gas. 
//    Execution cost: 62244 gas.
// getStruct
//    Transaction cost: 29070 gas. 
//    Execution cost: 7798 gas.
// getMapping
//    Transaction cost: 24331 gas. 
//    Execution cost: 3059 gas.




