pragma solidity ^0.4.11;

contract Random {
    uint256 randomNonce;

    function getRandom(address _appDB) internal returns (uint) {
        randomNonce++;
        return uint(sha3(block.timestamp, 
                         block.number, 
                         block.difficulty,
                         msg.gas,
                         msg.sender)) * uint(sha3(randomNonce));
    }
}
