library ValueFinder {
    
    
    
    // valueType
    // 1 string
    // 2 bool
    // 3 int
    // 4 null
    
    

    
    function find(string src, string findKey) private returns (bool found, uint valueType, string value) {
        uint pos = 0;
        var bSrc = bytes(src);
        bool objectStart = false;
        bool keyStart = false;
        bool valueStart = false;
        bool keyStringStart = false;
        bool nameSepStart = false;
        bool valueStringStart = false;
        bool valueSepStart = false;

        uint keyStartPos = 0;
        uint keyLen = 0;
        uint valueStartPos = 0;
        uint valueLen = 0;
        
        while (true) {
            if (pos == bSrc.length) {
                break;
            }
            if (!keyStringStart && !valueStringStart) {
                // skip white space
                if (bSrc[pos] == 0x20 || bSrc[pos] == 0x09 || bSrc[pos] == 0x0a || bSrc[pos] == 0x0d) {
                    pos++;
                    continue;
                }
            }
            if (!objectStart) {
                if (bSrc[pos] == 0x7b) {
                    // start object
                    objectStart = true;
                    keyStart = true;
                    pos++;
                    continue;
                } else {
                    // unsupported format
                    break;
                }
            } else if (objectStart) {
                if (bSrc[pos] == 0x7d) {
                    // end object
                    break;
                } else {
                    // unsupported format
                    break;
                }
            } else if (keyStart) {
                // parse value
                if (keyStringStart == false && bSrc[pos] == 0x22) {
                    keyStringStart = true;
                    keyStartPos = pos + 1;
                } else if (keyStringStart == true && bSrc[pos] == 0x22) {
                    keyLen = pos - keyStartPos; 
                    keyStringStart = false;
                    nameSepStart = true;
                } else {
                    // unsupported format
                    break;
                }
            } else if (nameSepStart) {
                if (bSrc[pos] == 0x3a) {
                   nameSepStart = false;
                   valueStart = true;
                } else {
                    // unsupported format
                    break;
                }
            } else if (valueStart) {
                // parse value
                if (valueStringStart == false && bSrc[pos] == 0x22) {
                    valueStringStart = true;
                    valueStartPos = pos + 1;
                } else if (valueStringStart == true && bSrc[pos] == 0x22) {
                    valueLen = pos - valueStartPos; 
                    valueStringStart = false;
                    if (isKeymatch(findKey, keyStartPos, keyLen)) {
                        valueString = getValueString(valueStartPos, valueLen);
                        return (true, 1, valueString);
                    }
                    valueStart = false;
                    valueSepStart = true;
                } else if (bSrc[pos] == 0x74 || bSrc[pos] == 0x66 || bSrc[pos] == 0x6e) {
                    // true/false/null
                    if (bSrc[pos] == 0x74) {
                        // true
                        if (pos + 3 >= bSrc.length) {
                            break;
                        }
                        if (bSrc[pos] == 0x74 && bSrc[pos + 1] == 0x00 && bSrc[pos + 2] == 0x00 && bSrc[pos + 3] == 0x00) {
                            if (isKeymatch(findKey, keyStartPos, keyLen)) {
                                valueString = getValueString(valueStartPos, valueLen);
                                return (true, 1, valueString);
                            }
                            pos += 3;
                            valueStart = false;
                            valueSepStart = true;
                        } else {
                            break;
                        }
                    } else if (bSrc[pos] == 0x66) {
                        // false
                        if (pos + 4 >= bSrc.length) {
                            break;
                        }
                        if (bSrc[pos] == 0x74 && bSrc[pos + 1] == 0x00 && bSrc[pos + 2] == 0x00 && bSrc[pos + 3] == 0x00 && bSrc[pos + 3] == 0x00) {
                            if (isKeymatch(findKey, keyStartPos, keyLen)) {
                                valueString = getValueString(valueStartPos, valueLen);
                                return (true, 1, valueString);
                            }
                            pos += 4;
                            valueStart = false;
                            valueSepStart = true;
                        } else {
                            break;
                        }
                    } else if (bSrc[pos] == 0x6e) {
                        // null
                        if (pos + 3 >= bSrc.length) {
                            break;
                        }
                        if (bSrc[pos] == 0x74 && bSrc[pos + 1] == 0x00 && bSrc[pos + 2] == 0x00 && bSrc[pos + 3] == 0x00) {
                            if (isKeymatch(findKey, keyStartPos, keyLen)) {
                                valueString = getValueString(valueStartPos, valueLen);
                                return (true, 1, valueString);
                            }
                            pos += 3;
                            valueStart = false;
                            valueSepStart = true;
                        } else {
                            break;
                        }
                    } 
                } else if (bSrc[pos] == 0x2d || bSrc[pos] == 0x2b || bSrc[pos] >= 0x30  || bSrc[pos] <= 0x39) {
                    // digit
                    
                    
                    
                } else {
                    // unsupported format
                    break;
                }
            } else if (valueSepStart) {
                if (bSrc[pos] == 0x2c) {
                   valueSepStart = false;
                   keyStart = true;
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
