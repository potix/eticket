library ValueFinder {

    // value type
    //
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
    
    function getValueString(bytes bSrc, bytes valuePos, uint valueLen) private returns (string) {
        
    }
    
    function find(string src, string findKey) private returns (bool found, uint valueType, string value) {
        uint pos = 0;
        bytes memory bSrc = bytes(src);
        var state = 0;
        
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
                    break;
                }
            } else if ((state & 0x02) != 0) {
                if (bSrc[pos] == 0x7d) {
                    // end object
                    break;
                } else {
                    // unsupported format
                    break;
                }
            } else if ((state & 0x04) != 0) {
                // parse value
                if ((state & 0x10) == 0 && bSrc[pos] == 0x22) {
                    keyStartPos = pos + 1;
                    state &= ~0x04;
                    state |= 0x10;
                } else if ((state & 0x10) != 0 && bSrc[pos] == 0x22) {
                    keyLen = pos - keyStartPos; 
                    state &= ~0x10 ;
                    state |= 0x40;
                } else {
                    // unsupported format
                    break;
                }
            } else if ((state & 0x40) != 0) {
                if (bSrc[pos] == 0x3a) {
                   state &= ~0x40;
                   state |= 0x08;
                } else {
                    // unsupported format
                    break;
                }
            } else if ((state & 0x08) != 0) {
                // parse value
                if ((state & 0x20) == 0 && bSrc[pos] == 0x22) {
                    valueStartPos = pos + 1;
                    state &= ~0x08;
                    state |= 0x20;
                } else if ((state & 0x20) == 1 && bSrc[pos] == 0x22) {
                    valueLen = pos - valueStartPos; 
                    if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                        valueString = getValueString(bSrc, valueStartPos, valueLen);
                        return (true, 1, valueString);
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
                            valueString = getValueString(bSrc, valueStartPos, 4);
                            return (true, 1, valueString);
                        }
                        pos += 3;
                        state &= ~0x08;
                        state |= 0x80;
                    } else {
                        break;
                    }
                } else if (bSrc[pos] == 0x66) {
                    // false
                    if (pos + 4 >= bSrc.length) {
                        break;
                    }
                    if (bSrc[pos] == 0x66 && bSrc[pos + 1] == 0x61 && bSrc[pos + 2] == 0x6c && bSrc[pos + 3] == 0x73 && bSrc[pos + 3] == 0x65) {
                        if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                            valueString = getValueString(bSrc, valueStartPos, 5);
                            return (true, 1, valueString);
                        }
                        pos += 4;
                        state &= ~0x08;
                        state |= 0x80;
                    } else {
                        break;
                    }
                } else if (bSrc[pos] == 0x6e) {
                    // null
                    if (pos + 3 >= bSrc.length) {
                        break;
                    }
                    if (bSrc[pos] == 0x6e && bSrc[pos + 1] == 0x75 && bSrc[pos + 2] == 0x6c && bSrc[pos + 3] == 0x6c) {
                        if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                            valueString = getValueString(bSrc, valueStartPos, 4);
                            return (true, 1, valueString);
                        }
                        pos += 3;
                        state &= ~0x08;
                        state |= 0x80;
                    } else {
                        break;
                    }
                } else if (bSrc[pos] == 0x2d || bSrc[pos] == 0x2b || bSrc[pos] >= 0x30  || bSrc[pos] <= 0x39) {
                    // digit
                    valueStartPos = pos;
                    for (uint l = 0; pos + l < bSrc.length; l++) {
                        if (bSrc[pos] == 0x2d || bSrc[pos] == 0x2b || bSrc[pos] >= 0x30  || bSrc[pos] <= 0x39) {
                            l++;
                            continue;
                        }
                        break;
                    }
                    valueLen = (pos + l) - valueStartPos;
                    if (isKeymatch(findKey, bSrc, keyStartPos, keyLen)) {
                        valueString = getValueString(bSrc, valueStartPos, valueLen);
                        return (true, 1, valueString);
                    }
                    pos += (l - 1);
                    state &= ~0x08;
                    state |= 0x80;
                } else {
                    // unsupported format
                    break;
                }
            } else if ((state & 0x80) != 0) {
                if (bSrc[pos] == 0x2c) {
                   state &= ~0x80;
                   state |= 0x04;
                } else {
                    // unsupported format
                    break;
                }
            }
            pos++;
        }
        return (false, 0, false, "");
    }
    
    
   
    function getString(string src, string key) internal returns (bool found, bool isNull, string value) {
        
    }

    function getInt(string src, string key) internal returns (bool found, bool isNull, string value) {
        
    }

    function getBool(string src, string key) internal returns (bool found, bool isNull, string value) {
        
    }
    
    
}

