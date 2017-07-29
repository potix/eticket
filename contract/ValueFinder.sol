pragma solidity ^0.4.11;

library ValueFinder {
    uint8 constant T_NONE     = 0;
    uint8 constant T_K_STRING = 1;
    uint8 constant T_V_STRING = 2;
    uint8 constant T_V_BOOL   = 3;
    uint8 constant T_V_INT    = 4;
    uint8 constant T_V_NULL   = 5;
    
    uint8 constant ST_OBJECT_START    = 0x02;
    uint8 constant ST_KEY_START       = 0x04;
    uint8 constant ST_VALUE_START     = 0x08;
    uint8 constant ST_NAME_SEP_START  = 0x10;
    uint8 constant ST_VALUE_SEP_START = 0x20;
    
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
        uint8 _state = 0;
        uint _pos = 0;
        uint _keyStartPos = 0;
        uint _keyLen = 0;
        uint _valueStartPos = 0;
        uint _valueLen = 0;
        uint l;
        uint m;
        while (true) {
            if (_pos == _bSrc.length) {
                break;
            }
            // skip white space
            if (_bSrc[_pos] == 0x20 || _bSrc[_pos] == 0x09 || _bSrc[_pos] == 0x0a || _bSrc[_pos] == 0x0d) {
                _pos++;
                continue;
            }
            if ((_state & ST_OBJECT_START) == 0) {
                if (_bSrc[_pos] == '{') {
                    // start object
                    _pos++;
                    _state |= ST_OBJECT_START;
                    _state |= ST_KEY_START;
                    continue;
                } else {
                    // unsupported format
                    return (false, T_NONE, _pos, 0);
                }
            } else if ((_state & ST_OBJECT_START) != 0) {
                if (_bSrc[_pos] == '}') {
                    // end object
                    _pos++;
                    _state &= ~ST_OBJECT_START;
                    break;
                } else {
                    // unsupported format
                    return (false, T_NONE, _pos, 0);
                }
            } else if ((_state & ST_KEY_START) != 0) {
                // parse value
                if (_bSrc[_pos] == '"') {
                    _pos++;
                    _keyStartPos = _pos;
                    for (l = 0; _pos + l < _bSrc.length; l++) {
                        if (_bSrc[_pos + l] <= 0x1F) {
                            // unsupported format
                            return (false, T_K_STRING, _pos, 0);
                        } else if (_bSrc[_pos + l] == '\\') {
                            if (_pos + l + 1 >= _bSrc.length) {
                                // unsupported format
                                return (false, T_K_STRING, _pos, 0);
                            }
                            l++;
                            if (_bSrc[_pos + l] == '"' || 
                                _bSrc[_pos + l] == '\\' ||
                                _bSrc[_pos + l] == '/' ||
                                _bSrc[_pos + l] == 'b' ||
                                _bSrc[_pos + l] == 'f' ||
                                _bSrc[_pos + l] == 'n' ||
                                _bSrc[_pos + l] == 'r' ||
                                _bSrc[_pos + l] == 't') {
                            } else if (_bSrc[_pos + l] == 'u') {
                                if (_pos + l + 4 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, T_K_STRING, _pos, 0);
                                }
                                for (m = 0; m < 4; m++) {
                                    if ((_bSrc[_pos + l + m] >= '0' && _bSrc[_pos + l + m] <= '9') ||
                                        (_bSrc[_pos + l + m] >= 'a' && _bSrc[_pos + l + m] <= 'f') ||
                                        (_bSrc[_pos + l + m] >= 'A' && _bSrc[_pos + l + m] <= 'F')) {
                                        // pass
                                    } else {
                                        // unsupported format
                                        return (false, T_K_STRING, _pos, 0);
                                    }
                                }
                                l += 4;
                            } else {
                                // unsupported format
                                return (false, T_K_STRING, _pos, 0); 
                            }
                        } else if (_bSrc[_pos + l] == '"') {
                            break;  
                        }               
                    }
                    if (_bSrc[_pos] == '"' && l == 0) {
                        // unsupported format
                        return (false, T_K_STRING, _pos, 0);
                    }
                    _keyLen = _pos + l - _keyStartPos; 
                    _pos += l;
                    _state &=  ~ST_KEY_START;
                    _state |= ST_NAME_SEP_START;
                    continue;
                } else {
                    // unsupported format
                    return (false, T_NONE, _pos, 0);
                }
            } else if ((_state & ST_NAME_SEP_START) != 0) {
                if (_bSrc[_pos] == ':') {
                   _pos++;
                   _state &=  ~ST_NAME_SEP_START;
                   _state |= ST_VALUE_START;
                   continue;
                } else {
                    // unsupported format
                    return (false, T_NONE, _pos, 0);
                }
            } else if ((_state & ST_VALUE_START) != 0) {
                // parse value
                if (_bSrc[_pos] == '"') {
                    _pos++;
                    _valueStartPos = _pos;
                    for (l = 0; _pos + l < _bSrc.length; l++) {
                        if (_bSrc[_pos + l] <= 0x1f) {
                            // unsupported format
                            return (false, T_V_STRING, _pos, 0);
                        } else if (_bSrc[_pos + l] == '\\') {
                            if (_pos + l + 1 >= _bSrc.length) {
                                // unsupported format
                                return (false, T_V_STRING, _pos, 0);
                            }
                            l++;
                            if (_bSrc[_pos + l] == '"' || 
                                _bSrc[_pos + l] == '\\' ||
                                _bSrc[_pos + l] == '/' ||
                                _bSrc[_pos + l] == 'b' ||
                                _bSrc[_pos + l] == 'f' ||
                                _bSrc[_pos + l] == 'n' ||
                                _bSrc[_pos + l] == 'r' ||
                                _bSrc[_pos + l] == 't') {
                                if (_pos + l + 1 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, T_V_STRING, _pos, 0);
                                }
                                l++;
                            } else if (_bSrc[_pos + l] == 'u') {
                                if (_pos + l + 4 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, T_V_STRING, _pos, 0);
                                }
                                for (m = 0; m < 4; m++) {
                                    if ((_bSrc[_pos + l + m] >= '0' && _bSrc[_pos + l + m] <= '9') ||
                                        (_bSrc[_pos + l + m] >= 'a' && _bSrc[_pos + l + m] <= 'f') ||
                                        (_bSrc[_pos + l + m] >= 'A' && _bSrc[_pos + l + m] <= 'F')) {
                                        // pass
                                    } else {
                                        // unsupported format
                                        return (false, T_V_STRING, _pos, 0);
                                    }
                                }
                                l += 4;
                            } else {
                                // unsupported format
                                return (false, T_V_STRING, _pos, 0); 
                            }
                        } else if (_bSrc[_pos + l] == '"') {
                            break;  
                        }               
                    }
                    if (_bSrc[_pos] == '"' && l == 0) {
                        // unsupported format
                        return (false, T_V_STRING, _pos, 0);
                    }
                    _valueLen = _pos + l - _valueStartPos; 
                    if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                        return (true, T_V_STRING, _valueStartPos, _valueLen);
                    } 
                    _pos += l;
                    _state &=  ~ST_VALUE_START;
                    _state |= ST_VALUE_SEP_START;
                    continue;
                } else if (_bSrc[_pos] == 't') {
                    // true
                    if (_pos + 3 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 'r' && _bSrc[_pos + 2] == 'u' && _bSrc[_pos + 3] == 'e') {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, T_V_BOOL, _valueStartPos, 4);
                        }
                        _pos += 4;
                        _state &=  ~ST_VALUE_START;
                        _state |= ST_VALUE_SEP_START;
                        continue;
                    } else {
                        // unsupported format
                        return (false, T_V_BOOL, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 'f') {
                    // false
                    if (_pos + 4 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 'a' && _bSrc[_pos + 2] == 'l' && _bSrc[_pos + 3] == 's' && _bSrc[_pos + 4] == 'e') {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, T_V_BOOL, _valueStartPos, 5);
                        }
                        _pos += 5;
                        _state &= ~ST_VALUE_START;
                        _state |= ST_VALUE_SEP_START;
                        continue;
                    } else {
                        // unsupported format
                        return (false, T_V_BOOL, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 0x6e) {
                    // null
                    if (_pos + 3 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 'u' && _bSrc[_pos + 2] == 'l' && _bSrc[_pos + 3] == 'l') {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, T_V_NULL, _valueStartPos, 4);
                        }
                        _pos += 4;
                        _state &=  ~ST_VALUE_START;
                        _state |= ST_VALUE_SEP_START;
                        continue;
                    } else {
                        // unsupported format
                        return (false, T_V_NULL, _pos, 0);
                    }
                } else if (_bSrc[_pos] == '-' || (_bSrc[_pos] >= '0'  && _bSrc[_pos] <= '9')) {
                    // digit
                    _valueStartPos = _pos;
                    _pos++;
                    for (l = 0; _pos + l < _bSrc.length; l++) {
                        if (_bSrc[_pos + l] >= '0'  || _bSrc[_pos + l] <= '9') {
                            continue;
                        } else if (_bSrc[_pos + l] == '.' || _bSrc[_pos + l] >= '+' || _bSrc[_pos + l] >= 'e') {
                            // unsupported forrmat 
                            return (false, T_V_INT, _pos, 0);
                        }
                        break;
                    }
                    if ((_bSrc[_pos] == '-' || (_bSrc[_pos] >= '0' && _bSrc[_pos] <= '9')) && l == 0) {
                            // unsupported forrmat 
                            return (false, T_V_INT, _pos, 0);
                    }
                    _valueLen = _pos + l - _valueStartPos;
                    if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                        return (true, T_V_INT, _valueStartPos, _valueLen);
                    }
                    _pos += l;
                    _state &=  ~ST_VALUE_START;
                    _state |= ST_VALUE_SEP_START;
                    continue;
                } else {
                    // unsupported format
                    return (false, T_NONE, _pos, 0);
                }
            } else if ((_state & ST_VALUE_SEP_START) != 0) {
                if (_bSrc[_pos] == 0x2c) {
                   _pos++;
                   _state &=  ~ST_VALUE_SEP_START;
                   _state |= ST_KEY_START;
                   continue;
                } else {
                    // unsupported format
                    return (false, T_NONE, _pos, 0);
                }
            }
            _pos++;
        }
        return (false, T_NONE, _pos, 0);
    }
    
    function convertString (string _src, uint _valuePos, uint _valueLen) private returns (string) {
        bytes memory _bSrc = bytes(_src);
        bytes memory _newBValue = new bytes(_valueLen);
        uint i = 0;
        for (uint l = 0; l < _valueLen; l++) {
            if (_bSrc[_valuePos + l] == '\\') {
                l++;
                if (_bSrc[_valuePos + l] == '"') { 
                    _newBValue[i++] = '"';
                } else if (_bSrc[_valuePos + l] == '\\') {
                    _newBValue[i++] = '\\';
                } else if (_bSrc[_valuePos + l] == '/') {
                    _newBValue[i++] = '/';
                } else if (_bSrc[_valuePos + l] == 'b') {
                    _newBValue[i++] = '\b';
                } else if (_bSrc[_valuePos + l] == 'f') {
                    _newBValue[i++] = '\f';
                } else if (_bSrc[_valuePos + l] == 'n') {
                    _newBValue[i++] = '\n';
                } else if (_bSrc[_valuePos + l] == 'r') {
                    _newBValue[i++] = '\r';
                } else if (_bSrc[_valuePos + l] == 't') {
                    _newBValue[i++] = '\t';
                } else if (_bSrc[_valuePos + l] == 'u') {
                    uint16 code = 0;
                    uint16 v;
                    for (uint j = 0; j < 4; j++) {
                        if (_bSrc[_valuePos + l + j] >= '0' && _bSrc[_valuePos + l + j] <= '9') {
                                v = uint8(_bSrc[_valuePos + l + j]) - uint8(byte('0'));
                        } else if (_bSrc[_valuePos + l + j] >= 'a' && _bSrc[_valuePos + l + j] <= 'f') {
                                v = uint8(_bSrc[_valuePos + l + j]) - uint8(byte('a'));
                        } else if (_bSrc[_valuePos + l + j] >= 'A' && _bSrc[_valuePos + l + j] <= 'F') {
                                v = uint8(_bSrc[_valuePos + l + j]) - uint8(byte('A'));
                        } else {
                            assert(false);
                        }
                        code = (code << 4) | v; 
                    }
                    if (code <= 0x7F) {
					    _newBValue[i++] = byte(code);
				    } else if (code <= 0x7FF) {
					    _newBValue[i++] = byte(0xC0 | (code >> 6));
				    	_newBValue[i++]  = byte(0x80 | (code & 0x3F));
			    	} else {
			    		_newBValue[i++]  = byte(0xE0 | (code >> 12));
			    		_newBValue[i++]  = byte(0x80 | ((code >> 6) & 0x3F));
			    		_newBValue[i++]  = byte(0x80 | (code & 0x3F));
				    }
                } else {
                    assert(false);
                }
            } else {
                _newBValue[i++] = _bSrc[_valuePos + l]; 
            }
        }
        return string(_newBValue);
    } 

    function convertInt (string _src, uint _valuePos, uint _valueLen) private returns (int) {
         bytes memory _bSrc = bytes(_src);
         int _result = 0;
         bool _negative = false;
         for (uint i = 0; i< _valueLen; i++) {
             if (i == 0 && _bSrc[_valuePos + i] == '-') {
                _negative = true;  
                continue;
             }
            _result = (_result * 10) + (int(_bSrc[_valuePos + i]) - 0x30);  
         }
         if (_negative) {
             _result *= -1;
         }
         return _result;
    } 

    function convertBool (string _src, uint _valuePos, uint _valueLen) private returns (bool) {
         bytes memory bSrc = bytes(_src);
         if (_valueLen == 4 && bSrc[_valuePos] == 't' && bSrc[_valuePos + 1] == 'r' && bSrc[_valuePos + 2] == 'u' && bSrc[_valuePos + 3] == 'e') {
             return true;
         } else if (_valueLen == 5 && bSrc[_valuePos] == 'f' && bSrc[_valuePos + 1] == 'a' && bSrc[_valuePos + 2] == 'l' && bSrc[_valuePos + 3] == 's' && bSrc[_valuePos + 4] == 'e') {
             return false;
         } else {
             // not reached
             assert(false);
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
            if (_found && _valueType != T_V_STRING && _valueType != T_V_NULL) {
                return (false, false, "");
            } else if (_found && _valueType == T_V_NULL) {
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
            if (_found && _valueType != T_V_INT && _valueType != T_V_NULL) {
                return (false, false, "");
            } else if (_found && _valueType == T_V_NULL) {
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
            if (_found && _valueType != T_V_BOOL && _valueType != T_V_NULL) {
                return (false, false, "");
            } else if (_found && _valueType == T_V_NULL) {
                return (true, true, "");
            }
    }
    
    
}


