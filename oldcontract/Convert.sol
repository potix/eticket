pragma solidity ^0.4.11;

library Convert {

	function getHexChar(byte _b) private returns (byte) {
		if (_b >= 0 && _b <= 9) {
			return byte(uint8(_b) + uint8(0x30));
		} else {
			return byte(uint8(_b) + uint8(0x37));
		}
	}

	function bytes32ToHexString(bytes32 _b) internal returns (string) {
		bytes memory _bs = new bytes(64);
		for (uint i; i < 32; i++) {
		    var c = _b[i];
			_bs[i * 2] = getHexChar((c & 0xf0) >> 4);
			_bs[(i * 2) + 1] = getHexChar(c & 0x0f); 
		}
		return string(_bs);
	}
}

