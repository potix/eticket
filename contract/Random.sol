pragma solidity ^0.4.11;

contract Random {
    uint randNonce;
    
    function getRandom() returns (uint) {
        randNonce++;
        return (uint(sha3(uint(block.timestamp) 
            + uint(block.number) 
            + uint(block.difficulty)
            + uint(msg.gas)
            + uint(msg.sender)))
            * uint(sha3(randNonce)));
    }
}

