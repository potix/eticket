pragma solidity ^0.4.14;

import "./Random.sol";

contract RandomTest {
    uint nonce;
    
    function test1() returns (uint) {
        nonce++;
        return Random.getRandom(nonce) % 20;
    }
    
    function test2() returns (uint) {
        return Random.getRandom(1) % 20;
    }
}
