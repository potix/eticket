pragma solidity ^0.4.14;

import "./Ownable.sol";

contract ContractAllowable is Ownable {
    mapping(address => bool) allowContracts;
    
    function addAllowContracts(address _allowContract) onlyOwner returns (bool) {
        if (_allowContract == address (0)) {
            return false;
        }
        allowContracts[_allowContract] = true;
        return true;
    }
    
    function deleteAllowContracts(address _allowContract) onlyOwner returns (bool) {
        delete allowContracts[_allowContract];
        return true;
    } 
    
    modifier onlyAllowContractOrOwner() {
        require(allowContracts[msg.sender] == true || msg.sender == owner);
        _;
    }
}
