pragma solidity ^0.4.14;

import "./Random.sol";

contract RandomTest {
    function test1() returns (uint) {
        return Random.getRandom() % 20;
    }
    
    function test2() returns (uint) {
        return Random.getRandom() % 20;
    }
}
