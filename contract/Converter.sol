pragma solidity ^0.4.14;

library Converter {
	function bytes32ToString(bytes32 _b) internal returns (string) {
		bytes memory _bs = new bytes(32);
		for (uint i = 0; i < 32; i++) {
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



