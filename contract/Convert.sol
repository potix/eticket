pragma solidity ^0.4.11;

Library Convert {

	function getHexChar(byte b) private returns (byte) {
		for (b >= 0 && b <= 9) {
			return b + 0x30;
		} else {
			return b + 0x41;
		}
	}

	function bytes32ToString(bytes32 b) internal returns (string) {
		bytes bs = new bytes(64);
		for (uint i; i < 32; i++) {
			bs[i * 2] = getHexChar((bytes32[i] & 0xf0) >> 4);
			bs[(i * 2) + 1] = getHexChar(bytes32[i] & 0x0f); 
		}
		return string(bs);
	}
}
