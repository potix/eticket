pragma solidity ^0.4.11;

library ValueFinder {

    // value type
    // 0 none
    // 1 string
    // 2 bool
    // 3 int
    // 4 null
    
    // parser state
    //
    // 00000010 0x02 objectStart 
    // 00000100 0x04 keyStart 
    // 00001000 0x08 valueStart
    // 00010000 0x10 keyStringStart
    // 00100000 0x20 valueStringStart
    // 01000000 0x40 nameSepStart
    // 10000000 0x80 valueSepStart
    
    function isKeymatch(string _keyA, bytes _bSrc, uint _bkeyBPos, uint _keyBLen) private returns (bool) {
        bytes memory bkeyA = bytes(_keyA);
        if (bkeyA.length != _keyBLen) {
            return false;
        }
        for (uint i = 0; i < _keyBLen; i++) {
           if (bkeyA[i] != _bSrc[_bkeyBPos + i]) {
               return false;
           } 
        }
        return true;
    }
    
    function findValuePos(string _src, string _findKey) private returns (bool, uint8, uint, uint) {
        bytes memory _bSrc = bytes(_src);
        int16 _state = 0;
        uint _pos = 0;
        uint _keyStartPos = 0;
        uint _keyLen = 0;
        uint _valueStartPos = 0;
        uint _valueLen = 0;
        
        while (true) {
            if (_pos == _bSrc.length) {
                break;
            }
            if ((_state & (0x10 | 0x40)) == 0) {
                // skip white space
                if (_bSrc[_pos] == 0x20 || _bSrc[_pos] == 0x09 || _bSrc[_pos] == 0x0a || _bSrc[_pos] == 0x0d) {
                    _pos++;
                    continue;
                }
            }
            if ((_state & 0x02) == 0) {
                if (_bSrc[_pos] == 0x7b) {
                    // start object
                    _state |= 0x02;
                    _state |= 0x04;
                    _pos++;
                    continue;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x02) != 0) {
                if (_bSrc[_pos] == 0x7d) {
                    // end object
                    break;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x04) != 0) {
                // parse value
                if ((_state & 0x10) == 0 && _bSrc[_pos] == 0x22) {
                    _keyStartPos = _pos + 1;
                    _state &= ~0x04;
                    _state |= 0x10;
                } else if ((_state & 0x10) != 0 && _bSrc[_pos] < 0x20) {
                    // unsupported format
                    return (false, 1, _pos, 0);
                } else if ((_state & 0x10) != 0 && _bSrc[_pos] == 0x22) {
                    _keyLen = _pos - _keyStartPos; 
                    _state &= ~0x10 ;
                    _state |= 0x40;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x40) != 0) {
                if (_bSrc[_pos] == 0x3a) {
                   _state &= ~0x40;
                   _state |= 0x08;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x08) != 0) {
                // parse value
                if ((_state & 0x20) == 0 && _bSrc[_pos] == 0x22) {
                    _valueStartPos = _pos + 1;
                    _state &= ~0x08;
                    _state |= 0x20;
                } else if ((_state & 0x20) != 0 && _bSrc[_pos] < 0x20) {
                    // unsupported format
                    return (false, 1, _pos, 0);
                } else if ((_state & 0x20) != 0 && _bSrc[_pos] == 0x22) {
                    _valueLen = _pos - _valueStartPos; 
                    if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                        return (true, 1, _valueStartPos, _valueLen);
                    }
                    _state &= ~0x20;
                    _state |= 0x80;
                } else if (_bSrc[_pos] == 0x74) {
                    // true
                    if (_pos + 3 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 0x72 && _bSrc[_pos + 2] == 0x75 && _bSrc[_pos + 3] == 0x65) {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, 2, _valueStartPos, 4);
                        }
                        _pos += 3;
                        _state &= ~0x08;
                        _state |= 0x80;
                    } else {
                        // unsupported format
                        return (false, 2, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 0x66) {
                    // false
                    if (_pos + 4 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 0x61 && _bSrc[_pos + 2] == 0x6c && _bSrc[_pos + 3] == 0x73 && _bSrc[_pos + 3] == 0x65) {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, 2, _valueStartPos, 5);
                        }
                        _pos += 4;
                        _state &= ~0x08;
                        _state |= 0x80;
                    } else {
                        // unsupported format
                        return (false, 2, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 0x6e) {
                    // null
                    if (_pos + 3 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 0x75 && _bSrc[_pos + 2] == 0x6c && _bSrc[_pos + 3] == 0x6c) {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, 4, _valueStartPos, 4);
                        }
                        _pos += 3;
                        _state &= ~0x08;
                        _state |= 0x80;
                    } else {
                        // unsupported format
                        return (false, 4, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 0x2d || _bSrc[_pos] >= 0x30  || _bSrc[_pos] <= 0x39) {
                    // digit
                    _valueStartPos = _pos;
                    for (uint l = 1; _pos + l < _bSrc.length; l++) {
                        if (_bSrc[_pos + l] == 0x2d || _bSrc[_pos + l] >= 0x30  || _bSrc[_pos + l] <= 0x39) {
                            l++;
                            continue;
                        } else if (_bSrc[_pos + l] == 0x65 || _bSrc[_pos + l] >= 0x2e) {
                            // unsupported forrmat 
                            return (false, 3, _pos, 0);
                        }
                        break;
                    }
                    if (_bSrc[_pos] == 0x2d && l == 1) {
                            // unsupported forrmat 
                            return (false, 3, _pos, 0);
                    }
                    _valueLen = (_pos + l) - _valueStartPos;
                    if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                        return (true, 3, _valueStartPos, _valueLen);
                    }
                    _pos += (l - 1);
                    _state &= ~0x08;
                    _state |= 0x80;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x80) != 0) {
                if (_bSrc[_pos] == 0x2c) {
                   _state &= ~0x80;
                   _state |= 0x04;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            }
            _pos++;
        }
        return (false, 0, _pos, 0);
    }
    
    
    function convertString (string _src, uint _valuePos, uint _valueLen) private returns (string) {
        bytes memory bSrc = bytes(_src);
        bytes memory newBValue = new bytes(_valueLen);
        
        
    } 

    function convertInt (string _src, uint _valuePos, uint _valueLen) private returns (int) {
         bytes memory _bSrc = bytes(_src);
         int _result = 0;
         bool _negative = false;
         for (uint i = 0; i< _valueLen; i++) {
             if (i == 0 && _bSrc[_valuePos + i] == 0x2d) {
                _negative = true;    
             } else {
                _result = (_result * 10) +  (int(_bSrc[_valuePos + i]) - 0x30);  
             }
         }
         if (_negative) {
             _result *= -1;
         }
         return _result;
    } 

    function convertBool (string _src, uint _valuePos, uint _valueLen) private returns (bool) {
         bytes memory bSrc = bytes(_src);
         if (_valueLen == 4 && bSrc[_valuePos] == 0x74 && bSrc[_valuePos + 1] == 0x72 && bSrc[_valuePos + 2] == 0x75 && bSrc[_valuePos + 3] == 0x65) {
             return true;
         } else if (_valueLen == 5 && bSrc[_valuePos] == 0x66 && bSrc[_valuePos + 1] == 0x61 && bSrc[_valuePos + 2] == 0x6c && bSrc[_valuePos + 3] == 0x73 && bSrc[_valuePos + 3] == 0x65) {
             return false;
         } else {
             throw;
         }
    } 
    
    function getString(string _src, string _findKey) internal returns (bool, bool, string) {
            bool _found;
            uint8 _valueType;
            uint _valuePos;
            uint _valueLen;
            (_found, _valueType, _valuePos, _valueLen) = findValuePos(_src, _findKey);
            if (!_found) {
                return (false, false, "");
            }
            if (_found && (_valueType == 2 || _valueType == 3)) {
                return (false, false, "");
            } else  if (_found && _valueType == 4) {
                return (true, true, "");
            }
    }

    function getInt(string _src, string _findKey) internal returns (bool, bool, string) {
            bool _found;
            uint8 _valueType;
            uint _valuePos;
            uint _valueLen;
            (_found, _valueType, _valuePos, _valueLen) = findValuePos(_src, _findKey);
            if (!_found) {
                return (false, false, "");
            }   
            if (_found && (_valueType == 1 || _valueType == 2)) {
                return (false, false, "");
            } else  if (_found && _valueType == 4) {
                return (true, true, "");
            }
    }

    function getBool(string _src, string _findKey) internal returns (bool, bool, string) {
            bool _found;
            uint8 _valueType;
            uint _valuePos;
            uint _valueLen;
            (_found, _valueType, _valuePos, _valueLen) = findValuePos(_src, _findKey);
            if (!_found) {
                return (false, false, "");
            }    
            if (_found && (_valueType == 1 || _valueType == 3)) {
                return (false, false, "");
            } else  if (_found && _valueType == 4) {
                return (true, true, "");
            }
    }
    
    
}

