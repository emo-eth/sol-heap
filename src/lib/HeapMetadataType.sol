// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Pointer } from "./PointerType.sol";

type HeapMetadata is uint256;

library HeapMetadataType {
    uint256 constant UINT32_MASK = 0xffffffff;
    uint256 constant POINTER_MASK = 0x1FFFFFFFF;
    uint256 constant NOT_SIZE = 0x01ffffffffffffffffffffffffffffffff00000000;
    uint256 constant NOT_ROOT = 0x01ffffffffffffffffffffffff00000000ffffffff;
    uint256 constant NOT_LEFTMOST_NODE_POINTER =
        0x01ffffffffffffffff00000000ffffffffffffffff;
    uint256 constant NOT_LAST_NODE_POINTER =
        0x01ffffffff00000000ffffffffffffffffffffffff;
    uint256 constant NOT_INSERT_POINTER = 0xffffffffffffffffffffffffffffffff;
    uint256 constant ROOT_SHIFT = 32;
    uint256 constant LEFTMOST_NODE_POINTER_SHIFT = 64;
    uint256 constant LAST_NODE_POINTER_SHIFT = 96;
    uint256 constant INSERT_POINTER_SHIFT = 128;

    function createHeapMetadata(
        uint256 _root,
        uint256 _size,
        uint256 _leftmostNodeKey,
        uint256 _lastNodeKey,
        Pointer _insertPointer
    ) internal pure returns (HeapMetadata _heapMetadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _heapMetadata :=
                or(
                    or(
                        or(
                            or(
                                shl(ROOT_SHIFT, _root),
                                shl(INSERT_POINTER_SHIFT, _insertPointer)
                            ),
                            shl(LAST_NODE_POINTER_SHIFT, _lastNodeKey)
                        ),
                        shl(LEFTMOST_NODE_POINTER_SHIFT, _leftmostNodeKey)
                    ),
                    _size
                )
        }
    }

    function safeCreateHeapMetadata(
        uint32 _root,
        uint32 _size,
        uint32 _leftmostNodeKey,
        uint32 _lastNodeKey,
        Pointer _insertPointer
    ) internal pure returns (HeapMetadata _heapMetadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _heapMetadata :=
                or(
                    or(
                        or(
                            or(
                                shl(ROOT_SHIFT, _root),
                                shl(INSERT_POINTER_SHIFT, _insertPointer)
                            ),
                            shl(LAST_NODE_POINTER_SHIFT, _lastNodeKey)
                        ),
                        shl(LEFTMOST_NODE_POINTER_SHIFT, _leftmostNodeKey)
                    ),
                    _size
                )
        }
    }

    function unpack(HeapMetadata _heapMetadata)
        internal
        pure
        returns (
            uint256 _root,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastNodeKey,
            Pointer _insertPointer
        )
    {
        ///@solidity memory-safe-assembly
        assembly {
            _root := and(shr(ROOT_SHIFT, _heapMetadata), UINT32_MASK)
            _size := and(_heapMetadata, UINT32_MASK)
            _insertPointer :=
                and(shr(INSERT_POINTER_SHIFT, _heapMetadata), POINTER_MASK)
            _lastNodeKey :=
                and(shr(LAST_NODE_POINTER_SHIFT, _heapMetadata), UINT32_MASK)
            _leftmostNodeKey :=
                and(shr(LEFTMOST_NODE_POINTER_SHIFT, _heapMetadata), UINT32_MASK)
        }
    }

    function root(HeapMetadata _heapMetadata)
        internal
        pure
        returns (uint256 _root)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _root := and(shr(ROOT_SHIFT, _heapMetadata), UINT32_MASK)
        }
    }

    function size(HeapMetadata _heapMetadata)
        internal
        pure
        returns (uint256 _size)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _size := and(_heapMetadata, UINT32_MASK)
        }
    }

    function insertPointer(HeapMetadata _heapMetadata)
        internal
        pure
        returns (Pointer _insertPointer)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _insertPointer :=
                and(shr(INSERT_POINTER_SHIFT, _heapMetadata), POINTER_MASK)
        }
    }

    function lastNodeKey(HeapMetadata _heapMetadata)
        internal
        pure
        returns (uint256 _lastNodeKey)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _lastNodeKey :=
                and(shr(LAST_NODE_POINTER_SHIFT, _heapMetadata), UINT32_MASK)
        }
    }

    function leftmostNodeKey(HeapMetadata _heapMetadata)
        internal
        pure
        returns (uint256 _leftmostNodeKey)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _leftmostNodeKey :=
                and(shr(LEFTMOST_NODE_POINTER_SHIFT, _heapMetadata), UINT32_MASK)
        }
    }

    function setRoot(HeapMetadata _heapMetadata, uint256 _root)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(and(_heapMetadata, NOT_ROOT), shl(ROOT_SHIFT, _root))
        }
    }

    function setSize(HeapMetadata _heapMetadata, uint256 _size)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(and(_heapMetadata, NOT_SIZE), and(_size, UINT32_MASK))
        }
    }

    function setInsertPointer(
        HeapMetadata _heapMetadata,
        Pointer _insertPointer
    ) internal pure returns (HeapMetadata _newHeapMetadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(
                    and(_heapMetadata, NOT_INSERT_POINTER),
                    shl(INSERT_POINTER_SHIFT, _insertPointer)
                )
        }
    }

    function setLastNodeKey(HeapMetadata _heapMetadata, uint256 _lastNodeKey)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(
                    and(_heapMetadata, NOT_LAST_NODE_POINTER),
                    shl(LAST_NODE_POINTER_SHIFT, _lastNodeKey)
                )
        }
    }

    function setLeftmostNodeKey(
        HeapMetadata _heapMetadata,
        uint256 _leftmostNodeKey
    ) internal pure returns (HeapMetadata _newHeapMetadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(
                    and(_heapMetadata, NOT_LEFTMOST_NODE_POINTER),
                    shl(LEFTMOST_NODE_POINTER_SHIFT, _leftmostNodeKey)
                )
        }
    }
}

using HeapMetadataType for HeapMetadata global;
