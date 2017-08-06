pragma solidity ^0.4.14;

library Converter {
	function getHexChar(byte _b) private returns (byte) {
		if (_b >= 0 && _b <= 9) {
			return byte(uint8(_b) + uint8(0x30));
		} else {
			return byte(uint8(_b) + uint8(0x37));
		}
	}

	function bytes32ToHexString(bytes32 _b) internal returns (string) {
		bytes memory _bs = new bytes(64);
		for (uint i = 0; i < 32; i++) {
			var c = _b[i];
			_bs[i * 2] = getHexChar((c & 0xf0) >> 4);
			_bs[(i * 2) + 1] = getHexChar(c & 0x0f); 
		}
		return string(_bs);
	}

	function bytes32ToString(bytes32 _b) internal returns (string) {
		bytes memory _bs = new bytes(32);
		uint i;
		for (i = 0; i < 32; i++) {
			var c = _b[i];
			if (c == 0) {
				delete _bs[i];
				break;
			}
			_bs[i] = c;
		}
		return string(_bs);
	}

	function stringToBytes32(string _s) internal returns (bytes32) {
		var _bs = bytes(_s);
		uint _v = 0;
		for (uint i = 0; i < 32; i++) {
			_v = _v << 8;
			if (i < _bs.length) {
				_v = _v | uint8(_bs[i]);    
			}            
		}
		return bytes32(_v);
	}
}


