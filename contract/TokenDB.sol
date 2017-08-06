pragma solidity ^0.4.14;

import "./ContractAllowable.sol";
import "./SafeMath.sol";

contract TokenDB is ContractAllowable {
    using SafeMath for uint256;    

    bytes32 name;
    bytes32 symbol;
    uint decimals = 18;
    uint256 totalSupply = 0;
    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    
    function getName() constant returns (bytes32) {
        return name;
    }

    function setName(bytes32 _name) onlyAllowContractOrOwner {
        name = _name;        
    }

    function getSymbol() constant returns (bytes32) {
        return symbol;
    }

    function setSymbol(bytes32 _symbol) onlyAllowContractOrOwner {
        symbol = _symbol;        
    }

    function getDecimals() constant returns (uint) {
        return decimals;
    }

    function setDecimals(uint _decimals) onlyAllowContractOrOwner {
        decimals = _decimals;        
    }
    
    function getTotalSupply() constant returns (uint256) {
        return totalSupply;
    }
    
    function initTotalSupply(address _owner, uint256 _totalSupply) onlyAllowContractOrOwner {
        require(_owner == owner && totalSupply == 0);
        totalSupply = _totalSupply;
        balances[_owner] = _totalSupply;
    }
    
    function addTotalSupply(address _owner, uint256 _addSupply) onlyAllowContractOrOwner {
        require(_owner == owner);
        totalSupply = totalSupply.add(_addSupply);
        balances[_owner] = balances[_owner].add(_addSupply);
    }
    
    function subTotalSupply(address _owner, uint256 _subSupply) onlyAllowContractOrOwner {
        require(_owner == owner);
        totalSupply = totalSupply.sub(_subSupply);
        balances[_owner] = balances[_owner].sub(_subSupply);
    }
    
    function getBalance(address _address) constant returns (uint256) {
        return balances[_address];
    }
    
    function addBalance(address _address, uint256 _value) onlyAllowContractOrOwner {
        balances[_address] = balances[_address].add(_value);
    }
    
    function subBalance(address _address, uint256 _value) onlyAllowContractOrOwner {
        balances[_address] = balances[_address].sub(_value);
    }  
    
    function getAllowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function setAllowance(address _owner, address _spender, uint256 _value) onlyAllowContractOrOwner {
        allowed[_owner][_spender] = _value;
    }
    
    function subAllowance(address _owner, address _spender, uint256 _value) onlyAllowContractOrOwner {
        allowed[_owner][_spender] = allowed[_owner][_spender].sub(_value);
    }
}
