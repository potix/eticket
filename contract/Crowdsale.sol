pragma solidity ^0.4.14;

import './EticketToken.sol';
import './SafeMath.sol';

/**
 * @title Crowdsale 
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end block, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet 
 * as they arrive.
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // start and end block where investments are allowed (both inclusive)
    uint256 public startBlock;
    uint256 public endBlock;
    // how many token units a buyer gets per wei
    uint256 public rate;
    // amount of raised money in wei
    uint256 public weiRaised;
    
    // The token being sold
    address mintableToken;
    // address where funds are collected
    address wallet;
    
    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */ 
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    function Crowdsale(uint256 _startBlock, uint256 _endBlock, uint256 _rate, address _mintableToken, address _wallet) {
        require(_startBlock >= block.number);
        require(_endBlock >= _startBlock);
        require(_rate > 0);
        require(_mintableToken != 0x0);
        require(_wallet != 0x0);
        mintableToken = _mintableToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        rate = _rate;
        wallet = _wallet;
    }

    function removeMintableToken() onlyOwner returns (bool) {
        mintableToken = address(0);
        return true;
    }

    // fallback function can be used to buy tokens
    function () payable {
        buyTokens(msg.sender);
    }
    
    // low level token purchase function
    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0 && validPurchase());
        uint256 weiAmount = msg.value;
        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);
        // update state
        weiRaised = weiRaised.add(weiAmount);
        require(Eticket(mintableToken).mint(beneficiary, tokens));
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
        forwardFunds();
    }
    
    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        uint256 current = block.number;
        return (current >= startBlock && current <= endBlock) && (msg.value != 0);
    }
    
    // @return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        return block.number > endBlock;
    }
}

