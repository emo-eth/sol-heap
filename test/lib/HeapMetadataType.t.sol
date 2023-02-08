// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TestPlus as Test } from "solady-test/utils/TestPlus.sol";
import {
    HeapMetadata, HeapMetadataType
} from "../../src/lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "../../src/lib/PointerType.sol";

contract HeapMetadataTypeTest is Test {
    function testCreateHeapMetadata(
        uint32 root,
        uint32 size,
        uint32 leftmostNodeKey,
        uint32 lastKey,
        uint32 insertKey,
        bool right
    ) public {
        Pointer insertPointer = PointerType.createPointer(insertKey, right);
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata({
            _root: root,
            _size: size,
            _leftmostNodeKey: leftmostNodeKey,
            _lastNodeKey: lastKey,
            _insertPointer: insertPointer
        });
        assertEq(heapMetadata.root(), root, "root incorrect");
        assertEq(heapMetadata.size(), size, "size incorrect");
        assertEq(
            heapMetadata.leftmostNodeKey(),
            leftmostNodeKey,
            "leftmostNodeKey incorrect"
        );
        assertEq(heapMetadata.lastNodeKey(), lastKey, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(heapMetadata.insertPointer()),
            Pointer.unwrap(insertPointer),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = heapMetadata.unpack();
        assertEq(_root, root, "unpacked root incorrect");
        assertEq(_size, size, "unpacked size incorrect");
        assertEq(
            _leftmostNodeKey,
            leftmostNodeKey,
            "unpacked leftmostNodeKey incorrect"
        );
        assertEq(_lastKey, lastKey, "unpacked lastKey incorrect");
        assertEq(
            Pointer.unwrap(_insertPointer),
            Pointer.unwrap(insertPointer),
            "unpacked insertPointer incorrect"
        );
    }

    function testCreateHeapMetadata() public {
        HeapMetadata heapMetadata = HeapMetadataType.createHeapMetadata({
            _root: 1,
            _size: 2,
            _leftmostNodeKey: 3,
            _lastNodeKey: 4,
            _insertPointer: PointerType.createPointer(5, true)
        });
        assertEq(heapMetadata.root(), 1, "root incorrect");
        assertEq(heapMetadata.size(), 2, "size incorrect");
        assertEq(heapMetadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(heapMetadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = heapMetadata.unpack();
        assertEq(_root, 1, "unpacked root incorrect");
        assertEq(_size, 2, "unpacked size incorrect");
        assertEq(_leftmostNodeKey, 3, "unpacked leftmostNodeKey incorrect");
        assertEq(_lastKey, 4, "unpacked lastKey incorrect");
        assertEq(
            Pointer.unwrap(_insertPointer),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "unpacked insertPointer incorrect"
        );
    }

    function testSafeCreateHeapMetadata(
        uint32 root,
        uint32 size,
        uint32 leftmostNodeKey,
        uint32 lastKey,
        uint32 insertKey,
        bool right
    ) public {
        Pointer insertPointer = PointerType.createPointer(insertKey, right);
        HeapMetadata heapMetadata = HeapMetadataType.safeCreateHeapMetadata({
            _root: root,
            _size: size,
            _leftmostNodeKey: leftmostNodeKey,
            _lastNodeKey: lastKey,
            _insertPointer: insertPointer
        });
        assertEq(heapMetadata.root(), root, "root incorrect");
        assertEq(heapMetadata.size(), size, "size incorrect");
        assertEq(
            heapMetadata.leftmostNodeKey(),
            leftmostNodeKey,
            "leftmostNodeKey incorrect"
        );
        assertEq(heapMetadata.lastNodeKey(), lastKey, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(heapMetadata.insertPointer()),
            Pointer.unwrap(insertPointer),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = heapMetadata.unpack();
        assertEq(_root, root, "unpacked root incorrect");
        assertEq(_size, size, "unpacked size incorrect");
        assertEq(
            _leftmostNodeKey,
            leftmostNodeKey,
            "unpacked leftmostNodeKey incorrect"
        );
        assertEq(_lastKey, lastKey, "unpacked lastKey incorrect");
        assertEq(
            Pointer.unwrap(_insertPointer),
            Pointer.unwrap(insertPointer),
            "unpacked insertPointer incorrect"
        );
    }

    function testSafeCreateHeapMetadata() public {
        HeapMetadata heapMetadata = HeapMetadataType.safeCreateHeapMetadata(
            1, 2, 3, 4, PointerType.createPointer(5, true)
        );
        assertEq(heapMetadata.root(), 1, "root incorrect");
        assertEq(heapMetadata.size(), 2, "size incorrect");
        assertEq(heapMetadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(heapMetadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(heapMetadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = heapMetadata.unpack();
        assertEq(_root, 1, "unpacked root incorrect");
        assertEq(_size, 2, "unpacked size incorrect");
        assertEq(_leftmostNodeKey, 3, "unpacked leftmostNodeKey incorrect");
        assertEq(_lastKey, 4, "unpacked lastKey incorrect");
        assertEq(
            Pointer.unwrap(_insertPointer),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "unpacked insertPointer incorrect"
        );
    }
}
