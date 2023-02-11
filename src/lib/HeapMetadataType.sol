// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Pointer } from "./PointerType.sol";

type HeapMetadata is uint256;

library HeapMetadataType {
    // POINTER, ROOT, SIZE, LEFTMOST, LAST
    uint256 constant UINT32_MASK = 0xffffffff;
    uint256 constant POINTER_MASK = 0x1FFFFFFFF;
    uint256 constant NOT_INSERT_POINTER = 0xffffffffffffffffffffffffffffffff;
    uint256 constant NOT_ROOT_KEY = 0x01ffffffff00000000ffffffffffffffffffffffff;
    uint256 constant NOT_SIZE = 0x01ffffffffffffffff00000000ffffffffffffffff;
    uint256 constant NOT_LEFTMOST_KEY =
        0x01ffffffffffffffffffffffff00000000ffffffff;
    uint256 constant NOT_LAST_KEY = 0x01ffffffffffffffffffffffffffffffff00000000;

    uint256 constant INSERT_POINTER_SHIFT = 128;
    uint256 constant ROOT_KEY_SHIFT = 96;
    uint256 constant SIZE_SHIFT = 64;
    uint256 constant LEFTMOST_KEY_SHIFT = 32;

    function createHeapMetadata(
        uint256 _rootKey,
        uint256 _size,
        uint256 _leftmostNodeKey,
        uint256 _lastNodeKey,
        Pointer _insertPointer
    ) internal pure returns (HeapMetadata _metadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _metadata :=
                or(
                    or(
                        or(
                            or(
                                shl(ROOT_KEY_SHIFT, _rootKey),
                                shl(INSERT_POINTER_SHIFT, _insertPointer)
                            ),
                            shl(SIZE_SHIFT, _size)
                        ),
                        shl(LEFTMOST_KEY_SHIFT, _leftmostNodeKey)
                    ),
                    _lastNodeKey
                )
        }
    }

    function safeCreateHeapMetadata(
        uint32 _rootKey,
        uint32 _size,
        uint32 _leftmostNodeKey,
        uint32 _lastNodeKey,
        Pointer _insertPointer
    ) internal pure returns (HeapMetadata _metadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _metadata :=
                or(
                    or(
                        or(
                            or(
                                shl(ROOT_KEY_SHIFT, _rootKey),
                                shl(INSERT_POINTER_SHIFT, _insertPointer)
                            ),
                            shl(SIZE_SHIFT, _size)
                        ),
                        shl(LEFTMOST_KEY_SHIFT, _leftmostNodeKey)
                    ),
                    _lastNodeKey
                )
        }
    }

    function unpack(HeapMetadata _metadata)
        internal
        pure
        returns (
            uint256 _rootKey,
            uint256 _size,
            uint256 _leftmostNodeKey,
            uint256 _lastNodeKey,
            Pointer _insertPointer
        )
    {
        ///@solidity memory-safe-assembly
        assembly {
            _rootKey := and(shr(ROOT_KEY_SHIFT, _metadata), UINT32_MASK)
            _size := and(shr(SIZE_SHIFT, _metadata), UINT32_MASK)
            _leftmostNodeKey :=
                and(shr(LEFTMOST_KEY_SHIFT, _metadata), UINT32_MASK)
            _lastNodeKey := and(_metadata, UINT32_MASK)
            _insertPointer :=
                and(shr(INSERT_POINTER_SHIFT, _metadata), POINTER_MASK)
        }
    }

    function rootKey(HeapMetadata _metadata)
        internal
        pure
        returns (uint256 _rootKey)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _rootKey := and(shr(ROOT_KEY_SHIFT, _metadata), UINT32_MASK)
        }
    }

    function size(HeapMetadata _metadata)
        internal
        pure
        returns (uint256 _size)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _size := and(shr(SIZE_SHIFT, _metadata), UINT32_MASK)
        }
    }

    function insertPointer(HeapMetadata _metadata)
        internal
        pure
        returns (Pointer _insertPointer)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _insertPointer :=
                and(shr(INSERT_POINTER_SHIFT, _metadata), POINTER_MASK)
        }
    }

    function lastNodeKey(HeapMetadata _metadata)
        internal
        pure
        returns (uint256 _lastNodeKey)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _lastNodeKey := and(_metadata, UINT32_MASK)
        }
    }

    function leftmostNodeKey(HeapMetadata _metadata)
        internal
        pure
        returns (uint256 _leftmostNodeKey)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _leftmostNodeKey :=
                and(shr(LEFTMOST_KEY_SHIFT, _metadata), UINT32_MASK)
        }
    }

    function setRootKey(HeapMetadata _metadata, uint256 _rootKey)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(and(_metadata, NOT_ROOT_KEY), shl(ROOT_KEY_SHIFT, _rootKey))
        }
    }

    function setSize(HeapMetadata _metadata, uint256 _size)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(and(_metadata, NOT_SIZE), shl(SIZE_SHIFT, _size))
        }
    }

    function setInsertPointer(HeapMetadata _metadata, Pointer _insertPointer)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(
                    and(_metadata, NOT_INSERT_POINTER),
                    shl(INSERT_POINTER_SHIFT, _insertPointer)
                )
        }
    }

    function setLastNodeKey(HeapMetadata _metadata, uint256 _lastNodeKey)
        internal
        pure
        returns (HeapMetadata _newHeapMetadata)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata := or(and(_metadata, NOT_LAST_KEY), _lastNodeKey)
        }
    }

    function setLeftmostNodeKey(
        HeapMetadata _metadata,
        uint256 _leftmostNodeKey
    ) internal pure returns (HeapMetadata _newHeapMetadata) {
        ///@solidity memory-safe-assembly
        assembly {
            _newHeapMetadata :=
                or(
                    and(_metadata, NOT_LEFTMOST_KEY),
                    shl(LEFTMOST_KEY_SHIFT, _leftmostNodeKey)
                )
        }
    }
}

using HeapMetadataType for HeapMetadata global;
