pragma solidity ^0.4.14;

import "./TokenDB.sol";
import "./EticketDB.sol";

contract EticketView is EticketViewInterface {
    
    address eticketDB;
    
    function Eticket(address _tokenDB, address _eticketDB) Token(_tokenDB) {
        require(_eticketDB != address(0));
        eticketDB = _eticketDB;
        name = "EticketToken";
        decimals = 18;
        symbol = "ETT";
    }
    
}
