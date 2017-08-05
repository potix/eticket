pragma solidity ^0.4.14;

import "./EticketDB.sol";

library EticketLibrary {
    
    function createUser(address _eticketDB, string _name, string _email, string _profile) returns (uint256, bool) {
            // userId
            // user.name
            // user.email
            // user.pprofile
            var userId = EticketDB(_eticketDB).getAndIncrementId(sha3("userId"));
            EticketDB(_eticketDB).setString(sha3("user.name", userId));
            EticketDB(_eticketDB).setString(sha3("user.email", userId));
            EticketDB(_eticketDB).setString(sha3("user.profile", userId));
    }


    
}
