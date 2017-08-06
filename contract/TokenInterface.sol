pragma solidity ^0.4.14;

contract ERC20Interface {
    function totalSupply() constant returns (uint256);
    function balanceOf(address _owner) constant returns (uint256);
    function transfer(address _to, uint256 _value) returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);
    function approve(address _spender, uint256 _value) returns (bool);
    function allowance(address _owner, address _spender) constant returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// constract ERC667Interface {
//     function approveAndCall(address receiver, uint amount, bytes data) returns (bool success);
//     function receiveApproval(address from, uint256 amount, address token, bytes data) returns (bool success)
// }

contract TokenInterface {
    function name() constant returns (string);
    function symbol() constant returns (string);
    function decimals() constant returns (uint);
    function setName(string _name) returns (bool);
    function setSymbol(string _symbol) returns (bool);
    function setDecimals(uint _decimals) returns (bool);
    function initSupply(uint256 _supply) returns (bool); 
    function increaseSupply(uint256 _supply) returns (bool); 
    function decreaseSupply(uint256 _supply) returns (bool); 
    event Mint(address indexed _owner, uint256 _value);
    event Burn(address indexed _owner, uint256 _value);
}

