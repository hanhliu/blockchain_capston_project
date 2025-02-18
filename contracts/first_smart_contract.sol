// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
    uint public count;
    uint private test;

    

    function increment() public {
        count += 1;
    }
}
