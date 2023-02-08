// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Node, NodeType } from "./lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "./lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "./lib/PointerType.sol";

library MinHeapMap {
    error MinHeap__Empty();
    error MinHeap__NotEmpty();

    uint256 constant EMPTY = 0;

    struct Heap {
        mapping(uint256 => Node) nodes;
        HeapMetadata heapMetadata;
    }

    function size(Heap storage heap) internal view returns (uint256 _size) {
        HeapMetadata heapMetadata;
        assembly {
            heapMetadata := sload(add(heap.slot, 1))
        }
        _size = heapMetadata.size();
    }

    function _add(Heap storage heap, uint256 key, Node node)
        internal
        returns (uint256 newLength)
    {
        assembly {
            let sizeSlot := add(heap.slot, 1)
            newLength := add(1, sload(sizeSlot))
            // write new length
            sstore(sizeSlot, newLength)
            // drive mapping slot from key
            mstore(0, key)
            mstore(0x20, heap.slot)
            // write node to mapping slot
            sstore(keccak256(0, 0x40), node)
        }
    }

    function _get(uint256 slot, uint256 key)
        internal
        view
        returns (Node node)
    {
        assembly {
            // drive mapping slot from key
            mstore(0, key)
            mstore(0x20, slot)
            // read node from mapping slot
            node := sload(keccak256(0, 0x40))
        }
    }

    function _update(uint256 nodesSlot, uint256 index, Node node) internal {
        assembly {
            sstore(add(nodesSlot, index), node)
        }
    }

    function _swap(
        uint256 nodesSlot,
        uint256 childKey,
        Node childNode,
        uint256 parentKey,
        Node parentNode
    ) internal {
        bool isRight = parentNode.right() == childKey;
        uint256 childNewParent = parentNode.parent();
        uint256 childNewLeft;
        uint256 childNewRight;
        uint256 parentLeft = parentNode.left();
        uint256 parentRight = parentNode.right();
        uint256 parentNewLeft = childNode.left();
        uint256 parentNewRight = childNode.right();
        assembly {
            childNewLeft :=
                add(mul(iszero(isRight), parentLeft), mul(isRight, parentRight))
            childNewRight :=
                add(mul(iszero(isRight), parentRight), mul(isRight, parentLeft))
        }
        childNode = childNode.setParent(childNewParent).setLeft(childNewLeft)
            .setRight(childNewRight);
        parentNode = parentNode.setParent(childKey).setLeft(parentNewLeft)
            .setRight(parentNewRight);

        _update(nodesSlot, childKey, childNode);
        _update(nodesSlot, parentKey, parentNode);
    }

    function _updateChildrenParentPointers(
        uint256 nodesSlot,
        Node parentNode,
        uint256 parentKey,
        uint256 newParentKey
    ) internal {
        uint256 leftChildKey = parentNode.left();
        uint256 rightChildKey = parentNode.right();
        if (leftChildKey != EMPTY) {
            Node leftChildNode = _get(nodesSlot, leftChildKey);
            leftChildNode = leftChildNode.setParent(newParentKey);
            _update(nodesSlot, leftChildKey, leftChildNode);
        }
        if (rightChildKey != EMPTY) {
            Node rightChildNode = _get(nodesSlot, rightChildKey);
            rightChildNode = rightChildNode.setParent(newParentKey);
            _update(nodesSlot, rightChildKey, rightChildNode);
        }
    }

    function _pop(Heap storage heap)
        internal
        returns (uint256 oldRootVal, uint256 newRootKey)
    {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        uint256 lastNodeKey = heap.heapMetadata.lastNodePointer().key();
        uint256 rootKey = heap.heapMetadata.root();

        Node lastNode = _get(nodesSlot, lastNodeKey);
        Node rootNode = _get(nodesSlot, rootKey);
        // update root's childrens' parent pointers
        _updateChildrenParentPointers(nodesSlot, rootNode, rootKey, lastNodeKey);
        uint256 lastParentKey = lastNode.parent();

        // update lastNode with all of root node's properties except for the
        // value
        lastNode = rootNode.setValue(lastNode.value());

        // update parent of the last node, only if it hasn't already been
        // updated
        // (i.e. if the last node was a child of the root)
        if (lastParentKey != rootKey) {
            Node lastParentNode = _get(nodesSlot, lastParentKey);
            uint256 lastParentRight = lastParentNode.right();
            uint256 lastParentLeft = lastParentNode.left();
            assembly {
                lastParentRight :=
                    mul(eq(lastParentRight, lastNodeKey), lastParentRight)
                lastParentLeft :=
                    mul(eq(lastParentLeft, lastNodeKey), lastParentLeft)
            }
            lastParentNode =
                lastParentNode.setRight(lastParentRight).setLeft(lastParentLeft);
            // update parent of old last node
            _update(nodesSlot, lastParentKey, lastParentNode);
        }

        // update lastNode, which is now the root node
        _update(nodesSlot, lastNodeKey, lastNode);
        // delete slot of old root node
        _update(nodesSlot, rootKey, Node.wrap(0));

        // update heap metadata
        HeapMetadata metadata = heap.heapMetadata;
        unchecked {
            metadata =
                metadata.setRoot(lastNodeKey).setSize(metadata.size() - 1);
        }
        heap.heapMetadata = heap.heapMetadata.setRoot(lastNodeKey);

        return (rootNode.value(), lastNodeKey);
    }

    function getRightmostKey(Heap storage heap)
        internal
        view
        returns (uint256)
    {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        uint256 rootKey = heap.heapMetadata.root();
        Node rootNode = _get(nodesSlot, rootKey);
        uint256 rightmostKey = rootKey;
        while (rootNode.right() != EMPTY) {
            rightmostKey = rootNode.right();
            rootNode = _get(nodesSlot, rightmostKey);
        }
    }

    function insert(Heap storage heap, uint256 key, Node node) internal {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        _add(heap, key, node);
        Pointer parentPointer = heap.heapMetadata.insertPointer();
        (uint256 parentKey, bool right) = parentPointer.unpack();
        Node parentNode = _get(nodesSlot, parentKey);
        if (right) {
            parentNode.setRight(key);
        } else {
            parentNode.setLeft(key);
        }

        percUp(heap, key, node); //, parentKey, parentNode, right);
    }

    function percUp(Heap storage heap, uint256 key, Node node) internal {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        HeapMetadata heapMetadata = heap.heapMetadata;
        uint256 parentKey = node.parent();
        Node parentNode = _get(nodesSlot, parentKey);

        while (parentKey != EMPTY) {
            // if node is less than parent, swap
            if (node.value() < parentNode.value()) {
                // decide which side of parent to swap with
                bool isRight = parentNode.right() == key;
                Node tmp;
                if (isRight) {
                    tmp = node.setLeft(parentNode.left()).setRight(parentKey)
                        .setParent(parentNode.parent());
                } else {
                    tmp = node.setLeft(parentKey).setRight(parentNode.right())
                        .setParent(parentNode.parent());
                }
                parentNode = parentNode.setLeft(node.left()).setRight(
                    node.right()
                ).setParent(key);
                node = tmp;
                _update(nodesSlot, key, node);
                _update(nodesSlot, parentKey, parentNode);

                heapMetadata =
                    _updateMetadata(heapMetadata, key, parentKey, isRight);

                parentKey = parentNode.parent();
                parentNode = _get(nodesSlot, parentKey);
            } else {
                // todo: ???
                break;
            }
        }
    }

    function _updateMetadata(
        HeapMetadata heapMetadata,
        uint256 key,
        uint256 parentKey,
        bool isRight
    ) internal returns (HeapMetadata) {
        // update root pointer if necessary
        if (parentKey == heapMetadata.root()) {
            heapMetadata = heapMetadata.setRoot(key);
        }
        // update leftmost pointer if necessary
        if (key == heapMetadata.leftmostNodePointer().key()) {
            heapMetadata = heapMetadata.setLeftmostNodePointer(
                PointerType.createPointer(parentKey, false)
            );
        }
        // update last node pointer if necessary
        if (key == heapMetadata.lastNodePointer().key()) {
            heapMetadata = heapMetadata.setLastNodePointer(
                PointerType.createPointer(parentKey, isRight)
            );
        }
        if (key == heapMetadata.insertPointer().key()) {
            // TODO: assume insertPointer has been udpated at this
            // point, ie, it knows if right leaf is full
            heapMetadata = heapMetadata.setInsertPointer(
                PointerType.createPointer(
                    parentKey, heapMetadata.insertPointer().right()
                )
            );
        }
        if (parentKey == heapMetadata.insertPointer().key()) {
            // i think we can always assume that if swapping with a
            // parent that used to be insert pointer then only the right
            // child is free
            heapMetadata = heapMetadata.setInsertPointer(
                PointerType.createPointer(key, true)
            );
        }
    }

    function getNextInsertPointer(
        Heap storage heap,
        uint256 _size,
        uint256 leftmostNodeKey,
        uint256 lastNodeKey
    ) internal view returns (Pointer pointer) {
        if (allLayersFilled(_size)) {
            // if all layers are filled, we need to add a new layer
            // and add the new node to the leftmost position
            pointer = PointerType.createPointer(leftmostNodeKey, false);
        } else {
            // if all layers are not filled, we need to add the new node
            // to the position to the "right" of the last node (which may be a
            // child of a different parnet)
            pointer = getNextSiblingPointer(heap, lastNodeKey);
        }
    }

    function getNextSiblingPointer(Heap storage heap, uint256 key)
        internal
        view
        returns (Pointer siblingPointer)
    {
        require(!allLayersFilled((heap.heapMetadata.size())), "don't bother");
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        Node node = _get(nodesSlot, key);
        uint256 ancestorKey = node.parent();
        require(ancestorKey != EMPTY, "no parent");
        bool isRight = node.right() == key;
        if (!isRight) {
            // if it's not the right child, then that child is "next"
            return PointerType.createPointer(ancestorKey, true);
        }
        uint256 numAncestors;
        Node ancestorNode;
        Node tempNode;
        uint256 tempKey;
        while (isRight) {
            // load parent node
            tempKey = ancestorKey;
            tempNode = _get(nodesSlot, tempKey);
            ancestorKey = tempNode.parent();
            require(ancestorKey != EMPTY, "no intermediate parent");
            ancestorNode = _get(nodesSlot, ancestorKey);
            isRight = ancestorNode.right() == tempKey;
            unchecked {
                ++numAncestors;
            }
        }
        // when isRight is no longer true, the pointer key  will be the key of
        // leftmost
        // descendent of the ancestor
        tempKey = ancestorNode.right();
        tempNode = _get(nodesSlot, tempKey);
        /**
         * start at 1 since tempNode is already one child below highest
         * ancestor.
         * e.g., starting at key 5, ancestorNode is 1, and tempNode is 3
         *
         *          1
         *        /  \
         *       2    3
         *      / \
         *     4  5
         *
         * e.g. starting at key 11, ancestorNode is 1, and tempNode is 3
         *
         *                1
         *            /       \
         *           2         3
         *         /  \      /  \
         *        4    5    6    7
         *       / \  / \
         *      8  9 10 11
         * 1 is 2 ancestor nodes above 5, but 3 is only 1 ancestor above 6,
         * which
         * is the parent of the next child
         */
        for (uint256 i = 1; i < numAncestors;) {
            tempKey = tempNode.left();
            require(tempKey != EMPTY, "no left child");
            tempNode = _get(nodesSlot, tempKey);
            unchecked {
                ++i;
            }
        }
        // point to left child of leftmost child of the common ancestor
        return PointerType.createPointer(tempKey, false);
    }

    function getPreviousSiblingPointer(Heap storage heap, uint256 key)
        internal
        view
        returns (Pointer siblingPointer)
    {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        Node node = _get(nodesSlot, key);
        uint256 ancestorKey = node.parent();
        require(ancestorKey != EMPTY, "no parent");
        bool isLeft = node.left() == key;
        if (!isLeft) {
            // if it's not the left child, then the left child is the "previous"
            // sibling
            return PointerType.createPointer(ancestorKey, false);
        }
        uint256 numAncestors;
        Node ancestorNode;
        Node tempNode;
        uint256 tempKey;
        while (isLeft) {
            // load parent node
            tempKey = ancestorKey;
            tempNode = _get(nodesSlot, tempKey);
            ancestorKey = tempNode.parent();
            require(ancestorKey != EMPTY, "no intermediate parent");
            ancestorNode = _get(nodesSlot, ancestorKey);
            isLeft = ancestorNode.left() == tempKey;
            unchecked {
                ++numAncestors;
            }
        }
        // when isLeft is no longer true, the pointer key  will be the key of
        // rightmost descendent of the left child of the ancestor
        tempKey = ancestorNode.left();
        tempNode = _get(nodesSlot, tempKey);
        /**
         * start at 1 since tempNode is already one child below highest
         * ancestor.
         * e.g., starting at key 6, ancestorNode is 1, and tempNode is 2
         *
         *          1
         *        /  \
         *       2    3
         *      / \  /
         *     4  5 6
         *
         * e.g. starting at key 12, ancestorNode is 1, and tempNode is 2
         *
         *                1
         *            /       \
         *           2         3
         *         /  \       /  \
         *        4    5     6    7
         *       / \  / \   /
         *      8  9 10 11 12
         */
        for (uint256 i = 1; i < numAncestors;) {
            tempKey = tempNode.right();
            require(tempKey != EMPTY, "no right child");
            tempNode = _get(nodesSlot, tempKey);
            unchecked {
                ++i;
            }
        }
        // point to right child of rightmost child of the common ancestor
        return PointerType.createPointer(tempKey, true);
    }

    function allLayersFilled(uint256 numNodes)
        internal
        pure
        returns (bool _allLayersFilled)
    {
        assembly {
            // all layers are full if numNodes + 1 is a power of 2 (only 1 bit
            // set which does not overlap with others)
            _allLayersFilled := iszero(and(add(1, numNodes), numNodes))
        }
    }

    function commitHeapMetadata(Heap storage heap, HeapMetadata heapMetadata)
        internal
    {
        heap.heapMetadata = heapMetadata;
    }

    function percDown(Heap storage heap, uint256 key, Node node) internal {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        HeapMetadata heapMetadata = heap.heapMetadata;
        uint256 childKey = node.left();
        // right child can only be non-empty if left child is non-empty
        uint256 rightKey = node.right();

        while (childKey != EMPTY) {
            Node child = _get(nodesSlot, childKey);
            // check if it has a right child
            if (rightKey != EMPTY) {
                // if so, retrieve and compare to left child
                Node rightNode = _get(nodesSlot, rightKey);
                // whichever is smaller is suitable to be parent of both
                if (rightNode.value() < child.value()) {
                    child = rightNode;
                    childKey = rightKey;
                }
            }
            // if node val is greater than smallest child, swap
            if (node.value() > child.value()) {
                _swap(nodesSlot, key, node, childKey, child);
                heapMetadata = _updateMetadata(
                    heapMetadata, key, childKey, childKey == rightKey
                );

                // if node was swapped, its new children are old children of
                // child
                childKey = child.left();
                rightKey = child.right();
            } else {
                // no need to continue downward
                break;
            }
        }
    }

    function pop(Heap storage heap) internal returns (uint256) {
        (uint256 rootVal, uint256 newRootKey) = _pop(heap);
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        percDown(heap, newRootKey, _get(nodesSlot, newRootKey));
        return rootVal;
    }

    function peek(Heap storage heap) internal view returns (uint256) {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        return _get(nodesSlot, heap.heapMetadata.root()).value();
    }

    // function buildMinHeap(Heap storage heap, uint256[] memory nodesToBuild)
    //     internal
    // {
    //     uint256[] storage nodes = heap.nodes;
    //     if (nodes.length != 0) {
    //         revert MinHeap__NotEmpty();
    //     }
    //     uint256 _size = nodesToBuild.length;
    //     _copy(nodes, nodesToBuild);
    //     uint256 i = nodesToBuild.length >> 1;
    //     while (i > 0) {
    //         percDown(nodes, i, _size);
    //         unchecked {
    //             --i;
    //         }
    //     }
    // }
}
