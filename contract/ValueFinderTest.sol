pragma solidity ^0.4.11;

import "./ValueFinder.sol";

contract ValueFinderTest {
     using ValueFinder for ValueFinder.finder;

    string constant jsonSubset = '{  "aaa" : "bbb" ,"a.b":"ttt", \n \t \r  "null": null, "pppl" : "\u3057\u306d" ,"b.h"  :  -4  ,  "ggg":6778, "rr":false,   "uu"  :  true}';
    
    function getString1() returns (bool _found, bool _isNULL, string _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findString("aaa");
    }   
    
    function getString2() returns (bool _found, bool _isNULL, string _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findString("a.b");
    }   
    
    function getString3() returns (bool _found, bool _isNULL, string _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findString("pppl");
    } 

    function getString4() returns (bool _found, bool _isNULL, string _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findString("null");
    }   

    function getString5() returns (bool _found, bool _isNULL, string _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findString("b.h");
    }   

    function getString6() returns (bool _found, bool _isNULL, string _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findString("xxxx");
    }   

    function getInt1() returns (bool _found, bool _isNULL, int _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findInt("b.h");
    }   

    function getInt2() returns (bool _found, bool _isNULL, int _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findInt("ggg");
    }   
    
    function getInt3() returns (bool _found, bool _isNULL, int _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findInt("null");
    }   

    function getInt4() returns (bool _found, bool _isNULL, int _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findInt("");
    }   

    function getInt5() returns (bool _found, bool _isNULL, int _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findInt("XXXX");
    }   
    
    function getBool1() returns (bool _found, bool _isNULL, bool _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findBool("rr");
    }   

    function getBool2() returns (bool _found, bool _isNULL, bool _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findBool("uu");
    }   

    function getBool3() returns (bool _found, bool _isNULL, bool _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findBool("null");
    }   

    function getBool4() returns (bool _found, bool _isNULL, bool _value) {
         var finder = ValueFinder.initFinder(jsonSubset);
       (_found, _isNULL, _value) = finder.findBool("a.b");
    }   
    
    function getBool5() returns (bool _found, bool _isNULL, bool _value) {
        var finder = ValueFinder.initFinder(jsonSubset);
        (_found, _isNULL, _value) = finder.findBool("XXX");
    }  
}
