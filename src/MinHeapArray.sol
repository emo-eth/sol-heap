// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MinHeapArray {
    error MinHeap__Empty();
    error MinHeap__NotEmpty();

    struct Heap {
        uint256[] nodes;
    }

    function size(Heap storage heap) internal view returns (uint256) {
        return heap.nodes.length;
    }

    function _push(uint256[] storage nodes, uint256 node)
        private
        returns (uint256 newLength)
    {
        assembly {
            newLength := add(1, sload(nodes.slot))
            // write new length
            sstore(nodes.slot, newLength)
            // heap nodes are 1-indexed for ease of calculating children
            // eg children of i are 2i and 2i + 1, which only works starting
            // with i = 1
            // this means nodes[0] is never accessed or written to, so adding an
            // extra
            // 1 to offset the length slot is not necessary.
            sstore(add(nodes.slot, newLength), node)
        }
    }

    function _copy(uint256[] storage nodes, uint256[] memory nodesToPush)
        private
    {
        uint256 length = nodesToPush.length;
        assembly {
            sstore(nodes.slot, length)
            for { let i } lt(i, length) { i := add(i, 1) } {
                sstore(
                    // write index i to nodes.slot + i + 1
                    add(nodes.slot, add(1, i)),
                    // mload index i from nodesToPush.offset + (i * 0x20)
                    mload(
                        add(
                            nodesToPush,
                            // i * 0x20
                            shl(5, i)
                        )
                    )
                )
            }
        }
    }

    function _read(uint256[] storage nodes, uint256 index)
        private
        view
        returns (uint256 node)
    {
        assembly {
            // heap-nodes are 1-indexed, so no need to add 1 to index
            node := sload(add(nodes.slot, index))
        }
    }

    function _update(uint256[] storage nodes, uint256 index, uint256 node)
        private
    {
        assembly {
            sstore(add(nodes.slot, index), node)
        }
    }

    function _pop(uint256[] storage nodes)
        private
        returns (uint256 minNode, uint256 newLength)
    {
        assembly {
            // get old length
            let oldLength := sload(nodes.slot)
            // get slot of last node
            let lastNodeSlot := add(nodes.slot, oldLength)
            // get last node
            let lastNode := sload(lastNodeSlot)
            // decrement length
            newLength := sub(oldLength, 1)
            // store new length
            sstore(nodes.slot, newLength)
            // get slot of first node
            let firstNodeSlot := add(nodes.slot, 1)
            // load first node, which we are replacing
            minNode := sload(firstNodeSlot)
            // write last node to first position
            sstore(firstNodeSlot, lastNode)
            // overwrite last node with 0
            // only necessary when length is 0, and to clean up storage
            sstore(lastNodeSlot, 0)
        }
    }

    function insert(Heap storage heap, uint256 node) internal {
        uint256[] storage nodes = heap.nodes;
        _push(nodes, node);
        percUp(nodes, nodes.length);
    }

    function percUp(uint256[] storage nodes, uint256 _size) private {
        uint256 i = _size;
        uint256 parentIndex = i >> 1;
        while (parentIndex > 0) {
            uint256 node = _read(nodes, i);
            uint256 parent = _read(nodes, parentIndex);
            if (node < parent) {
                uint256 tmp = parent;
                _update(nodes, parentIndex, node);
                _update(nodes, i, tmp);
            }
            i = parentIndex;
            parentIndex = i >> 1;
        }
    }

    function percDown(
        uint256[] storage nodes,
        uint256 startIndex,
        uint256 _size
    ) private {
        uint256 i = startIndex;
        uint256 minChildIndex = i << 1;
        while (minChildIndex <= _size) {
            uint256 node = _read(nodes, i);
            uint256 child = _read(nodes, minChildIndex);
            // no realistic chance of overflow
            unchecked {
                if (minChildIndex + 1 <= _size) {
                    uint256 rightChild = _read(nodes, minChildIndex + 1);
                    if (rightChild < child) {
                        child = rightChild;
                        minChildIndex = minChildIndex + 1;
                    }
                }
            }
            if (node > child) {
                uint256 tmp = child;
                _update(nodes, minChildIndex, node);
                _update(nodes, i, tmp);
            }
            i = minChildIndex;
            minChildIndex = i << 1;
        }
    }

    function pop(Heap storage heap) internal returns (uint256) {
        uint256[] storage nodes = heap.nodes;

        uint256 _size = nodes.length;
        if (_size == 0) {
            revert MinHeap__Empty();
        }
        (uint256 val, uint256 newLength) = _pop(nodes);
        percDown({nodes: nodes, startIndex: 1, _size: newLength});
        return val;
    }

    function peek(Heap storage heap) internal view returns (uint256) {
        uint256[] storage nodes = heap.nodes;

        uint256 _size = nodes.length;
        if (_size == 0) {
            revert MinHeap__Empty();
        }
        return _read(nodes, 1);
    }

    function buildMinHeap(Heap storage heap, uint256[] memory nodesToBuild)
        internal
    {
        uint256[] storage nodes = heap.nodes;
        if (nodes.length != 0) {
            revert MinHeap__NotEmpty();
        }
        uint256 _size = nodesToBuild.length;
        _copy(nodes, nodesToBuild);
        uint256 i = nodesToBuild.length >> 1;
        while (i > 0) {
            percDown(nodes, i, _size);
            unchecked {
                --i;
            }
        }
    }
}
