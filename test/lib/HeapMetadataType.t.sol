// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TestPlus as Test } from "../TestPlus.sol";
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
        HeapMetadata metadata = HeapMetadataType.createHeapMetadata({
            _rootKey: root,
            _size: size,
            _leftmostNodeKey: leftmostNodeKey,
            _lastNodeKey: lastKey,
            _insertPointer: insertPointer
        });
        assertEq(metadata.rootKey(), root, "root incorrect");
        assertEq(metadata.size(), size, "size incorrect");
        assertEq(
            metadata.leftmostNodeKey(),
            leftmostNodeKey,
            "leftmostNodeKey incorrect"
        );
        assertEq(metadata.lastNodeKey(), lastKey, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(metadata.insertPointer()),
            Pointer.unwrap(insertPointer),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = metadata.unpack();
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
        HeapMetadata metadata = HeapMetadataType.createHeapMetadata({
            _rootKey: 1,
            _size: 2,
            _leftmostNodeKey: 3,
            _lastNodeKey: 4,
            _insertPointer: PointerType.createPointer(5, true)
        });
        assertEq(metadata.rootKey(), 1, "root incorrect");
        assertEq(metadata.size(), 2, "size incorrect");
        assertEq(metadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(metadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = metadata.unpack();
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
        HeapMetadata metadata = HeapMetadataType.safeCreateHeapMetadata({
            _rootKey: root,
            _size: size,
            _leftmostNodeKey: leftmostNodeKey,
            _lastNodeKey: lastKey,
            _insertPointer: insertPointer
        });
        assertEq(metadata.rootKey(), root, "root incorrect");
        assertEq(metadata.size(), size, "size incorrect");
        assertEq(
            metadata.leftmostNodeKey(),
            leftmostNodeKey,
            "leftmostNodeKey incorrect"
        );
        assertEq(metadata.lastNodeKey(), lastKey, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(metadata.insertPointer()),
            Pointer.unwrap(insertPointer),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = metadata.unpack();
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
        HeapMetadata metadata = HeapMetadataType.safeCreateHeapMetadata(
            1, 2, 3, 4, PointerType.createPointer(5, true)
        );
        assertEq(metadata.rootKey(), 1, "root incorrect");
        assertEq(metadata.size(), 2, "size incorrect");
        assertEq(metadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(metadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );
        (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastKey,
            Pointer _insertPointer
        ) = metadata.unpack();
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

    function testSetters() public {
        HeapMetadata metadata = HeapMetadataType.createHeapMetadata({
            _rootKey: 1,
            _size: 2,
            _leftmostNodeKey: 3,
            _lastNodeKey: 4,
            _insertPointer: PointerType.createPointer(5, true)
        });
        HeapMetadata _metadata = metadata.setRootKey(6);
        assertEq(_metadata.rootKey(), 6, "root incorrect");
        assertEq(_metadata.size(), 2, "size incorrect");
        assertEq(_metadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(_metadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(_metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );

        // do for all setters

        _metadata = metadata.setSize(7);
        assertEq(_metadata.rootKey(), 1, "root incorrect");
        assertEq(_metadata.size(), 7, "size incorrect");
        assertEq(_metadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(_metadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(_metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );

        _metadata = metadata.setLeftmostNodeKey(8);
        assertEq(_metadata.rootKey(), 1, "root incorrect");
        assertEq(_metadata.size(), 2, "size incorrect");
        assertEq(_metadata.leftmostNodeKey(), 8, "leftmostNodeKey incorrect");
        assertEq(_metadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(_metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );

        _metadata = metadata.setLastNodeKey(9);
        assertEq(_metadata.rootKey(), 1, "root incorrect");
        assertEq(_metadata.size(), 2, "size incorrect");
        assertEq(_metadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(_metadata.lastNodeKey(), 9, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(_metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(5, true)),
            "insertPointer incorrect"
        );

        _metadata =
            metadata.setInsertPointer(PointerType.createPointer(10, false));
        assertEq(_metadata.rootKey(), 1, "root incorrect");
        assertEq(_metadata.size(), 2, "size incorrect");
        assertEq(_metadata.leftmostNodeKey(), 3, "leftmostNodeKey incorrect");
        assertEq(_metadata.lastNodeKey(), 4, "lastKey incorrect");
        assertEq(
            Pointer.unwrap(_metadata.insertPointer()),
            Pointer.unwrap(PointerType.createPointer(10, false)),
            "insertPointer incorrect"
        );
    }
}
