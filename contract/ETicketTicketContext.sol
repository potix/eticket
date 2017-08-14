pragma solidity ^0.4.14;

import "./Validation.sol";
import "./State.sol";
import "./ETicketUser.sol";
import "./ETicketEvent.sol";
import "./ETicketTicketGroup.sol";
import "./ETicketTransaction.sol";
import "./ETicketDB.sol";
import "./TokenDB.sol";

library ETicketTicketContext {
    using State for uint32;  
    using SafeMath for uint256;

    // == create/modify ==
    // [ticketContexts]
    // ticketContextId
    // ticketContexts <ticketContextId> userId
    // ticketContexts <ticketContextId> eventId
    // ticketContexts <ticketContextId> ticketGroupId
    // ticketContexts <ticketContextId> transactionId
    // ticketContexts <ticketContextId> transactionOwner
    // ticketContexts <ticketContextId> eventOwner
    // ticketContexts <ticketContextId> reservedUrl
    // ticketContexts <ticketContextId> enteredUrl
    // ticketContexts <ticketContextId> cashBackPrice
    // ticketContexts <ticketContextId> enterCode
    // ticketContexts <ticketContextId> serialNumber
    // ticketContexts <ticketContextId> BuyPrice
    // ticketContexts <ticketContextId> salePrice
    // ticketContexts <ticketContextId> state [ 0x10 CACHEBACKED, 0x01 SALABLE, 0x02 UNSALABLE, 0x04 ENTERED ]
    // == related == 
    // [transaction]
    // transactions <ticketContextId> buyTickets
    // transactions <ticketContextId> reservedTickets
    // transactions <ticketContextId> state [ 0x01 SALABLE 0x02 UNSALABLE ]
    // [ticket group]
    // ticketGroups <ticketGroupId> lastSerialNumber
    // ticketGroups <ticketGroupId> state [ 0x01 SALE 0x02 STOP ]
    // [event]
    // events <eventId> state [ 0x01 CREATE, 0x02 SALE, 0x04 OPEN, 0x08 READY,  0x10 STOP, 0x20 CLOSE, 0x40 COLLECT ]
    
    function createTicketcontext() {
        var _userInfo = ETicketUser.getSenderUserInfo(_ticketDB);
        var _transactionInfo = getOwnerTransationInfo(_ticketDB, _userInfo.userId, _transactionId);
        
    }
    
}
