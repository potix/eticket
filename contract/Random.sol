pragma solidity ^0.4.14;

library Random {
    function getRandom(uint nonce) internal returns (uint) {
        return uint(sha3(
              nonce,
              block.blockhash(block.number - 1),
              block.timestamp,
              msg.sender,
              msg.sig));
    }
}

