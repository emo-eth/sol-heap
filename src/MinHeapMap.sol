// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Node, NodeType } from "./lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "./lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "./lib/PointerType.sol";
import { Heap } from "./lib/Structs.sol";
import { EMPTY } from "./lib/Constants.sol";
import { MinHeapMapHelper as Helper } from "./lib/MinheapMapHelper.sol";

library MinHeapMap {
    error MinHeap__Empty();
    error MinHeap__NotEmpty();
    error MinHeap__NodeExists();

    /**
     * @dev get the size of a heap
     */
    function size(Heap storage heap) internal returns (uint256 _size) {
        HeapMetadata heapMetadata;
        assembly {
            heapMetadata := sload(add(heap.slot, 1))
        }
        _size = heapMetadata.size();
    }

    /**
     * @dev Wrap a value into a node and insert it into the last position of the
     * heap, then percolate the node up until heap properties are satisfied.
     */
    function insert(Heap storage heap, uint256 key, uint256 nodeValue)
        internal
    {
        uint256 nodesSlot = Helper._nodesSlot(heap);
        Node retrieved = Helper._get(nodesSlot, key);
        HeapMetadata heapMetadata = heap.heapMetadata;
        // node value can be "empty" IF it is also the root (ie, zero value, no
        // children or parent)
        if (Node.unwrap(retrieved) != EMPTY || heapMetadata.rootKey() == key) {
            revert MinHeap__NodeExists();
        }
        Pointer insertPointer = heapMetadata.insertPointer();
        uint256 parentKey = insertPointer.key();

        if (parentKey != EMPTY) {
            Node parentNode = Helper._get(nodesSlot, parentKey);
            if (insertPointer.right()) {
                parentNode = parentNode.setRight(key);
            } else {
                parentNode = parentNode.setLeft(key);
            }
            Helper._update(nodesSlot, parentKey, parentNode);
        }

        // create node for new value and update it in the nodes mapping
        Node newNode = NodeType.createNode({
            _value: nodeValue,
            _parent: parentKey,
            _left: EMPTY,
            _right: EMPTY
        });
        Helper._update(nodesSlot, key, newNode);

        heapMetadata =
            Helper._preInsertUpdateHeapMetadata(nodesSlot, heapMetadata, key);

        // percolate new node up in the heap and store updated heap metadata
        heap.heapMetadata = Helper.percUp(nodesSlot, heapMetadata, key, newNode);
    }

    /**
     * @notice Remove the root node and return its value.
     */
    function pop(Heap storage heap) internal returns (uint256) {
        uint256 nodesSlot = Helper._nodesSlot(heap);
        // pre-emptively update with new root and new lastNode
        (uint256 oldRootKey, uint256 oldLastNodeKey, HeapMetadata heapMetadata)
        = Helper._prePopUpdateMetadata(nodesSlot, heap.heapMetadata);
        // swap root with last node and delete root node
        (uint256 rootVal, uint256 newRootKey, Node newRoot) =
            Helper._pop(nodesSlot, oldRootKey, oldLastNodeKey);
        // percolate new root downwards through tree
        heapMetadata =
            Helper.percDown(nodesSlot, heapMetadata, newRootKey, newRoot);
        heap.heapMetadata = heapMetadata;
        return rootVal;
    }

    /**
     * @notice Get the value of the root node without removing it.
     */
    function peek(Heap storage heap) internal returns (uint256) {
        // uint256 rootKey = heap.heapMetadata.rootKey();
        // if (rootKey == EMPTY) {
        //     revert("no root");
        // }
        return Helper._get(Helper._nodesSlot(heap), heap.heapMetadata.rootKey())
            .value();
    }

    function update(Heap storage heap, uint256 key, uint256 newValue)
        internal
    {
        uint256 nodesSlot = Helper._nodesSlot(heap);
        Node node = Helper._get(nodesSlot, key);
        uint256 oldValue = node.value();
        if (newValue == oldValue) {
            return;
        }
        // set new value and update
        node = node.setValue(newValue);
        // todo: write first?
        Helper._update(nodesSlot, key, node);
        // if new value is less than old value, percolate up to satisfy minHeap
        // properties
        if (newValue < oldValue) {
            heap.heapMetadata =
                Helper.percUp(nodesSlot, heap.heapMetadata, key, node);
        } else {
            // else percolateDown to satisfy minHeap properties
            heap.heapMetadata =
                Helper.percDown(nodesSlot, heap.heapMetadata, key, node);
        }
    }
}
