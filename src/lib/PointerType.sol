// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

type Pointer is uint256;

library PointerType {
    uint256 constant KEY_MASK = 0xFFFFFFFF;
    uint256 constant RIGHT_SHIFT = 32;

    function createPointer(uint256 _key, bool _right)
        internal
        pure
        returns (Pointer _pointer)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _pointer := or(and(_key, KEY_MASK), shl(RIGHT_SHIFT, _right))
        }
    }

    function unpack(Pointer _pointer)
        internal
        pure
        returns (uint256 _key, bool _right)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _key := and(_pointer, KEY_MASK)
            _right := shr(RIGHT_SHIFT, _pointer)
        }
    }

    function key(Pointer _pointer) internal pure returns (uint256 _key) {
        ///@solidity memory-safe-assembly
        assembly {
            _key := and(_pointer, KEY_MASK)
        }
    }

    function right(Pointer _pointer) internal pure returns (bool _right) {
        ///@solidity memory-safe-assembly
        assembly {
            _right := shr(RIGHT_SHIFT, _pointer)
        }
    }
}

using PointerType for Pointer global;
