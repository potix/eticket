pragma solidity ^0.4.14;

library Random {
    function getRandom() internal returns (uint) {
        return uint(sha3(
              block.blockhash(block.number - 1),
              block.timestamp,
              block.number,
              msg.sender,
              msg.sig));
    }
}

