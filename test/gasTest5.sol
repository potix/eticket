pragma solidity ^0.4.11;

contract gasTestStack {

    function args(
        int _a1,
        int _a2,
        int _a3,
        int _a4,
        int _a5,
        int _a6,
        int _a7,
        int _a8,
        int _a9,
        int _a10,
        int _a11,
        int _a12,
        int _a13,
        int _a14,
        int _a15,
        int _a16,
        int _a17) {
        // error
    }

    function vars() {
        int _a1;
        int _a2;
        int _a3;
        int _a4;
        int _a5;
        int _a6;
        int _a7;
        int _a8;
        int _a9;
        int _a10;
        int _a11;
        int _a12;
        int _a13;
        int _a14;
        int _a15;
        int _a16;
        int _a17; 
        // error
    }
    
    function rets() returns(
        int _a1,
        int _a2,
        int _a3,
        int _a4,
        int _a5,
        int _a6,
        int _a7,
        int _a8,
        int _a9,
        int _a10,
        int _a11,
        int _a12,
        int _a13,
        int _a14,
        int _a15,
        int _a16,
        int _a17) {
        // error
    }

    
    function argsRets(
        int _a1,
        int _a2,
        int _a3,
        int _a4,
        int _a5,
        int _a6,
        int _a7,
        int _a8
        ) returns(
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int) {
            var i = 1;
            // error
    }

    modifier m1(int _ma1) {
        int _l = 0;
        _;
    }
    
    function mod1(
        int _a1,
        int _a2,
        int _a3,
        int _a4,
        int _a5,
        int _a6,
        int _a7,
        int _a8
        ) m1(_a1) returns(
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int) {
            // OK
    }

    modifier m2(int _ma1) {
        int _v = 1;
        _;
    }

    function mod2(
        int _a1,
        int _a2,
        int _a3,
        int _a4,
        int _a5,
        int _a6,
        int _a7,
        int _a8
        ) m1(_a1) m2(_a2) returns(
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int) {
            // error
    }
    
    modifier m3(int _ma1) {
        int _i = 1;
        int _j = 1;
        _;
    }
    
    function mod3(
        int _a1,
        int _a2,
        int _a3,
        int _a4,
        int _a5,
        int _a6,
        int _a7,
        int _a8
        ) m3(_a1) returns(
        int,
        int,
        int,
        int,
        int,
        int,
        int,
        int) {
            // ok
    }
    
}
