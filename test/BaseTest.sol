// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TestPlus as Test } from "./TestPlus.sol";

contract BaseTest is Test {
    function setUp() public virtual { }
}
