pragma solidity ^0.4.14;

import "./ContractAllowable.sol";
import "./SafeMath.sol";

contract TicketDB is ContractAllowable {
    using SafeMath for uint256;  

    // 発行したidを格納する領域        
    mapping(bytes32 => uint256) ids;

    function getLastId(bytes32 _key) constant returns (uint256) {
        return ids[_key];
    }
    
    function getAndIncrementId(bytes32 _key) onlyAllowContractOrOwner returns (uint256) {
        var _v = ids[_key];
        ids[_key] = ids[_key].add(1);
        return _v;
    }
    
    function getIds(bytes32 _key, uint256 _start, uint256 _end) constant returns (uint256[]) {
        var _lastId = ids[_key];
        uint256[] memory _newIds = new uint256[](_lastId);
        for (uint256 i = _start; i < _lastId && i < _end; i++) {
            _newIds[i] = i;
        }
        return _newIds;
    }

    // addressからidへのマッピングを格納する領域
    mapping(address => uint256) idMap;
    
    function setIdMap(address _key, uint256 _value) onlyAllowContractOrOwner {
        idMap[_key] = _value;
    }

    function getIdMap(address _key) constant returns (uint256) {
        return idMap[_key];
    }
    
    // addressを格納する領域
    mapping(bytes32 => address) addresses;

    function setAddress(bytes32 _key, address _value) onlyAllowContractOrOwner {
        addresses[_key] = _value;
    }

    function getAddress(bytes32 _key) constant returns (address) {
        return addresses[_key];
    }

    // 文字列を格納する領域
    mapping(bytes32 => string) strings;

    function setString(bytes32 _key, string _value) onlyAllowContractOrOwner {
        strings[_key] = _value;
    }

    function getString(bytes32 _key) constant returns (string) {
        return strings[_key];
    }
    
    // uint32の値を格納する領域
    mapping(bytes32 => uint32) uint32Values;

    function setUint32(bytes32 _key, uint32 _value) onlyAllowContractOrOwner {
        uint32Values[_key] = _value;
    }

    function getUint32(bytes32 _key) constant returns (uint32) {
        return uint32Values[_key];
    }
    
    // uint256の値を格納する領域
    mapping(bytes32 => uint256) uint256Values;

    function incrementUint256(bytes32 _key) onlyAllowContractOrOwner {
        uint256Values[_key] = uint256Values[_key].add(1);
    }

    function addUint256(bytes32 _key, uint256 _value) onlyAllowContractOrOwner {
        uint256Values[_key] = uint256Values[_key].add(_value);
    }
    
    function subUint256(bytes32 _key, uint256 _value) onlyAllowContractOrOwner {
        uint256Values[_key] = uint256Values[_key].sub(_value);
    }  

    function setUint256(bytes32 _key, uint256 _value) onlyAllowContractOrOwner {
        uint256Values[_key] = _value;
    }

    function getUint256(bytes32 _key) constant returns (uint256) {
        return uint256Values[_key];
    }




    // 情報取得系処理
    // solidityの制約でデータ取得が困難なな場合があるので一旦DBから直接読むようにしておく
    // metoropolisアップデートで解消されると思われるので、解消したらticketDBに移す
}




