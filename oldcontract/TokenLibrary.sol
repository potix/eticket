pragma solidity ^0.4.14;

import "./SafeMath.sol";
import "./TokenDB.sol";

library TokenLibrary {
  /**
  * @dev Get total supply
  * @param _tokenDB The Token database contract.
  * @return The total supply.
  */
  function totalSupply(address _tokenDB) internal constant returns (uint256) {
      TokenDB(_tokenDB).getTotalSupply();    
  }

  /**
  * @dev init total supply
  * @param _tokenDB The Token database contract.
  * @param _totalSupply The total supply.
  */
  function initSupply(address _tokenDB, uint256 _totalSupply) internal returns (bool) {
      TokenDB(_tokenDB).initTotalSupply(msg.sender, _totalSupply);
      return true;
  }
  
  /**
  * @dev add total supply
  * @param _tokenDB The Token database contract.
  * @param _supply The additinal supply.
  */
  function increaseSupply(address _tokenDB, uint256 _supply) internal returns (bool) {
      TokenDB(_tokenDB).addTotalSupply(msg.sender, _supply);
      return true;
  }
  
    /**
  * @dev sub total supply
  * @param _tokenDB The Token database contract.
  * @param _supply The subtractional supply.
  */
  function decreaseSupply(address _tokenDB, uint256 _supply) internal returns (bool) {
      TokenDB(_tokenDB).subTotalSupply(msg.sender, _supply);
      return true;
  }
  
  /**
  * @dev transfer token for a specified address
  * @param _tokenDB The Token database contract.
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _tokenDB, address _to, uint256 _value) internal returns (bool) {
    TokenDB(_tokenDB).subBalance(msg.sender, _value);
    TokenDB(_tokenDB).addBalance(_to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _tokenDB The Token database contract.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _tokenDB, address _owner) internal constant returns (uint256 balance) {
    return TokenDB(_tokenDB).getBalance(_owner);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _tokenDB The Token database contract.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _tokenDB, address _from, address _to, uint256 _value) internal returns (bool) {
    TokenDB(_tokenDB).addBalance(_to, _value);
    TokenDB(_tokenDB).subBalance(_from, _value);
    TokenDB(_tokenDB).subAllowance(_from, msg.sender, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _tokenDB The Token database contract.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _tokenDB, address _spender, uint256 _value) internal returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (TokenDB(_tokenDB).getAllowance(msg.sender, _spender) == 0));
    TokenDB(_tokenDB).setAllowance(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _tokenDB The Token database contract.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _tokenDB, address _owner, address _spender) internal constant returns (uint256 remaining) {
    return TokenDB(_tokenDB).getAllowance(_owner, _spender);
  }
}
