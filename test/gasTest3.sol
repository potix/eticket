pragma solidity ^0.4.11;

contract gasTestMapping {
    struct value {
        string value1;
        string value2;
        string value3;
    }
    
    mapping(address => value) values;

    function setString1(string _value1, string _value2, string _value3){
        values[msg.sender].value1 = _value1;
        values[msg.sender].value2 = _value2;
        values[msg.sender].value3 = _value3;
    }

    function setString2(string _value1, string _value2, string _value3){
        var v = values[msg.sender];
        v.value1 = _value1;
        v.value2 = _value2;
        v.value3 = _value3;
    }

    function setString3(string _value1, string _value2, string _value3){
        values[msg.sender] = value({
           value1: _value1, 
           value2: _value2, 
           value3: _value3 
        });
    }

    function getString1() returns (string, string, string) {
        return (values[msg.sender].value1,  values[msg.sender].value2, values[msg.sender].value3);
    }

    function getString2() returns (string, string, string) {
        var v = values[msg.sender];
        return (v.value1, v.value2, v.value3);
    }
}

// input "aaa", "bbb", "ccc"
// setString1
//     Transaction cost: 85558 gas. 
//     Execution cost: 62174 gas.
// setString2
//     Transaction cost: 55608 gas. 
//     Execution cost: 32224 gas.
// setString3
//     Transaction cost: 55731 gas. 
//     Execution cost: 32347 gas.
// getString1
//     Transaction cost: 24267 gas. 
//     Execution cost: 2995 gas.
// getString2
//     Transaction cost: 24058 gas. 
//     Execution cost: 2786 gas.

contract gasTestArray1 {
    struct value {
        string value1;
        string value2;
        string value3;
    }
    value[] values;
    uint valuesIndex;

    function setString1(string _value1, string _value2, string _value3){
        values.push(value({
           value1: _value1, 
           value2: _value2, 
           value3: _value3 
        }));
    }

    function setString2(string _value1, string _value2, string _value3){
        values[0] = value({
           value1: _value1, 
           value2: _value2, 
           value3: _value3 
        });
    }

    function setString3(string _value1, string _value2, string _value3){
        values[valuesIndex] = value({
           value1: _value1, 
           value2: _value2, 
           value3: _value3 
        });
        valuesIndex++;
    }
    
    function getString1() returns (string, string, string) {
        return (values[0].value1,  values[0].value2, values[0].value3);
    }

    function getString2() returns (string, string, string) {
        var v = values[0];
        return (v.value1, v.value2, v.value3);
    }
}

// input "aaa", "bbb", "ccc"
// setString1
//    Transaction cost: 105844 gas. 
//    Execution cost: 82460 gas.
// setString2
//    Transaction cost: 55773 gas. 
//    Execution cost: 32389 gas.
// setString3
//    Transaction cost: 75932 gas. 
//    Execution cost: 52548 gas.
// getString1
//    Transaction cost: 24459 gas. 
//    Execution cost: 3187 gas.
// getString2
//    Transaction cost: 24122 gas. 
//    Execution cost: 2850 gas.


