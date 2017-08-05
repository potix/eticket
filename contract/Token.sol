pragma solidity ^0.4.14;

import "./TokenInterface.sol";
import "./TokenLibrary.sol";
import "./Ownable.sol";

contract Token is ERC20Interface, TokenInterface, Ownable {
    using TokenLibrary for address;

    string public name;
    string public symbol;
    uint public decimals = 18;
    address public tokenDB;
    
    function Token(address _tokenDB) {
        require(_tokenDB != address(0));
        tokenDB = _tokenDB;
    }

    function totalSupply() constant returns (uint256) {
        return tokenDB.totalSupply();    
    }

    function initSupply(uint256 _totalSupply) onlyOwner returns  (bool) {
        return tokenDB.initSupply(_totalSupply);    
    }
    
    function increaseSupply(uint256 _supply) onlyOwner returns  (bool) {
        var _success = tokenDB.increaseSupply(_supply);
        Mint(msg.sender, _supply);
        return _success;
    }
    
    function decreaseSupply(uint256 _supply) onlyOwner returns  (bool) {
        var _success = tokenDB.decreaseSupply(_supply);    
        Burn(msg.sender, _supply);
        return _success;
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        var _success = tokenDB.transfer(_to, _value);
        Transfer(msg.sender, _to, _value);
        return _success;
    }
    
    function balanceOf(address _owner) constant returns (uint256) {
        return tokenDB.balanceOf(_owner);    
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _success = tokenDB.transferFrom(_from, _to, _value);
        Transfer(_from, _to, _value);
        return _success;
    }
    
    function approve(address _spender, uint256 _value) returns (bool) {
        var _success = tokenDB.approve(_spender, _value);
        Approval(msg.sender, _spender, _value);
        return _success;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return tokenDB.allowance(_owner, _spender);
    }
}

