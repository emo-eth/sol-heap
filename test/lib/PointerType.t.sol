// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TestPlus as Test } from "solady-test/utils/TestPlus.sol";
import { Pointer, PointerType } from "../../src/lib/PointerType.sol";

contract PointerTypeTest is Test {
    using PointerType for Pointer;

    function testCreatePointer(uint32 key, bool right) public {
        Pointer pointer = PointerType.createPointer(key, right);
        assertEq(PointerType.key(pointer), key, "key incorrect");
        assertEq(PointerType.right(pointer), right, "right incorrect");
        (uint256 _key, bool _right) = pointer.unpack();
        assertEq(_key, key, "unpacked key incorrect");
        assertEq(_right, right, "unpacked right incorrect");
    }

    function testCreatePointer() public {
        Pointer pointer = PointerType.createPointer(1, true);
        assertEq(PointerType.key(pointer), 1, "key incorrect");
        assertEq(PointerType.right(pointer), true, "right incorrect");
        (uint256 _key, bool _right) = pointer.unpack();
        assertEq(_key, 1, "unpacked key incorrect");
        assertEq(_right, true, "unpacked right incorrect");
    }

    function testSetters() public {
        Pointer pointer = PointerType.createPointer(1, true);
        Pointer _pointer = pointer.setKey(2);
        assertEq(PointerType.key(_pointer), 2, "key incorrect");
        assertEq(PointerType.right(_pointer), true, "right incorrect");

        (uint256 _key, bool _right) = _pointer.unpack();
        assertEq(_key, 2, "unpacked key incorrect");
        assertEq(_right, true, "unpacked right incorrect");

        _pointer = pointer.setRight(false);
        assertEq(PointerType.key(_pointer), 1, "key incorrect");
        assertEq(PointerType.right(_pointer), false, "right incorrect");

        (_key, _right) = _pointer.unpack();
        assertEq(_key, 1, "unpacked key incorrect");
        assertEq(_right, false, "unpacked right incorrect");
    }
}
