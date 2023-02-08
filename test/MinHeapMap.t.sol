// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "test/BaseTest.sol";
import { MinHeapMap } from "../src/MinHeapMap.sol";
import { Node, NodeType } from "../src/lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "../src/lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "../src/lib/PointerType.sol";

contract MinHeapMapTest is BaseTest {
    using MinHeapMap for MinHeapMap.Heap;

    MinHeapMap.Heap private heap;
    uint256 nodesSlot;

    function setUp() public virtual override {
        nodesSlot = MinHeapMap._nodesSlot(heap);
    }

    function testUpdateAndGet(uint256 key, uint256 toWrap) public {
        MinHeapMap._update(nodesSlot, key, Node.wrap(toWrap));
        assertEq(Node.unwrap(MinHeapMap._get(nodesSlot, key)), toWrap);
        assertEq(Node.unwrap(heap.nodes[key]), toWrap);
    }

    function testUpdateAndGet() public {
        uint256 key = 69;
        uint256 toWrap = 420;
        MinHeapMap._update(nodesSlot, key, Node.wrap(toWrap));
        assertEq(Node.unwrap(MinHeapMap._get(nodesSlot, key)), toWrap);
        assertEq(Node.unwrap(heap.nodes[key]), toWrap);
    }

    function testPeek() public {
        uint256 value = 69;
        Node rootNode = NodeType.createNode({
            _value: value,
            _left: 0,
            _right: 0,
            _parent: 0
        });
        MinHeapMap._update(nodesSlot, 1, rootNode);
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata({
            _root: 1,
            _size: 1,
            _lastNodeKey: 1,
            _leftmostNodeKey: 1,
            _insertPointer: PointerType.createPointer(1, false)
        });
        heap.heapMetadata = heapMetadata;
        assertEq(MinHeapMap.peek(heap), value);
    }

    function testPeek(uint32 key, uint160 value) public {
        Node rootNode = NodeType.createNode({
            _value: value,
            _left: 0,
            _right: 0,
            _parent: 0
        });
        MinHeapMap._update(nodesSlot, key, rootNode);
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata({
            _root: key,
            _size: 1,
            _lastNodeKey: key,
            _leftmostNodeKey: key,
            _insertPointer: PointerType.createPointer(key, false)
        });
        heap.heapMetadata = heapMetadata;
        assertEq(MinHeapMap.peek(heap), value);
    }

    function testInsertAndPopOne() public {
        MinHeapMap.insert(heap, 42, 69);
        assertEq(MinHeapMap.peek(heap), 69, "peeked value incorrect");
        (
            uint256 root,
            uint256 size,
            uint256 lastNodeKey,
            uint256 leftmostNodeKey,
            Pointer insertPointer
        ) = HeapMetadataType.unpack(heap.heapMetadata);
        assertEq(root, 42, "root incorrect");
        assertEq(size, 1, "size incorrect");
        assertEq(lastNodeKey, 42, "lastNodeKey incorrect");
        assertEq(leftmostNodeKey, 42, "leftmostNodeKey incorrect");
        assertEq(Pointer.unwrap(insertPointer), 42, "insertPointer incorrect");

        uint256 value = MinHeapMap.pop(heap);
        assertEq(value, 69, "popped value incorrect");
        (root, size, lastNodeKey, leftmostNodeKey, insertPointer) =
            HeapMetadataType.unpack(heap.heapMetadata);
        assertEq(root, 0, "new root incorrect");
        assertEq(size, 0, "new size incorrect");
        assertEq(lastNodeKey, 0, "new lastNodeKey incorrect");
        assertEq(leftmostNodeKey, 0, "new leftmostNodeKey incorrect");
        assertEq(
            Pointer.unwrap(insertPointer), 0, "new insertPointer incorrect"
        );
    }

    function testInsertTwo() public {
        MinHeapMap.insert(heap, 42, 69);
        MinHeapMap.insert(heap, 43, 420);
        assertEq(MinHeapMap.peek(heap), 69, "peeked value incorrect");
        (
            uint256 root,
            uint256 size,
            uint256 lastNodeKey,
            uint256 leftmostNodeKey,
            Pointer insertPointer
        ) = HeapMetadataType.unpack(heap.heapMetadata);
        assertEq(root, 42, "root incorrect");
        assertEq(size, 2, "size incorrect");
        assertEq(lastNodeKey, 43, "lastNodeKey incorrect");
        assertEq(leftmostNodeKey, 43, "leftmostNodeKey incorrect");
        assertEq(
            Pointer.unwrap(insertPointer),
            Pointer.unwrap(PointerType.createPointer(42, true)),
            "insertPointer incorrect"
        );
    }
}
