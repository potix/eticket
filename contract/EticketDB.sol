pragma solidity ^0.4.14;

import "./ContractAllowable.sol";

contract EticketDB is ContractAllowable {
    mapping(bytes32 => uint256) ids;

    function getLastId(bytes32 key) constant returns (uint256) {
        return ids[key];
    }
    
    function getAndIncrementId(bytes32 key) onlyAllowContractOrOwner returns (uint256) {
        var _v = ids[key];
        ids[key] = _v + 1;
        return (_v, true);
    }
    
    function getIdArray(bytes32 key) constant returns (uint256[]) {
        var _lastId = ids[key];
        uint256[] memory _newIds = new uint256[](_lastId);
        for (uint256 i = 0; i < _lastId; i++) {
            _newIds[i] = i;
        }
        return _newIds;
    }

    mapping(bytes32 => string) strings;

    function setString(bytes32 key, string value) onlyAllowContractOrOwner returns (bool) {
        strings[key] = value;
        return true;
    }

    function getString(bytes32 key) constant returns (string) {
        return strings[key];
    }
}
