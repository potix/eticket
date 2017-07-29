pragma solidity ^0.4.11;

import "./ValueFinder.sol";

contract ValueFinderTest {
 
    string constant data = '{  "aaa" : "bbb" ,"a.b":"ttt", "null": null, b.h"  :  -4  ,  "ggg":6778, "rr":false,   "uu"  :  true}';
    
    function getString1() returns (bool _found, bool _isNULL, string _value) {
        (_found, _isNULL, _value) = ValueFinder.findString(data, "aaa");
    }   
    
    function getString2() returns (bool _found, bool _isNULL, string _value) {
        (_found, _isNULL, _value) = ValueFinder.findString(data, "a.b");
    }   

    function getString3() returns (bool _found, bool _isNULL, string _value) {
        (_found, _isNULL, _value) = ValueFinder.findString(data, "null");
    }   

    function getString4() returns (bool _found, bool _isNULL, string _value) {
        (_found, _isNULL, _value) = ValueFinder.findString(data, "b.h");
    }   

    function getString5() returns (bool _found, bool _isNULL, string _value) {
        (_found, _isNULL, _value) = ValueFinder.findString(data, "xxxx");
    }   

    function getInt1() returns (bool _found, bool _isNULL, int _value) {
        (_found, _isNULL, _value) = ValueFinder.findInt(data, "b.h");
    }   

    function getInt2() returns (bool _found, bool _isNULL, int _value) {
        (_found, _isNULL, _value) = ValueFinder.findInt(data, "ggg");
    }   

    function getBool1() returns (bool _found, bool _isNULL, bool _value) {
        (_found, _isNULL, _value) = ValueFinder.findBool(data, "rr");
    }   

    function getBool2() returns (bool _found, bool _isNULL, bool _value) {
        (_found, _isNULL, _value) = ValueFinder.findBool(data, "uu");
    }   

    function getBool3() returns (bool _found, bool _isNULL, bool _value) {
        (_found, _isNULL, _value) = ValueFinder.findBool(data, "null");
    }   

    function getBool4() returns (bool _found, bool _isNULL, bool _value) {
        (_found, _isNULL, _value) = ValueFinder.findBool(data, "a.b");
    }   
    
    function getBool5() returns (bool _found, bool _isNULL, bool _value) {
        (_found, _isNULL, _value) = ValueFinder.findBool(data, "XXX");
    }  
    

}
