pragma solidity ^0.4.11;

contract  Random {
    uint randNonce;
    
    function getRandom() internal returns (uint) {
        randNonce++;
        return uint(sha3(block.timestamp, 
                         block.number, 
                         block.difficulty,
                         msg.gas,
                         msg.sender)) *
               uint(sha3(randNonce));
    }
}

