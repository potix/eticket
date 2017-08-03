pragma solidity ^0.4.11;

contract gasTestMemory {
    
    function mem10() {
        bytes memory v = new bytes(10);        
    }

    function mem100() {
        bytes memory v = new bytes(100);        
    }

    function mem1000() {
        bytes memory v = new bytes(1000);        
    }

    function mem10000() {
        bytes memory v = new bytes(10000);        
    }

    function mem100000() {
        bytes memory v = new bytes(100000);        
    }

    function mem1000000() {
        bytes memory v = new bytes(1000000);        
    }

    function mem10000000() {
        bytes memory v = new bytes(10000000);        
    }

    function mem100000000() {
        bytes memory v = new bytes(100000000);        
    }
    
    function init(bytes b, uint size) private {
        for (uint i = 0; i < size; i++) {
            b[i] = byte(0);
        }
    }
    
    function memInit10() {
        bytes memory v = new bytes(10);        
        init(v, 10);
    }

    function memInit100() {
        bytes memory v = new bytes(100);        
        init(v, 100);
    }

    function memInit1000() {
        bytes memory v = new bytes(1000);        
        init(v, 1000);
    }
    
}

// mem10
//    Transaction cost: 21665 gas. 
//    Execution cost: 393 gas.
// mem100
//    Transaction cost: 21555 gas. 
//    Execution cost: 283 gas.
// mem1000
//    Transaction cost: 21599 gas. 
//    Execution cost: 327 gas.
// mem10000
//    Transaction cost: 21687 gas. 
//    Execution cost: 415 gas.
// mem100000
//    Transaction cost: 21577 gas. 
//    Execution cost: 305 gas.
// mem1000000
//    Transaction cost: 21643 gas. 
//    Execution cost: 371 gas.
// mem10000000
//    Transaction cost: 21621 gas. 
//    Execution cost: 349 gas.
// mem100000000
//    Transaction cost: 21709 gas. 
//    Execution cost: 437 gas.
// memInit10
//    Transaction cost: 23331 gas. 
//    Execution cost: 2059 gas.
// memInit100
//    Transaction cost: 36796 gas. 
//    Execution cost: 15524 gas.
// memInit1000 
//    Transaction cost: 171970 gas. 
//    Execution cost: 150698 gas.


