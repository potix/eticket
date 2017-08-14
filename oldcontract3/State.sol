pragma solidity ^0.4.14;

library State {
    function includesState(uint32 _state, uint32 _value) internal constant returns (bool) {
        return ((_state & _value) != 0);
    }
    
    function equalsState(uint32 _state, uint32 _value) internal constant returns (bool) {
        return ((_state & _value) == _value);
    }

    function setState(uint32 _state, uint32 _value) internal constant returns (uint32) {
        return _state | _value;
    }
    
    function deleteState(uint32 _state, uint32 _value) internal constant returns (uint32) {
        return _state & ~_value;
    }   
    
    function changeState(uint32 _state, uint32 _before, uint32 _after) internal constant returns (uint32) {
        return (_state & ~_before) | _after;
    }
}


