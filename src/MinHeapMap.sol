// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Node, NodeType } from "./lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "./lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "./lib/PointerType.sol";
import { Heap } from "./lib/Structs.sol";
import { EMPTY } from "./lib/Constants.sol";
import { MinHeapMapHelper as Helper } from "./lib/MinheapMapHelper.sol";

library MinHeapMap {
    using MinHeapMap for Heap;

    error MinHeap__Empty();
    error MinHeap__NodeDoesNotExist();
    error MinHeap__NodeExists();

    /**
     * @notice get the size of a heap
     */
    function size(Heap storage heap) internal view returns (uint256 _size) {
        HeapMetadata metadata;
        assembly {
            metadata := sload(add(heap.slot, 1))
        }
        _size = metadata.size();
    }

    /**
     * @notice Wrap a value into a node and insert it into the last position of
     * the
     * heap, then percolate the node up until heap properties are satisfied.
     */
    function insert(Heap storage heap, uint256 key, uint256 nodeValue)
        internal
    {
        uint256 nodesSlot = Helper._nodesSlot(heap);
        Node retrieved = Helper.get(nodesSlot, key);
        HeapMetadata metadata = heap.metadata;
        // node value can be "empty" IF it is also the root (ie, zero value, no
        // children or parent)
        if (Node.unwrap(retrieved) != EMPTY || metadata.rootKey() == key) {
            revert MinHeap__NodeExists();
        }
        Pointer insertPointer = metadata.insertPointer();
        uint256 parentKey = insertPointer.key();

        if (parentKey != EMPTY) {
            Node parentNode = Helper.get(nodesSlot, parentKey);
            if (insertPointer.right()) {
                parentNode = parentNode.setRight(key);
            } else {
                parentNode = parentNode.setLeft(key);
            }
            Helper.update(nodesSlot, parentKey, parentNode);
        }

        // create node for new value and update it in the nodes mapping
        Node newNode = NodeType.createNode({
            _value: nodeValue,
            _parent: parentKey,
            _left: EMPTY,
            _right: EMPTY
        });
        Helper.update(nodesSlot, key, newNode);

        metadata = Helper.preInsertUpdateHeapMetadata(nodesSlot, metadata, key);

        // percolate new node up in the heap and store updated heap metadata
        heap.metadata = Helper.percUp(nodesSlot, metadata, key, newNode);
    }

    /**
     * @notice Remove the root node and return its value. Replaces root node
     * with last node and then percolates the new root node down until heap
     * properties are satisfied.
     */
    function pop(Heap storage heap) internal returns (uint256) {
        HeapMetadata metadata = heap.metadata;
        if (metadata.size() == 0) {
            revert MinHeap__Empty();
        }
        uint256 nodesSlot = Helper._nodesSlot(heap);
        uint256 oldRootKey;
        uint256 oldLastNodeKey;
        // pre-emptively update with new root and new lastNode
        (oldRootKey, oldLastNodeKey, metadata) =
            Helper.prePopUpdateMetadata(nodesSlot, metadata);
        // swap root with last node and delete root node
        (uint256 rootVal, uint256 newRootKey, Node newRoot) =
            Helper.pop(nodesSlot, oldRootKey, oldLastNodeKey);
        // percolate new root downwards through tree
        metadata = Helper.percDown(nodesSlot, metadata, newRootKey, newRoot);
        heap.metadata = metadata;
        return rootVal;
    }

    /**
     * @notice Get the value of the root node without removing it.
     */
    function peek(Heap storage heap) internal view returns (uint256) {
        HeapMetadata metadata = heap.metadata;
        if (metadata.size() == 0) {
            revert MinHeap__Empty();
        }
        return Helper.get(Helper._nodesSlot(heap), metadata.rootKey()).value();
    }

    /**
     * @notice Update the value of a node in the heap and percolate changes up
     * or down until heap properties are satisfied.
     */
    function update(Heap storage heap, uint256 key, uint256 newValue)
        internal
    {
        uint256 nodesSlot = Helper._nodesSlot(heap);
        Node node = Helper.get(nodesSlot, key);
        HeapMetadata metadata = heap.metadata;
        if (Node.unwrap(node) == EMPTY && metadata.rootKey() != key) {
            revert MinHeap__NodeDoesNotExist();
        }
        uint256 oldValue = node.value();
        if (newValue == oldValue) {
            return;
        }
        // set new value and update
        node = node.setValue(newValue);
        Helper.update(nodesSlot, key, node);

        // if new value is less than old value, percolate up to satisfy minHeap
        // properties
        if (newValue < oldValue) {
            heap.metadata = Helper.percUp(nodesSlot, metadata, key, node);
        } else {
            // else percolateDown to satisfy minHeap properties
            heap.metadata = Helper.percDown(nodesSlot, metadata, key, node);
        }
    }
}
