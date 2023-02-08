// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TestPlus as Test } from "solady-test/utils/TestPlus.sol";
import {
    HeapMetadata, HeapMetadataType
} from "../../src/lib/HeapMetadataType.sol";

contract HeapMetadataTypeTest is Test {
    function testCreateHeapMetadata(uint32 root, uint32 totalNodes) public {
        HeapMetadata heapMetadata =
            HeapMetadataType.createHeapMetadata(root, totalNodes);
        assertEq(heapMetadata.root(), root, "root incorrect");
        assertEq(heapMetadata.totalNodes(), totalNodes, "totalNodes incorrect");
        (uint256 _root, uint256 _totalNodes) = heapMetadata.unpack();
        assertEq(_root, root, "unpacked root incorrect");
        assertEq(_totalNodes, totalNodes, "unpacked totalNodes incorrect");
    }

    function testCreateHeapMetadata() public {
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata(1, 2);
        assertEq(heapMetadata.root(), 1, "root incorrect");
        assertEq(heapMetadata.totalNodes(), 2, "totalNodes incorrect");
        (uint256 _root, uint256 _totalNodes) = heapMetadata.unpack();
        assertEq(_root, 1, "unpacked root incorrect");
        assertEq(_totalNodes, 2, "unpacked totalNodes incorrect");
    }

    function testSafeCreateHeapMetadata(uint32 root, uint32 totalNodes)
        public
    {
        HeapMetadata heapMetadata =
            HeapMetadataType.safeCreateHeapMetadata(root, totalNodes);
        assertEq(heapMetadata.root(), root, "root incorrect");
        assertEq(heapMetadata.totalNodes(), totalNodes, "totalNodes incorrect");
        (uint256 _root, uint256 _totalNodes) = heapMetadata.unpack();
        assertEq(_root, root, "unpacked root incorrect");
        assertEq(_totalNodes, totalNodes, "unpacked totalNodes incorrect");
    }

    function testSafeCreateHeapMetadata() public {
        HeapMetadata heapMetadata =
            HeapMetadataType.safeCreateHeapMetadata(1, 2);
        assertEq(heapMetadata.root(), 1, "root incorrect");
        assertEq(heapMetadata.totalNodes(), 2, "totalNodes incorrect");
        (uint256 _root, uint256 _totalNodes) = heapMetadata.unpack();
        assertEq(_root, 1, "unpacked root incorrect");
        assertEq(_totalNodes, 2, "unpacked totalNodes incorrect");
    }

    function testSetters() public {
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata(1, 2);
        HeapMetadata _heapMetadata = heapMetadata.setRoot(3);
        _assertAll(_heapMetadata, 3, 2);
        _heapMetadata = heapMetadata.setTotalNodes(4);
        _assertAll(_heapMetadata, 1, 4);
    }

    function _assertAll(
        HeapMetadata heapMetadata,
        uint32 root,
        uint32 totalNodes
    ) internal {
        assertEq(heapMetadata.root(), root, "root incorrect");
        assertEq(heapMetadata.totalNodes(), totalNodes, "totalNodes incorrect");
        (uint256 _root, uint256 _totalNodes) = heapMetadata.unpack();
        assertEq(_root, root, "unpacked root incorrect");
        assertEq(_totalNodes, totalNodes, "unpacked totalNodes incorrect");
    }
}
