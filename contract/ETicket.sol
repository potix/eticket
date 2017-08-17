pragma solidity ^0.4.14;

import "./ETicketInterface.sol";
import "./Token.sol";
import "./State.sol";
import "./ETicketTicketContext.sol";
import "./ETicketTransaction.sol";
import "./ETicketTicketGroup.sol";
import "./ETicketEvent.sol";
import "./ETicketUser.sol";
import "./TokenDB.sol";
import "./ETicketDB.sol";

contract ETicket is ETicketInterface, Token {
    address ticketDB;
    
    function ETicket(address _tokenDB, address _ticketDB) Token(_tokenDB) {
        require(_ticketDB != 0x0);
        ticketDB = _ticketDB;
    }

    function removeTicketDB() onlyOwner returns (bool) {
        ticketDB = address(0);
        return true;
    }
    
    // user

    function createUser(string _name, string _email, string _profile) returns (uint256) {
        return ETicketUser.createUser(ETicketDB(ticketDB), _name, _email, _profile);
    }

    function setUserName(string _name) returns (bool) {
        return ETicketUser.setUserName(ETicketDB(ticketDB), _name);
    }

    function setUserEmail(string _email) returns (bool) {
       return ETicketUser.setUserEmail(ETicketDB(ticketDB), _email);
    }

    function setUserProfile(string _profile) returns (bool) {
       return ETicketUser.setUserProfile(ETicketDB(ticketDB), _profile);
    }

    // event

    function createEventWithSalable(
        string _name, 
        string _country, 
        string _description, 
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashBackOracleUrl
        )  returns (uint256) {
        return ETicketEvent.createEventWithSalable(ETicketDB(ticketDB), _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashBackOracleUrl);
    }

    function createEventWithUnsalable(
        string _name, 
        string _country, 
        string _description, 
        string _reserveOracleUrl,
        string _enterOracleUrl,
        string _cashBackOracleUrl
        )  returns (uint256) {
        return ETicketEvent.createEventWithUnsalable(ETicketDB(ticketDB), _name, _country, _description, _reserveOracleUrl, _enterOracleUrl, _cashBackOracleUrl);

    }

    function setEventName(uint256 _eventId, string _name) returns (bool) {
        return ETicketEvent.setEventName(ETicketDB(ticketDB), _eventId, _name);
    }

    function setEventCountry(uint256 _eventId, string _country) returns (bool) {
        return ETicketEvent.setEventCountry(ETicketDB(ticketDB), _eventId, _country);
    }

    function setEventDescription(uint256 _eventId, string _description)  returns (bool) {
        return ETicketEvent.setEventDescription(ETicketDB(ticketDB), _eventId, _description);
    }

    function setEventReserveOracleUrl(uint256 _eventId, string _reserveOracleUrl)  returns (bool) {
        return ETicketEvent.setEventReserveOracleUrl(ETicketDB(ticketDB), _eventId, _reserveOracleUrl);
    }

    function setEventEnterOracleUrl(uint256 _eventId, string _enterOracleUrl)  returns (bool) {
        return ETicketEvent.setEventEnterOracleUrl(ETicketDB(ticketDB), _eventId, _enterOracleUrl);
    }

    function setEventCashBackOracleUrl(uint256 _eventId, string _cashbackOracleUrl) returns (bool) {
        return ETicketEvent.setEventCashBackOracleUrl(ETicketDB(ticketDB), _eventId, _cashbackOracleUrl);
    }

    function saleEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.saleEvent(ETicketDB(ticketDB), _eventId);
    }

    function openEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.openEvent(ETicketDB(ticketDB), _eventId);
    }

    function readyEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.readyEvent(ETicketDB(ticketDB), _eventId);
    }

    function stopEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.stopEvent(ETicketDB(ticketDB), _eventId);
    }

    function closeEvent(uint256 _eventId) returns (bool) { 
        return ETicketEvent.closeEvent(ETicketDB(ticketDB), _eventId);
    }

   function collectEvent(uint256 _eventId) returns (bool) {
        return ETicketEvent.collectEvent(ETicketDB(ticketDB), TokenDB(tokenDB), _eventId);
    }

    // ticketGroup

    function createTicketGroupWithSalable(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) returns (uint256) {
        return ETicketTicketGroup.createTicketGroupWithSalable(ETicketDB(ticketDB), _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
    }
    
    function createTicketGroupWithUnsalable(
        uint256 _eventId, 
        string _name, 
        string _description,
        uint256 _supplyTickets,
        uint256 _maxPrice,
        uint256 _price
        ) returns (uint256) {
        return ETicketTicketGroup.createTicketGroupWithUnsalable(ETicketDB(ticketDB), _eventId, _name, _description, _supplyTickets, _maxPrice, _price);
    }
    
    function setTicketGroupName(uint256 _ticketGroupId, string _name) returns (bool) {
        return ETicketTicketGroup.setTicketGroupName(ETicketDB(ticketDB), _ticketGroupId, _name);
    }
    
    function setTicketGroupDescription(uint256 _ticketGroupId, string _description) returns (bool) {
        return ETicketTicketGroup.setTicketGroupDescription(ETicketDB(ticketDB), _ticketGroupId, _description);
    }

    function addTicketGroupSupplyTickets(uint256 _ticketGroupId,  uint256 _supplyTickets) returns (bool) {
        return ETicketTicketGroup.addTicketGroupSupplyTickets(ETicketDB(ticketDB), _ticketGroupId, _supplyTickets);
    }

    function subTicketGroupSupplyTickets(uint256 _ticketGroupId, uint256 _supplyTickets) returns (bool) {
        return ETicketTicketGroup.subTicketGroupSupplyTickets(ETicketDB(ticketDB), _ticketGroupId, _supplyTickets);
    }

    function setTicketGroupMaxPrice(uint256 _ticketGroupId, uint256 _maxPrice) returns (bool) {
        return ETicketTicketGroup.setTicketGroupMaxPrice(ETicketDB(ticketDB), _ticketGroupId, _maxPrice);
    }

    function setTicketGroupPrice(uint256 _ticketGroupId, uint256 _price)  returns (bool) {
        return ETicketTicketGroup.setTicketGroupPrice(ETicketDB(ticketDB), _ticketGroupId, _price);
    }

    function setTicketGroupSalable(uint256 _ticketGroupId) returns (bool) {
        return ETicketTicketGroup.setTicketGroupSalable(ETicketDB(ticketDB), _ticketGroupId);
    }
    
    function setTicketGroupUnsalable(uint256 _ticketGroupId) returns (bool) {
        return ETicketTicketGroup.setTicketGroupUnsalable(ETicketDB(ticketDB), _ticketGroupId);
    }

    // transaction
    
    function buyTransaction(uint256 _ticketGroupId, uint256 _amount) returns (uint256) {
        return ETicketTransaction.buyTransaction(ETicketDB(ticketDB), TokenDB(tokenDB), _ticketGroupId, _amount); 
    }
        
    function setTransactionSalable(uint256 _transactionId) returns (bool) {
        return ETicketTransaction.setTransactionSalable(ETicketDB(ticketDB), _transactionId); 
    }
    
    function setTransactionUnsalable(uint256 _transactionId) returns (bool) {
        return ETicketTransaction.setTransactionUnsalable(ETicketDB(ticketDB), _transactionId); 
    }
    
    function buyTransactionFromBuyer(uint256 _ticketGroupId, uint256 _amount) returns (uint256) {
        return ETicketTransaction.buyTransactionFromBuyer(ETicketDB(ticketDB), TokenDB(tokenDB), _ticketGroupId, _amount); 
    }  
   
    function cancelTransaction(uint256 _ticketGroupId, uint256 _amount) returns (bool) {
        return ETicketTransaction.cancelTransaction(ETicketDB(ticketDB), TokenDB(tokenDB), _ticketGroupId, _amount); 
    }  
   
    // ticketContext  

    function createTicketcontext(uint256 _transactionId, uint256 _amount) returns (uint256[]) { 
        return ETicketTicketContext.createTicketcontext(ETicketDB(ticketDB), _transactionId, _amount);
    }

    function transferTicketCtx(uint256 _ticketContextId, uint256 _newUserId) returns (bool) { 
        return ETicketTicketContext.transferTicketCtx(ETicketDB(ticketDB), _ticketContextId, _newUserId);
    }

    function setTicketContextSalable(uint256 _ticketContextId) returns (bool)  { 
        return ETicketTicketContext.setTicketContextSalable(ETicketDB(ticketDB), _ticketContextId);
    }
    
    function setTicketContextUnsalable(uint256 _ticketContextId) returns (bool)  { 
        return ETicketTicketContext.setTicketContextUnsalable(ETicketDB(ticketDB), _ticketContextId);
    }

    function buyTicketContext(uint256 _ticketContextId) returns (bool)  { 
        return ETicketTicketContext.buyTicketContext(ETicketDB(ticketDB), TokenDB(tokenDB), _ticketContextId);
    }

    function enterTicketContext(uint256 _ticketContextId) returns (bool)  { 
        return ETicketTicketContext.enterTicketContext(ETicketDB(ticketDB), _ticketContextId);
    }

    function cashBackTicketContext(uint256 _ticketContextId, string _cashBackCode) returns (bool)  { 
        return ETicketTicketContext.cashBackTicketContext(ETicketDB(ticketDB), TokenDB(tokenDB), _ticketContextId, _cashBackCode);
    }

    function refundTicketContext(uint256 _ticketContextId) returns (bool)  { 
        return ETicketTicketContext.refundTicketContext(ETicketDB(ticketDB), TokenDB(tokenDB), _ticketContextId);
    }
}

