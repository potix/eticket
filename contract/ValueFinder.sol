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
        uint l;
        while (true) {
            if (_pos == _bSrc.length) {
                break;
            }
            // skip white space
            if (_bSrc[_pos] == 0x20 || _bSrc[_pos] == 0x09 || _bSrc[_pos] == 0x0a || _bSrc[_pos] == 0x0d) {
                _pos++;
                continue;
            }
            if ((_state & 0x02) == 0) {
                if (_bSrc[_pos] == 0x7b) {
                    // start object
                    _pos++;
                    _state |= 0x02;
                    _state |= 0x04;
                    continue;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x02) != 0) {
                if (_bSrc[_pos] == 0x7d) {
                    // end object
                    _state &= ~0x02;
                    _pos++;
                    break;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x04) != 0) {
                // parse value
                if ((_state & 0x10) == 0 && _bSrc[_pos] == 0x22) {
                    for (l = 1; _pos + l < _bSrc.length; l++) {
                        if (l == 1) {
                            _keyStartPos = _pos + 1;
                        }
                        if (_bSrc[_pos + l] < 20) {
                            // unsupported format
                            return (false, 1, _pos, 0);
                        } else if (_bSrc[_pos + l] == 0x5c) {
                            // escaped
                            if (_bSrc[_pos + l + 1] == 0x22 || 
                                _bSrc[_pos + l + 1] == 0x5c ||
                                _bSrc[_pos + l + 1] == 0x2f ||
                                _bSrc[_pos + l + 1] == 0x62 ||
                                _bSrc[_pos + l + 1] == 0x66 ||
                                _bSrc[_pos + l + 1] == 0x6e ||
                                _bSrc[_pos + l + 1] == 0x72 ||
                                _bSrc[_pos + l + 1] == 0x74) {
                                if (_pos + l + 1 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, 1, _pos, 0);
                                }
                                l++;
                            } else if (_bSrc[_pos + l + 1] == 0x75) {
                                if (_pos + l + 5 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, 1, _pos, 0);
                                }
                                l += 5;
                            }
                        } else if (_bSrc[_pos + l] == 0x22) {
                            break;  
                        }               
                    }
                    if (_bSrc[_pos] == 0x22 && l == 1) {
                        // unsupported format
                        return (false, 1, _pos, 0);
                    }
                    _keyLen = _pos + l - _keyStartPos; 
                    _pos += l;
                    _state &= ~0x04;
                    _state |= 0x40;
                    continue;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x40) != 0) {
                if (_bSrc[_pos] == 0x3a) {
                   _pos++;
                   _state &= ~0x40;
                   _state |= 0x08;
                   continue;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x08) != 0) {
                // parse value
                if ((_state & 0x20) == 0 && _bSrc[_pos] == 0x22) {
                    for (l = 1; _pos + l < _bSrc.length; l++) {
                        if (l == 1) {
                            _valueStartPos = _pos + 1;
                        }
                        if (_bSrc[_pos + l] < 20) {
                            // unsupported format
                            return (false, 1, _pos, 0);
                        } else if (_bSrc[_pos + l] == 0x5c) {
                            // escaped
                            if (_bSrc[_pos + l + 1] == 0x22 || 
                                _bSrc[_pos + l + 1] == 0x5c ||
                                _bSrc[_pos + l + 1] == 0x2f ||
                                _bSrc[_pos + l + 1] == 0x62 ||
                                _bSrc[_pos + l + 1] == 0x66 ||
                                _bSrc[_pos + l + 1] == 0x6e ||
                                _bSrc[_pos + l + 1] == 0x72 ||
                                _bSrc[_pos + l + 1] == 0x74) {
                                if (_pos + l + 1 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, 1, _pos, 0);
                                }
                                l++;
                            } else if (_bSrc[_pos + l + 1] == 0x75) {
                                if (_pos + l + 5 >= _bSrc.length) {
                                        // unsupported format
                                        return (false, 1, _pos, 0);
                                }
                                l += 5;
                            }
                        } else if (_bSrc[_pos + l] == 0x22) {
                            break;  
                        }               
                    }
                    if (_bSrc[_pos] == 0x22 && l == 1) {
                        // unsupported format
                        return (false, 1, _pos, 0);
                    }
                    _valueLen = _pos + l - _valueStartPos; 
                    _pos += l;
                    _state &= ~0x08;
                    _state |= 0x80;
                    continue;
                } else if (_bSrc[_pos] == 0x74) {
                    // true
                    if (_pos + 3 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 0x72 && _bSrc[_pos + 2] == 0x75 && _bSrc[_pos + 3] == 0x65) {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, 2, _valueStartPos, 4);
                        }
                        _pos += 4;
                        _state &= ~0x08;
                        _state |= 0x80;
                        continue;
                    } else {
                        // unsupported format
                        return (false, 2, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 0x66) {
                    // false
                    if (_pos + 4 >= _bSrc.length) {
                        break;
                    }
                    if (_bSrc[_pos + 1] == 0x61 && _bSrc[_pos + 2] == 0x6c && _bSrc[_pos + 3] == 0x73 && _bSrc[_pos + 4] == 0x65) {
                        if (isKeymatch(_findKey, _bSrc, _keyStartPos, _keyLen)) {
                            return (true, 2, _valueStartPos, 5);
                        }
                        _pos += 5;
                        _state &= ~0x08;
                        _state |= 0x80;
                        continue;
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
                        _pos += 4;
                        _state &= ~0x08;
                        _state |= 0x80;
                        continue;
                    } else {
                        // unsupported format
                        return (false, 4, _pos, 0);
                    }
                } else if (_bSrc[_pos] == 0x2d || _bSrc[_pos] >= 0x30  || _bSrc[_pos] <= 0x39) {
                    // digit
                    _valueStartPos = _pos;
                    for (l = 1; _pos + l < _bSrc.length; l++) {
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
                    _pos += l;
                    _state &= ~0x08;
                    _state |= 0x80;
                    continue;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            } else if ((_state & 0x80) != 0) {
                if (_bSrc[_pos] == 0x2c) {
                   _pos++;
                   _state &= ~0x80;
                   _state |= 0x04;
                   continue;
                } else {
                    // unsupported format
                    return (false, 0, _pos, 0);
                }
            }
            _pos++;
        }
        return (false, 0, _pos, 0);
    }
    
    
    function convertString (string _src, uint _valuePos, uint _valueLen) private returns (string, bool) {
        bytes memory _bSrc = bytes(_src);
        bytes memory _newBValue = new bytes(_valueLen);
        uint i = 0;
        for (uint l = 0; l < _valueLen; l++) {
            if (_bSrc[_valuePos + l] == 0x5c) {
                if (_bSrc[_valuePos + l + 1] == 0x22 || 
                    _bSrc[_valuePos + l + 1] == 0x5c ||
                    _bSrc[_valuePos + l + 1] == 0x2f ||
                    _bSrc[_valuePos + l + 1] == 0x62 ||
                    _bSrc[_valuePos + l + 1] == 0x66 ||
                    _bSrc[_valuePos + l + 1] == 0x6e ||
                    _bSrc[_valuePos + l + 1] == 0x72 ||
                    _bSrc[_valuePos + l + 1] == 0x74) {
                        _newBValue[i++] = _bSrc[_valuePos + l + 1];    
                        l++;
                } else if (_bSrc[_valuePos + l + 1] == 0x75) {
                    uint16 code = 0;
                    uint8 v;
                    for (uint j = 0; j < 4; j++) {
                        
                        if ((_bSrc[_valuePos + l + 1 + j] >= 0x30 && _bSrc[_valuePos + l + 1 + j] <= 0x39) ||
                            (_bSrc[_valuePos + l + 1 + j] >= 0x41 || _bSrc[_valuePos + l + 1 + j] <= 0x46) ||
                            (_bSrc[_valuePos + l + 1 + j] >= 0x61 || _bSrc[_valuePos + l + 1 + j] <= 0x66)) {
                                v = (((uint8(_bSrc[_valuePos + l + 1 + j]) - 33) % 32) + 10 ) % 25;
                        } else {
                            return ("", false);
                        }
                        code = (code * 16) + v; 
                    }
                    if (code <= 0x7F) {
					    _newBValue[i++] = uint8(code * 0xff);
				    } else if (code <= 0x7FF) {
					    _newBValue[i++] = uint8(0xC0 | (code >> 6));
				    	_newBValue[i++]  = uint8(0x80 | (code & 0x3F));
			    	} else if (code <= 0xFFFF) {
			    		_newBValue[i++]  = uint8(0xE0 | (code >> 12));
			    		_newBValue[i++]  = uint8(0x80 | ((code >> 6) & 0x3F));
			    		_newBValue[i++]  = uint8(0x80 | (code & 0x3F));
				    }

                }
            } else {
                _newBValue[i++] = _bSrc[_valuePos + l]; 
            }
        }

        
        
        
    } 

    function convertInt (string _src, uint _valuePos, uint _valueLen) private returns (int) {
         bytes memory _bSrc = bytes(_src);
         int _result = 0;
         bool _negative = false;
         for (uint i = 0; i< _valueLen; i++) {
             if (i == 0 && _bSrc[_valuePos + i] == 0x2d) {
                _negative = true;    
             } else {
                _result = (_result * 10) +  (uint8(_bSrc[_valuePos + i]) - 0x30);  
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

