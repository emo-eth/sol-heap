// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

type Node is uint256;

library NodeType {
    uint256 constant VALUE_SHIFT = 96;
    uint256 constant RED_SHIFT = 95;
    uint256 constant PARENT_SHIFT = 64;
    uint256 constant LEFT_SHIFT = 32;
    uint256 constant UINT31_MASK = 0x7FFFFFFF;
    uint256 constant UINT160_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant NOT_VALUE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant NOT_RED_MASK =
        0xffffffffffffffffffffffffffffffffffffffff7fffffffffffffffffffffff;
    uint256 constant NOT_PARENT_MASK =
        0xffffffffffffffffffffffffffffffffffffffff80000000ffffffffffffffff;
    uint256 constant NOT_LEFT_MASK =
        0xffffffffffffffffffffffffffffffffffffffffffffffff80000000ffffffff;
    uint256 constant NOT_RIGHT_MASK =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff80000000;

    uint256 constant PackedValueTooLarge__Selector = 0x1e83345b;

    error PackedValueTooLarge();

    function createNode(
        uint256 _value,
        bool _red,
        uint256 _parent,
        uint256 _left,
        uint256 _right
    ) internal pure returns (Node node) {
        ///@solidity memory-safe-assembly
        assembly {
            node :=
                or(
                    shl(VALUE_SHIFT, _value),
                    or(
                        shl(RED_SHIFT, _red),
                        or(
                            shl(PARENT_SHIFT, _parent),
                            or(shl(LEFT_SHIFT, _left), _right)
                        )
                    )
                )
        }
    }

    function safeCreateNode(
        uint160 _value,
        bool _red,
        uint256 _parent,
        uint256 _left,
        uint256 _right
    ) internal pure returns (Node node) {
        ///@solidity memory-safe-assembly
        assembly {
            // _value was cast to 160 on the way in, so no need to double-check
            if gt(or(_parent, or(_left, _right)), UINT31_MASK) {
                mstore(0, PackedValueTooLarge__Selector)
                revert(0x1c, 4)
            }
            node :=
                or(
                    shl(VALUE_SHIFT, _value),
                    or(
                        shl(RED_SHIFT, _red),
                        or(
                            shl(PARENT_SHIFT, _parent),
                            or(shl(LEFT_SHIFT, _left), _right)
                        )
                    )
                )
        }
    }

    function unpack(Node node)
        internal
        pure
        returns (
            uint256 _value,
            bool _red,
            uint256 _parent,
            uint256 _left,
            uint256 _right
        )
    {
        ///@solidity memory-safe-assembly
        assembly {
            _value := shr(VALUE_SHIFT, node)
            _red := and(shr(RED_SHIFT, node), 1)
            _parent := and(shr(PARENT_SHIFT, node), UINT31_MASK)
            _left := and(shr(LEFT_SHIFT, node), UINT31_MASK)
            _right := and(node, UINT31_MASK)
        }
    }

    function value(Node node) internal pure returns (uint256 _value) {
        ///@solidity memory-safe-assembly
        assembly {
            _value := shr(VALUE_SHIFT, node)
        }
    }

    function red(Node node) internal pure returns (bool _red) {
        ///@solidity memory-safe-assembly
        assembly {
            _red := and(shr(RED_SHIFT, node), 1)
        }
    }

    function parent(Node node) internal pure returns (uint256 _parent) {
        ///@solidity memory-safe-assembly
        assembly {
            _parent := and(shr(PARENT_SHIFT, node), UINT31_MASK)
        }
    }

    function left(Node node) internal pure returns (uint256 _left) {
        ///@solidity memory-safe-assembly
        assembly {
            _left := and(shr(LEFT_SHIFT, node), UINT31_MASK)
        }
    }

    function right(Node node) internal pure returns (uint256 _right) {
        ///@solidity memory-safe-assembly
        assembly {
            _right := and(node, UINT31_MASK)
        }
    }

    function setValue(Node node, uint256 _value)
        internal
        pure
        returns (Node _node)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _node := or(and(node, NOT_VALUE_MASK), shl(VALUE_SHIFT, _value))
        }
    }

    function setRed(Node node, bool _red) internal pure returns (Node _node) {
        ///@solidity memory-safe-assembly
        assembly {
            _node := or(and(node, NOT_RED_MASK), shl(RED_SHIFT, _red))
        }
    }

    function setRedUint(Node node, uint256 _red)
        internal
        pure
        returns (Node _node)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _node := or(and(node, NOT_RED_MASK), shl(RED_SHIFT, and(1, _red)))
        }
    }

    function setParent(Node node, uint256 _parent)
        internal
        pure
        returns (Node _node)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _node := or(and(node, NOT_PARENT_MASK), shl(PARENT_SHIFT, _parent))
        }
    }

    function setLeft(Node node, uint256 _left)
        internal
        pure
        returns (Node _node)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _node := or(and(node, NOT_LEFT_MASK), shl(LEFT_SHIFT, _left))
        }
    }

    function setRight(Node node, uint256 _right)
        internal
        pure
        returns (Node _node)
    {
        ///@solidity memory-safe-assembly
        assembly {
            _node := or(and(node, NOT_RIGHT_MASK), _right)
        }
    }
}

// using {unpack, value, red, parent, left, right} for Node global;
using NodeType for Node global;
