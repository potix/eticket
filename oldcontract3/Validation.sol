pragma solidity ^0.4.14;

library Validation {
    function validAddress(address _address) internal returns (bool) {
        return (_address != 0x0);
    }  
    
    function validStringLength(string _value, uint min, uint max) internal returns (bool) {
        var b = bytes(_value);
        return (b.length >= min && b.length <= max);
    }

    function validUint256Range(uint256 _value, uint min, uint max) internal returns (bool){
        return (_value >= min && _value <= max);
    }
}
