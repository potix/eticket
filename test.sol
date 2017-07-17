pragma solidity ^0.4.8;

/** とりあえず、チュートリアル **/

contract ERC20Interface {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Test is ERC20Interface {
    uint storedData;
    function set(uint x) {
        storedData = x;
    }
    function get() constant returns (uint retVal) {
        return storedData;
    }
    

    mapping (address => uint) balances;
    function Test() {
        minter = msg.sender;
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    
    address minter;
    event Send(address from, address to, uint value);

    function mint(address owner, uint amount) {
        if (msg.sender != minter) return;
        balances[owner] += amount;
    }
    function send(address receiver, uint amount) {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Send(msg.sender, receiver, amount);
    }
    function queryBalance(address addr) constant returns (address ad, uint balance) {
        return (addr, balances[addr]);
    }
    
    
    string public constant symbol = "TETEST";
    string public constant name = "Test Fixed Supply Token";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 1000000000;
    address public owner;
    modifier onlyOwner() {
          require(msg.sender == owner);
          _;
    }
    
    mapping(address => mapping (address => uint256)) allowed;
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 amount) returns (bool success) {
        if (balances[msg.sender] >= amount 
            && amount > 0
            && balances[_to] + amount > balances[_to]) {
            balances[msg.sender] -= amount;
            balances[_to] += amount;
            Transfer(msg.sender, _to, amount);
            return true;
        } else {
            return false;
        }
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 amount
    ) returns (bool success) {
        if (balances[_from] >= amount
        && allowed[_from][msg.sender] >= amount
            && amount > 0
            && balances[_to] + amount > balances[_to]) {
            balances[_from] -= amount;
            allowed[_from][msg.sender] -= amount;
            balances[_to] += amount;
            Transfer(_from, _to, amount);
            return true;
        } else {
            return false;
        }
    }
    function approve(address _spender, uint256 amount) returns (bool success) {
        allowed[msg.sender][_spender] = amount;
        Approval(msg.sender, _spender, amount);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}
