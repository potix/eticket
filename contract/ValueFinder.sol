pragma solidity ^0.4.11;

library ValueFinder {
    // 一度paeseしたところは覚えておいて、パースを端折る昨日入れる
    // この際stackを作って、パースした情報はそこに入れていく
    // メモリが動的に容量拡張できないので、自前であたらしい領域を倍のサイズで確保してコピー(realloc)
    // initで初期容量を指定できるようにする。0なら勝手に決める
    
    uint8 constant VT_NONE   = 0;
    uint8 constant VT_STRING = 1;
    uint8 constant VT_BOOL   = 2;
    uint8 constant VT_INT    = 3;
    uint8 constant VT_NULL   = 4;
    
    uint8 constant ST_ARRAY_START     = 0x01;
    uint8 constant ST_OBJECT_START    = 0x02;
    uint8 constant ST_KEY_START       = 0x04;
    uint8 constant ST_VALUE_START     = 0x08;
    uint8 constant ST_NAME_SEP_START  = 0x10;
    uint8 constant ST_VALUE_SEP_START = 0x20;
    
    struct finder {
        bytes bSrc;
        bool found;
        uint8 vType;
        uint keyStartPos;
        uint keyLen;
        uint valueStartPos;
        uint valueLen;  
    }
    
    function isKeyMatch(finder _finder, string _findKey) private returns (bool) {
        bytes memory bFindKey = bytes(_findKey);
        if (bFindKey.length != _finder.keyLen) {
            return false;
        }
        for (uint i = 0; i < _finder.keyLen; i++) {
           if (bFindKey[i] != _finder.bSrc[_finder.keyStartPos + i]) {
               return false;
           } 
        }
        return true;
    }
    
    function findValuePos(finder _finder, string _findKey, int _findArrayIndex) private {
        uint8 _state = 0;
        uint _pos = 0;
        uint _i;
        uint _j;
        byte _c;
        byte _nc;
        int _arrayIndex;
        while (true) {
            if (_pos == _finder.bSrc.length) {
                break;
            }
            _c = _finder.bSrc[_pos];
            // skip white space
            if (_c == 0x20 || _c == 0x09 || _c == 0x0a || _c == 0x0d) {
                _pos++;
                continue;
            }
            if ((_state & ST_OBJECT_START) == 0 && _c == '{') {
                // start object
                _pos++;
                _state |= ST_OBJECT_START;
                _state |= ST_KEY_START;
                continue;
            } else if ((_state & ST_OBJECT_START) != 0 && _c == '}') {
                // end object
                _pos++;
                _state &= ~ST_OBJECT_START;
                break;
            } else if ((_state & ST_KEY_START) != 0) {
                // parse value
                if (_c == '"') {
                    _pos++;
                    _finder.keyStartPos = _pos;
                    for (_i = 0; _pos + _i < _finder.bSrc.length; _i++) {
                        _nc = _finder.bSrc[_pos + _i]; 
                        if (_nc <= 0x1F) {
                            // unsupported format
                            _finder.found = false;
                            _finder.vType = VT_NONE;
                            return;
                        } else if (_nc == '\\') {
                            if (_pos + _i + 1 >= _finder.bSrc.length) {
                                // unsupported format
                                _finder.found = false;
                                _finder.vType = VT_NONE;
                                return;
                            }
                            _i++;
                            _nc = _finder.bSrc[_pos + _i];
                            if (_nc == '"' || 
                                _nc == '\\' ||
                                _nc == '/' ||
                                _nc == 'b' ||
                                _nc == 'f' ||
                                _nc == 'n' ||
                                _nc == 'r' ||
                                _nc == 't') {
                                // pass
                            } else if (_nc == 'u') {
                                if (_pos + _i + 4 >= _finder.bSrc.length) {
                                    // unsupported format
                                    _finder.found = false;
                                    _finder.vType = VT_NONE;
                                    return;
                                }
                                for (_j = 0; _j < 4; _j++) {
                                    _nc = _finder.bSrc[_pos + _i + _j];
                                    if ((_nc >= '0' && _nc <= '9') ||
                                        (_nc >= 'a' && _nc <= 'f') ||
                                        (_nc >= 'A' && _nc <= 'F')) {
                                        // pass
                                    } else {
                                        // unsupported format
                                        _finder.found = false;
                                        _finder.vType = VT_NONE;
                                        return;
                                    }
                                }
                                _i += 4;
                            } else {
                                // unsupported format
                                _finder.found = false;
                                _finder.vType = VT_NONE;
                                return;
                            }
                        } else if (_nc == '"') {
                            break;  
                        }               
                    }
                    if (_c == '"' && _i == 0) {
                        // unsupported format
                        _finder.found = false;
                        _finder.vType = VT_NONE;
                        return;
                    }
                    _finder.keyLen = _pos + _i - _finder.keyStartPos; 
                    _pos += _i + 1;
                    _state &=  ~ST_KEY_START;
                    _state |= ST_NAME_SEP_START;
                    continue;
                } else {
                    // unsupported format
                    _finder.found = false;
                    _finder.vType = VT_NONE;
                    return;
                }
            } else if ((_state & ST_NAME_SEP_START) != 0) {
                if (_c == ':') {
                   _pos++;
                   _state &=  ~ST_NAME_SEP_START;
                   _state |= ST_VALUE_START;
                   _arrayIndex = 0;
                   continue;
                } else {
                    // unsupported format
                    _finder.found = false;
                    _finder.vType = VT_NONE;
                    return;
                }
            } else if ((_state & ST_VALUE_START) != 0) {
                // parse value
                if ((_state & ST_ARRAY_START) == 0 &&  _c == "[") {
                    _pos++;
                    _state |= ST_ARRAY_START;
                    continue;
                } else if ((_state & ST_ARRAY_START) != 0 &&  _c == "]") {
                    // empty array
                    _pos++;
                    _state &= ~ST_ARRAY_START;
                    _state &=  ~ST_VALUE_START;
                    _state |= ST_VALUE_SEP_START;
                    continue;
                } else if (_c== '"') {
                    _pos++;
                    _finder.valueStartPos = _pos;
                    for (_i = 0; _pos + _i < _finder.bSrc.length; _i++) {
                        _nc = _finder.bSrc[_pos + _i];
                        if (_nc <= 0x1f) {
                            // unsupported format
                            _finder.found = false;
                            _finder.vType = VT_NONE;
                            return;
                        } else if (_nc == '\\') {
                            if (_pos + _i + 1 >= _finder.bSrc.length) {
                                // unsupported format
                                _finder.found = false;
                                _finder.vType = VT_NONE;
                                return;
                            }
                            _i++;
                            _nc = _finder.bSrc[_pos + _i];
                            if (_nc == '"' || 
                                _nc == '\\' ||
                                _nc == '/' ||
                                _nc == 'b' ||
                                _nc == 'f' ||
                                _nc == 'n' ||
                                _nc == 'r' ||
                                _nc == 't') {
                                // pass
                            } else if (_nc == 'u') {
                                if (_pos + _i + 4 >= _finder.bSrc.length) {
                                    // unsupported format
                                    _finder.found = false;
                                    _finder.vType = VT_NONE;
                                    return;
                                }
                                for (_j = 0; _j < 4; _j++) {
                                    _nc = _finder.bSrc[_pos + _i + _j]; 
                                    if ((_nc >= '0' && _nc <= '9') ||
                                        (_nc >= 'a' && _nc <= 'f') ||
                                        (_nc >= 'A' && _nc <= 'F')) {
                                        // pass
                                    } else {
                                        // unsupported format
                                        _finder.found = false;
                                        _finder.vType = VT_NONE;
                                        return;
                                    }
                                }
                                _i += 4;
                            } else {
                                // unsupported format
                                _finder.found = false;
                                _finder.vType = VT_NONE;
                                return;
                            }
                        } else if (_nc == '"') {
                            break;  
                        }               
                    }
                    if (_c == '"' && _i == 0) {
                        // unsupported format
                        _finder.found = false;
                        _finder.vType = VT_NONE;
                        return;
                    }
                    _finder.valueLen = _pos + _i - _finder.valueStartPos; 
                     if (isKeyMatch(_finder, _findKey) &&
                        (_findArrayIndex == -1 || (_findArrayIndex >= 0 && _findArrayIndex == _arrayIndex))) {
                        _finder.found = true;
                        _finder.vType = VT_STRING;
                        return;
                    } 
                    _pos += _i + 1;
                    _state &=  ~ST_VALUE_START;
                    _state |= ST_VALUE_SEP_START;
                    if ((_state & ST_ARRAY_START) != 0) {
                        _arrayIndex++;
                    }
                    continue;
                } else if (_c == 't') {
                    // true
                    if (_pos + 3 >= _finder.bSrc.length) {
                        break;
                    }
                    if (_finder.bSrc[_pos + 1] == 'r' &&
                        _finder.bSrc[_pos + 2] == 'u' && 
                        _finder.bSrc[_pos + 3] == 'e') {
                        if (isKeyMatch(_finder, _findKey) &&
                            (_findArrayIndex == -1 || (_findArrayIndex >= 0 && _findArrayIndex == _arrayIndex))) {
                            _finder.found = true;
                            _finder.vType = VT_BOOL;
                            _finder.valueStartPos = _pos;
                            _finder.valueLen = 4;
                            return;
                        }
                        _pos += 4;
                        _state &=  ~ST_VALUE_START;
                        _state |= ST_VALUE_SEP_START;
                        if ((_state & ST_ARRAY_START) != 0) {
                            _arrayIndex++;
                        }
                        continue;
                    } else {
                        // unsupported format
                        _finder.found = false;
                        _finder.vType = VT_NONE;
                        return;
                    }
                } else if (_c == 'f') {
                    // false
                    if (_pos + 4 >= _finder.bSrc.length) {
                        break;
                    }
                    if (_finder.bSrc[_pos + 1] == 'a' &&
                        _finder.bSrc[_pos + 2] == 'l' &&
                        _finder.bSrc[_pos + 3] == 's' &&
                        _finder.bSrc[_pos + 4] == 'e') {
                         if (isKeyMatch(_finder, _findKey) &&
                            (_findArrayIndex == -1 || (_findArrayIndex >= 0 && _findArrayIndex == _arrayIndex))) {
                           _finder.found = true;
                            _finder.vType = VT_BOOL;
                            _finder.valueStartPos = _pos;
                            _finder.valueLen = 5;
                            return;
                        }
                        _pos += 5;
                        _state &= ~ST_VALUE_START;
                        _state |= ST_VALUE_SEP_START;
                        if ((_state & ST_ARRAY_START) != 0) {
                            _arrayIndex++;
                        }
                        continue;
                    } else {
                        // unsupported format
                        _finder.found = false;
                        _finder.vType = VT_NONE;
                        return;
                    }
                } else if (_c == 'n') {
                    // null
                    if (_pos + 3 >= _finder.bSrc.length) {
                        break;
                    }
                    if (_finder.bSrc[_pos + 1] == 'u' &&
                        _finder.bSrc[_pos + 2] == 'l' &&
                        _finder.bSrc[_pos + 3] == 'l') {
                        if (isKeyMatch(_finder, _findKey) &&
                            (_findArrayIndex == -1 || (_findArrayIndex >= 0 && _findArrayIndex == _arrayIndex))) {
                            _finder.found = true;
                            _finder.vType = VT_NULL;
                            _finder.valueStartPos = _pos;
                            _finder.valueLen = 4;
                            return;
                        }
                        _pos += 4;
                        _state &=  ~ST_VALUE_START;
                        _state |= ST_VALUE_SEP_START;
                        if ((_state & ST_ARRAY_START) != 0) {
                            _arrayIndex++;
                        }
                        continue;
                    } else {
                        // unsupported format
                        _finder.found = false;
                        _finder.vType = VT_NONE;
                        return;
                    }
                } else if (_c == '-' || (_c >= '0'  && _c <= '9')) {
                    // digit
                    _finder.valueStartPos = _pos;
                    _pos++;
                    for (_i = 0; _pos + _i < _finder.bSrc.length; _i++) {
                        _nc = _finder.bSrc[_pos + _i];
                        if (_nc >= '0'  && _nc <= '9') {
                            continue;
                        } else if (_nc == '.' || _nc == '+' || _nc == 'e') {
                            // unsupported forrmat 
                            _finder.found = false;
                            _finder.vType = VT_NONE;
                            return;
                        }
                        break;
                    }
                    if ((_c == '-' || (_c >= '0' && _c <= '9')) && _i == 0) {
                            // unsupported forrmat 
                            _finder.found = false;
                            _finder.vType = VT_NONE;
                            return;
                    }
                    _finder.valueLen = _pos + _i - _finder.valueStartPos;
                    if (isKeyMatch(_finder, _findKey) &&
                        (_findArrayIndex == -1 || (_findArrayIndex >= 0 && _findArrayIndex == _arrayIndex))) {
                        _finder.found = true;
                        _finder.vType = VT_INT;
                        return;
                    }
                    _pos += _i;
                    _state &=  ~ST_VALUE_START;
                    _state |= ST_VALUE_SEP_START;
                    if ((_state & ST_ARRAY_START) != 0) {
                        _arrayIndex++;
                    }
                    continue;
                } else {
                    // unsupported format
                    _finder.found = false;
                    _finder.vType = VT_NONE;
                    return;
                }
            } else if ((_state & ST_VALUE_SEP_START) != 0) {
                if ((_state & ST_ARRAY_START) != 0 &&  _c == "]") {
                    _pos++;
                    _state &= ~ST_ARRAY_START;
                    continue;
                } else if (_c == 0x2c) {
                    _pos++;
                    _state &=  ~ST_VALUE_SEP_START;
                     if ((_state & ST_ARRAY_START) != 0) {
                         _state |= ST_VALUE_START; 
                     } else {
                         _state |= ST_KEY_START;
                     }
                     continue;
                } else {
                    // unsupported format
                    _finder.found = false;
                    _finder.vType = VT_NONE;
                    return;
                }
            }
            _pos++;
        }
        _finder.found = false;
        _finder.vType = VT_NONE;
        return;
    }
    
    function convertString (finder _finder) private returns (bytes) {
        bytes memory _newBValue = new bytes(_finder.valueLen);
        uint _i;
        uint _j;
        uint _k = 0;
        byte _c;
        uint16 _code = 0;
        for (_i = 0; _i < _finder.valueLen; _i++) {
            _c = _finder.bSrc[_finder.valueStartPos + _i];
            if (_c == '\\') {
                _i++;
                _c = _finder.bSrc[_finder.valueStartPos + _i]; 
                if (_c == '"') { 
                    _newBValue[_k++] = '"';
                } else if (_c == '\\') {
                    _newBValue[_k++] = '\\';
                } else if (_c == '/') {
                    _newBValue[_k++] = '/';
                } else if (_c == 'b') {
                    _newBValue[_k++] = '\b';
                } else if (_c == 'f') {
                    _newBValue[_k++] = '\f';
                } else if (_c == 'n') {
                    _newBValue[_k++] = '\n';
                } else if (_c == 'r') {
                    _newBValue[_k++] = '\r';
                } else if (_c == 't') {
                    _newBValue[_k++] = '\t';
                } else if (_c == 'u') {
                    _i++;
                    for (_j = 0; _j < 4; _j++) {
                        _code = (_code << 4) | ((((uint16(_finder.bSrc[_finder.valueStartPos + _i + _j]) - 33) % 32) + 10) % 25); 
                    }
                    if (_code <= 0x7F) {
					    _newBValue[_k++] = byte(_code);
				    } else if (_code <= 0x7FF) {
					    _newBValue[_k++] = byte(0xC0 | (_code >> 6));
				    	_newBValue[_k++]  = byte(0x80 | (_code & 0x3F));
			    	} else {
			    		_newBValue[_k++]  = byte(0xE0 | (_code >> 12));
			    		_newBValue[_k++]  = byte(0x80 | ((_code >> 6) & 0x3F));
			    		_newBValue[_k++]  = byte(0x80 | (_code & 0x3F));
				    }
				    _i += 4;
                } else {
                    assert(false);
                }
            } else {
                _newBValue[_k++] = _c; 
            }
        }
        return _newBValue;
    } 

    function convertInt (finder _finder) private returns (int) {
         int _result = 0;
         bool _negative = false;
         uint _i;
         for (_i = 0; _i < _finder.valueLen; _i++) {
             if (_i == 0 && _finder.bSrc[_finder.valueStartPos + _i] == '-') {
                _negative = true;  
                continue;
             }
            _result = (_result * 10) + (int(_finder.bSrc[_finder.valueStartPos + _i]) - 0x30);  
         }
         if (_negative) {
             _result *= -1;
         }
         return _result;
    } 

    function convertBool (finder _finder) private returns (bool) {
         if (_finder.valueLen == 4 && 
             _finder.bSrc[_finder.valueStartPos] == 't' && 
             _finder.bSrc[_finder.valueStartPos + 1] == 'r' && 
             _finder.bSrc[_finder.valueStartPos + 2] == 'u' && 
             _finder.bSrc[_finder.valueStartPos + 3] == 'e') {
             return true;
         } else if (_finder.valueLen == 5 &&
             _finder.bSrc[_finder.valueStartPos] == 'f' &&
             _finder.bSrc[_finder.valueStartPos + 1] == 'a' &&
             _finder.bSrc[_finder.valueStartPos + 2] == 'l' &&
             _finder.bSrc[_finder.valueStartPos + 3] == 's' &&
             _finder.bSrc[_finder.valueStartPos + 4] == 'e') {
             return false;
         } else {
             // not reached
             assert(false);
         }
    } 
    
    function initFinder(string _src) internal returns (finder) {
       return  finder({
            bSrc: bytes(_src),
            found : false,
            vType : 0,
            keyStartPos: 0,
            keyLen: 0,
            valueStartPos: 0,
            valueLen: 0
        });  
    } 
    
    function findString(finder _finder, string _findKey) internal returns (bool, bool, bytes) {
        findValuePos(_finder, _findKey, -1);
        if (!_finder.found) {
            return (false, false, new bytes(0));
        }
        if (_finder.found && _finder.vType == VT_STRING) {
            return (true, false, convertString(_finder));
        } else if (_finder.found && _finder.vType == VT_NULL) {
            return (true, true, new bytes(0));
        } else {
            return (false, false, new bytes(0));
        }
    }

    function findInt(finder _finder, string _findKey) internal returns (bool, bool, int) {
            findValuePos(_finder, _findKey, -1);
            if (!_finder.found) {
                return (false, false, 0);
            }   
            if (_finder.found && _finder.vType == VT_INT) {
                return (true, false, convertInt(_finder));
            } else if (_finder.found && _finder.vType == VT_NULL) {
                return (true, true, 0);
            } else {
                return (false, false, 0);
            }
    }

    function findBool(finder _finder, string _findKey) internal returns (bool, bool, bool) {
            findValuePos(_finder, _findKey, -1);
            if (!_finder.found) {
                return (false, false, false);
            }    
            if (_finder.found && _finder.vType == VT_BOOL) {
                return (true, false, convertBool(_finder));
            } else if (_finder.found && _finder.vType == VT_NULL) {
                return (true, true, false);
            } else {
                return (false, false, false);
            }
    }
    
    function findArrayString(finder _finder, string _findKey, int _arrayIndex) internal returns (bool, bool, bytes) {
        findValuePos(_finder, _findKey, _arrayIndex);
        if (!_finder.found) {
            return (false, false, new bytes(0));
        }
        if (_finder.found && _finder.vType == VT_STRING) {
            return (true, false, convertString(_finder));
        } else if (_finder.found && _finder.vType == VT_NULL) {
            return (true, true, new bytes(0));
        } else {
            return (false, false, new bytes(0));
        }
    }

    function findArrayInt(finder _finder, string _findKey, int _arrayIndex) internal returns (bool, bool, int) {
            findValuePos(_finder, _findKey, _arrayIndex);
            if (!_finder.found) {
                return (false, false, 0);
            }   
            if (_finder.found && _finder.vType == VT_INT) {
                return (true, false, convertInt(_finder));
            } else if (_finder.found && _finder.vType == VT_NULL) {
                return (true, true, 0);
            } else {
                return (false, false, 0);
            }
    }

    function findArrayBool(finder _finder, string _findKey, int _arrayIndex) internal returns (bool, bool, bool) {
            findValuePos(_finder, _findKey, _arrayIndex);
            if (!_finder.found) {
                return (false, false, false);
            }    
            if (_finder.found && _finder.vType == VT_BOOL) {
                return (true, false, convertBool(_finder));
            } else if (_finder.found && _finder.vType == VT_NULL) {
                return (true, true, false);
            } else {
                return (false, false, false);
            }
    }
}

