pragma solidity ^0.4.14;

import "./TokenInterface.sol";
import "./ContractAllowable.sol";
import "./TokenDB.sol";
import "./Converter.sol";

contract Token is ERC20Interface, TokenInterface, ContractAllowable {
    address public tokenDB;

    function Token(address _tokenDB) {
        require(_tokenDB != 0x0);
        tokenDB = _tokenDB;
    }
    
    function removeTokenDB() onlyOwner returns (bool) {
        tokenDB = address(0);
        return true;
    }

    /**
     * @dev Get name
     * @return The name.
     */
    function name() constant returns (string) {
        return Converter.bytes32ToString(TokenDB(tokenDB).getName());    
    }

    /**
     * @dev Set name
     * @param _name The name.
     */
    function setName(string _name) onlyOwner returns (bool) {
        TokenDB(tokenDB).setName(Converter.stringToBytes32(_name));
        return true;
    }

    /**
     * @dev Get symbol
     * @return The symbol.
     */
    function symbol() constant returns (string) {
        return Converter.bytes32ToString(TokenDB(tokenDB).getSymbol());    
    }

    /**
     * @dev Set symbol
     * @param _symbol The symbol.
     */
    function setSymbol(string _symbol) onlyOwner returns (bool) {
        TokenDB(tokenDB).setSymbol(Converter.stringToBytes32(_symbol));
        return true;
    }

    /**
     * @dev Get decimals
     * @return The decimals.
     */
    function decimals() constant returns (uint) {
        return TokenDB(tokenDB).getDecimals();    
    }

    /**
     * @dev Set decimals
     * @param _decimals The decimals.
     */
    function setDecimals(uint _decimals) onlyOwner returns (bool) {
        TokenDB(tokenDB).setDecimals(_decimals);
        return true;
    }

    /**
     * @dev Get total supply
     * @return The total supply.
     */
    function totalSupply() constant returns (uint256) {
        return TokenDB(tokenDB).getTotalSupply();    
    }

    /**
     * @dev Increase total supply
     * @param _amount The additinal supply amount.
     */
    function increaseSupply(uint256 _amount) onlyOwner returns  (bool) {
        TokenDB(tokenDB).addTotalSupply(_amount);
        TokenDB(tokenDB).addBalance(msg.sender, _amount);
        return true;
    }

    /**
     * @dev decrease total supply
     * @param _amount The subtractional supply amount.
     */
    function decreaseSupply(uint256 _amount) onlyOwner returns  (bool) {
        TokenDB(tokenDB).subTotalSupply(_amount);
        TokenDB(tokenDB).subBalance(msg.sender, _amount);
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) returns (bool) {
        require(_to != address(0));
        TokenDB(tokenDB).subBalance(msg.sender, _value);
        TokenDB(tokenDB).addBalance(_to, _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of. 
     * @return An uint256 representing the amount owned by the passed address.
     */   
    function balanceOf(address _owner) constant returns (uint256) {
        return TokenDB(tokenDB).getBalance(_owner);   
    }
    
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(_from != address(0) && _to != address(0));
        TokenDB(tokenDB).addBalance(_to, _value);
        TokenDB(tokenDB).subBalance(_from, _value);
        TokenDB(tokenDB).subAllowance(_from, msg.sender, _value);
        Transfer(_from, _to, _value);
        return true;
    }
 
    /**
    * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */    
    function approve(address _spender, uint256 _value) returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (TokenDB(tokenDB).getAllowance(msg.sender, _spender) == 0));
        TokenDB(tokenDB).setAllowance(msg.sender, _spender, _value);
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still available for the spender.
     */    
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return TokenDB(tokenDB).getAllowance(_owner, _spender);
    }
    
    /**
     * @dev Get minting
     * @return The minting.
     */
    function minting() constant returns (bool) {
        return TokenDB(tokenDB).getMinting();
    }
    
    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyAllowContractOrOwner returns (bool) {
        require(TokenDB(tokenDB).getMinting());
        TokenDB(tokenDB).addTotalSupply(_amount);
        TokenDB(tokenDB).addBalance(_to, _amount);
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to enable minting new tokens.
     * @return True if the operation was successful.
     */
    function enableMinting() onlyOwner returns (bool) {
        TokenDB(tokenDB).enableMinting();
        EnableMinting();
        return true;
    }

    /**
     * @dev Function to disable minting new tokens.
     * @return True if the operation was successful.
     */
    function disableMinting() onlyAllowContractOrOwner returns (bool) {
        TokenDB(tokenDB).disableMinting();
        DisableMinting();
        return true;
    }
}


