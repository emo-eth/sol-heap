// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "test/BaseTest.sol";
import { MinHeapArray } from "src/MinHeap.sol";

contract MinHeapTest is BaseTest {
    MinHeapArray.Heap private heap;

    using MinHeapArray for MinHeapArray.Heap;

    function setUp() public virtual override { }

    function testInsertPeekAndSize() public {
        for (uint256 i = 1; i < 255; i++) {
            heap.insert(i);
            assertEq(1, heap.peek());
            assertEq(i, heap.size());
        }
    }

    function testPop() public {
        for (uint256 i = 1; i < 255; i++) {
            heap.insert(i);
        }

        for (uint256 i = 1; i < 255; i++) {
            assertEq(i, heap.pop());
        }
    }

    function testFuzz(uint256[] memory arr) public {
        if (arr.length == 0) {
            arr = new uint256[](1);
            arr[0] = 1;
        }

        for (uint256 i = 0; i < arr.length; i++) {
            heap.insert(arr[i]);
        }

        uint256[] memory sorted = new uint256[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            sorted[i] = heap.pop();
        }

        for (uint256 i = 1; i < arr.length; i++) {
            assertTrue(sorted[i - 1] <= sorted[i]);
        }
    }

    function min(uint256[] memory arr) internal pure returns (uint256) {
        uint256 _min = arr[0];
        for (uint256 i = 1; i < arr.length; i++) {
            if (arr[i] < _min) {
                _min = arr[i];
            }
        }
        return _min;
    }
}
