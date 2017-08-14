pragma solidity ^0.4.14;

import "./Converter.sol";

contract ConverterTest {
    function test0() returns (string, bytes32, string){
        var _os = "";
        var _b = Converter.stringToBytes32(_os);
        var _s = Converter.bytes32ToString(_b);
        return (_os, _b, _s);
    }
    
    function test1() returns (string, bytes32, string){
        var _os = "hello world";
        var _b = Converter.stringToBytes32(_os);
        var _s = Converter.bytes32ToString(_b);
        return (_os, _b, _s);
    }
    
    function test2() returns (string, bytes32, string){
        var _os = "ｇじょえりｇじぇりお";
        var _b = Converter.stringToBytes32(_os);
        var _s = Converter.bytes32ToString(_b);
        return (_os, _b, _s);
    }
    
    function test3() returns (string, bytes32){
        var _os = "avｇじょえりｇじぇりお";
        var _b = Converter.stringToBytes32(_os);
        return (_os, _b);
    }

    function test4() returns (bytes32, string){
        bytes32 _ob = 0x6176efbd87e38198e38287e38188e3828aefbd87e38198e38187e3828ae3818a;
        var _s = Converter.bytes32ToString(_ob);
        return (_ob, _s);
    }
}
