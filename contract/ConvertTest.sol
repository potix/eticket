pragma solidity ^0.4.11;

import './Convert.sol';

library ConvertTest {
	function test1() returns (uint, string) {
		bytes32  b = 255;
		return (uint(b), Convert.bytes32ToHexString(b));
	}

	function test2() returns (uint, string) {
		bytes32  b = 65535;
		return (uint(b), Convert.bytes32ToHexString(b));
	}
	
	function test3() returns (uint, string) {
		bytes32  b = sha3(1);
		return (uint(b), Convert.bytes32ToHexString(b));
	}
}

