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
    
    function isKeymatch(string keyA, bytes bSrc, uint bkeyBPos, uint keyBLen) private returns (bool) {
        bytes memory bkeyA = bytes(keyA);
        if (bkeyA.length != keyBLen) {
            return false;
        }
        for (uint i = 0; i < keyBLen; i++) {
           if (bkeyA[i] != bSrc[bkeyBPos + i]) {
               return false;
           } 
        }
        return true;
    }
    
    function findValuePos(string src, string findKey) private returns (bool, uint8, uint, uint) {
        bytes memory bSrc = bytes(src);
        int16 state = 0;
        uint pos = 0;
        uint keyStartPos = 0;
        uint keyLen = 0;
        uint valueStartPos = 0;
        uint valueLen = 0;
        
        while (true) {
            if (pos == bSrc.length) {
                break;
            }
            if ((state & (0x10 | 0x40)) == 0) {
                // skip white space
                if (bSrc[pos] == 0x20 || bSrc[pos] == 0x09 || bSrc[pos] == 0x0a || bSrc[pos] == 0x0d) {
                    pos++;
                    continue;
                }
            }
            if ((state & 0x02) == 0) {
                if (bSrc[pos] == 0x7b) {
                    // start object
                    state |= 0x02;
                    state |= 0x04;
                    pos++;
                    continue;
                } else {
                    // unsupported format
                    return (false, 0, pos, 0);
                }
            } else if ((state & 0x02) != 0) {
                if (bSrc[pos] == 0x7d) {
                    // end object
                    break;
                } else {
                    // unsupported format
                    return (false, 0, pos, 0);
                }
            } else if ((state & 0x04) != 0) {
                // parse value
                if ((state & 0x10) == 0 && bSrc[pos] == 0x22) {
                    keyStartPos = pos + 1;
                    state &= ~0x04;
                    state |= 0x10;
                } else if ((state & 0x10) != 0 && bSrc[pos] < 0x20) {
                    // unsupported format
                    return (false, 1, pos, 0);
                } else if ((state & 0x10) != 0 && bSrc[pos] == 0x22) {
                    keyLen = pos - keyStartPos; 
                    state &= ~0x10 ;
                    state |= 0x40;
                } else {
                    // unsupported format
                     return (false, 0, pos, 0);
                }
            } else if ((state & 0x40) != 0) {
                if (bSrc[pos] == 0x3a) {
                   state &= ~0x40;
                   state |= 0x08;
                } else {
                    // unsupported format
                     return (false, 0, pos, 0);
                }
            } else if ((state & 0x08) != 0) {
                // parse value
                if ((state & 0x20) == 0 && bSrc[pos] == 0x22) {
                    valueStartPos = pos + 1;
                    state &= ~0x08;
                    state |= 0x20;
                } else if ((state & 0x20) != 0 && bSrc[pos] < 0x20) {
                    // unsupported format
                    return (false, 1, pos, 0);
                } else if ((state & 0x20) != 0 && bSrc[pos] == 0x22) {
                    valueLen = pos - valueStartPos; 
                    if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                        return (true, 1, valueStartPos, valueLen);
                    }
                    state &= ~0x20;
                    state |= 0x80;
                } else if (bSrc[pos] == 0x74) {
                    // true
                    if (pos + 3 >= bSrc.length) {
                        break;
                    }
                    if (bSrc[pos] == 0x74 && bSrc[pos + 1] == 0x72 && bSrc[pos + 2] == 0x75 && bSrc[pos + 3] == 0x65) {
                        if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                            return (true, 2, valueStartPos, 4);
                        }
                        pos += 3;
                        state &= ~0x08;
                        state |= 0x80;
                    } else {
                        // unsupported format
                        return (false, 2, pos, 0);
                    }
                } else if (bSrc[pos] == 0x66) {
                    // false
                    if (pos + 4 >= bSrc.length) {
                        break;
                    }
                    if (bSrc[pos] == 0x66 && bSrc[pos + 1] == 0x61 && bSrc[pos + 2] == 0x6c && bSrc[pos + 3] == 0x73 && bSrc[pos + 3] == 0x65) {
                        if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                            return (true, 2, valueStartPos, 5);
                        }
                        pos += 4;
                        state &= ~0x08;
                        state |= 0x80;
                    } else {
                        // unsupported format
                        return (false, 2, pos, 0);
                    }
                } else if (bSrc[pos] == 0x6e) {
                    // null
                    if (pos + 3 >= bSrc.length) {
                        break;
                    }
                    if (bSrc[pos] == 0x6e && bSrc[pos + 1] == 0x75 && bSrc[pos + 2] == 0x6c && bSrc[pos + 3] == 0x6c) {
                        if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                            return (true, 4, valueStartPos, 4);
                        }
                        pos += 3;
                        state &= ~0x08;
                        state |= 0x80;
                    } else {
                        // unsupported format
                        return (false, 4, pos, 0);
                    }
                } else if (bSrc[pos] == 0x2d || bSrc[pos] >= 0x30  || bSrc[pos] <= 0x39) {
                    // digit
                    valueStartPos = pos;
                    for (uint l = 0; pos + l < bSrc.length; l++) {
                        if (bSrc[pos + l] == 0x2d || bSrc[pos + l] >= 0x30  || bSrc[pos + l] <= 0x39) {
                            l++;
                            continue;
                        } else if (bSrc[pos + l] == 0x65 || bSrc[pos + l] >= 0x2e) {
                            // unsupported forrmat 
                        return (false, 3, pos, 0);
                        }
                        break;
                    }
                    valueLen = (pos + l) - valueStartPos;
                    if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                        return (true, 3, valueStartPos, valueLen);
                    }
                    pos += (l - 1);
                    state &= ~0x08;
                    state |= 0x80;
                } else {
                    // unsupported format
                    return (false, 0, pos, 0);
                }
            } else if ((state & 0x80) != 0) {
                if (bSrc[pos] == 0x2c) {
                   state &= ~0x80;
                   state |= 0x04;
                } else {
                    // unsupported format
                    return (false, 0, pos, 0);
                }
            }
            pos++;
        }
        return (false, 0, pos, 0);
    }
    
    
    function convertString (string _src, uint _valuePos, uint _valueLen) private returns (string) {
        
    } 

    function convertInt (string _src, uint _valuePos, uint _valueLen) private returns (int) {
        
    } 

    function convertBool (string _src, uint _valuePos, uint _valueLen) private returns (bool) {
        
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

