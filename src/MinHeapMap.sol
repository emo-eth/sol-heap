// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Node, NodeType } from "./lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "./lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "./lib/PointerType.sol";

library MinHeapMap {
    error MinHeap__Empty();
    error MinHeap__NotEmpty();

    // uint32 keys should be non-zero
    uint256 constant EMPTY = 0;

    ///@dev A heap is a binary tree where each node is smaller than its
    /// children.
    struct Heap {
        ///@dev A mapping of keys to nodes. A Node contains a uint160 value as
        /// well as uint32 pointers to its parent, left child, and right child.
        mapping(uint256 => Node) nodes;
        ///@dev A packed UDT containing root key, heap size, leftmost node key,
        /// last node key, and a Pointer UDT where the next node should be
        /// inserted
        HeapMetadata heapMetadata;
    }

    function size(Heap storage heap) internal view returns (uint256 _size) {
        HeapMetadata heapMetadata;
        assembly {
            heapMetadata := sload(add(heap.slot, 1))
        }
        _size = heapMetadata.size();
    }

    /**
     * @dev Read the node for a given key
     */
    function _get(uint256 slot, uint256 key)
        internal
        view
        returns (Node node)
    {
        assembly {
            // derive mapping slot from key
            mstore(0, key)
            mstore(0x20, slot)
            // read node from mapping slot
            node := sload(keccak256(0, 0x40))
        }
    }

    /**
     * @dev Update (overwrite) the node for a given key
     */
    function _update(uint256 nodesSlot, uint256 key, Node node) internal {
        assembly {
            mstore(0, key)
            mstore(0x20, nodesSlot)
            sstore(keccak256(0, 0x40), node)
        }
    }

    /**
     * @dev Swap a child node with its parent node by updating their respective
     * parent and left/right pointers, and update storage
     */
    function _swap(
        uint256 nodesSlot,
        uint256 childKey,
        Node childNode,
        uint256 parentKey,
        Node parentNode
    ) internal {
        bool isRight = parentNode.right() == childKey;
        uint256 childNewParent = parentNode.parent();

        // cache these values since we need to update them respectively
        uint256 parentLeft = parentNode.left();
        uint256 parentRight = parentNode.right();
        uint256 parentNewLeft = childNode.left();
        uint256 parentNewRight = childNode.right();
        // block scope to avoid stacc2dank
        {
            // one of parent's left or right is the child; we can calculate this
            // branchlessly
            uint256 childNewLeft;
            uint256 childNewRight;
            assembly {
                // if child is right node, set child left to parent left and
                // child right to parent
                // if child is left - new left is parent, otherwise parentLeft
                childNewLeft :=
                    add(
                        mul(
                            // "is left"
                            iszero(isRight),
                            // left is parent
                            parentKey
                        ),
                        mul(
                            // "is not left"
                            isRight,
                            // left is parent left
                            parentLeft
                        )
                    )
                // if child is right - new right is parent, otherwise
                // parentRight
                childNewRight :=
                    add(
                        mul(
                            // "is right"
                            isRight,
                            // right is parent
                            parentKey
                        ),
                        mul(
                            // "is not right"
                            iszero(isRight),
                            // right is parent right
                            parentRight
                        )
                    )
            }
            childNode = childNode.setParent(childNewParent);
            childNode = childNode.setLeft(childNewLeft);
            childNode = childNode.setRight(childNewRight);
        }

        parentNode = parentNode.setParent(childKey).setLeft(parentNewLeft)
            .setRight(parentNewRight);

        // update storage before percolating (which reads from storage)
        _update(nodesSlot, childKey, childNode);
        _update(nodesSlot, parentKey, parentNode);
    }

    /**
     * @dev update the parent pointers of the children of a node. Used when
     * popping an element off the top of the heap, which replaces the top node
     * with the last node
     *
     * @param nodesSlot the slot of the nodes mapping (cached for efficiency)
     * @param leftChildKey the key of the left child node
     * @param rightChildKey the key of the right child node
     * @param newParentKey the key of the new parent node
     */
    function _updateChildrenParentPointers(
        uint256 nodesSlot,
        uint256 leftChildKey,
        uint256 rightChildKey,
        uint256 newParentKey
    ) internal {
        // use branches since unnecessary sloads are more costly, even if warm
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

    function _swapWithRoot(
        uint256 nodesSlot,
        Node rootNode,
        uint256 lastKey,
        Node lastNode
    ) internal returns (Node updatedLastNode) {
        uint256 leftChildOfRoot = rootNode.left();
        uint256 rightChildOfRoot = rootNode.right();
        uint256 newLeftKey;
        uint256 newRightKey;
        assembly {
            newLeftKey :=
                mul(
                    // if "is not left child of root"
                    iszero(eq(leftChildOfRoot, lastKey)),
                    // old left child, else empty
                    leftChildOfRoot
                )
            newRightKey :=
                mul(
                    // if "is not right child of root"
                    iszero(eq(rightChildOfRoot, lastKey)),
                    // old right child, else empty
                    rightChildOfRoot
                )
        }
        lastNode =
            lastNode.setParent(EMPTY).setLeft(newLeftKey).setRight(newRightKey);
        _updateChildrenParentPointers(
            nodesSlot, newLeftKey, newRightKey, lastKey
        );
        return lastNode;
    }

    /**
     * @dev Pop the root node off the heap, replacing it with the last node
     *
     * @param nodesSlot the slot of the nodes mapping (cached for efficiency)
     * @param rootKey the key of the old root node
     * @param lastNodeKey the key of the old last node
     *
     * @return oldRootVal the uint160 value of the old root node
     * @return newRootKey the key of the new root node
     * @return newRoot the new root node
     */
    function _pop(uint256 nodesSlot, uint256 rootKey, uint256 lastNodeKey)
        internal
        returns (uint256 oldRootVal, uint256 newRootKey, Node newRoot)
    {
        Node lastNode;
        Node rootNode;
        // if the root is not last node (ie popping last element off heap),
        // update heap
        if (rootKey != lastNodeKey) {
            lastNode = _get(nodesSlot, lastNodeKey);
            rootNode = _get(nodesSlot, rootKey);
            lastNode = _swapWithRoot(nodesSlot, rootNode, lastNodeKey, lastNode);
            // update lastNode, which is now the root node
            _update(nodesSlot, lastNodeKey, lastNode);
        } else {
            rootNode = _get(nodesSlot, rootKey);
            lastNode = Node.wrap(0);
        }
        // delete slot of old root node
        _update(nodesSlot, rootKey, Node.wrap(0));

        return (rootNode.value(), lastNodeKey, lastNode);
    }

    /**
     * @dev Get the key of the rightmost node in the heap. Used when deleting
     * leftmost node to find new lastNode.
     */
    function getRightmostKey(uint256 nodesSlot, uint256 rootKey)
        internal
        view
        returns (uint256)
    {
        Node rootNode = _get(nodesSlot, rootKey);
        // if no right child, root is rightmost
        uint256 rightmostKey = rootKey;
        while (rootNode.right() != EMPTY) {
            // set first to avoid overwriting with EMPTY
            rightmostKey = rootNode.right();
            rootNode = _get(nodesSlot, rightmostKey);
        }
        return rightmostKey;
    }

    /**
     * @dev Wrap a value into a node and insert it into the last position of the
     * heap, then percolate the node up until heap properties are satisfied.
     */
    function insert(Heap storage heap, uint256 key, uint256 nodeValue)
        internal
    {
        uint256 nodesSlot = _nodesSlot(heap);
        HeapMetadata heapMetadata = heap.heapMetadata;
        // todo: consider pre-updating heap metadata
        uint256 parentKey = EMPTY;
        // if it is not the first node in the heap
        if (heapMetadata.size() > 0) {
            unchecked {
                heapMetadata = heapMetadata.setSize(heapMetadata.size() + 1);
            }

            Pointer parentPointer = heapMetadata.insertPointer();
            bool right;
            (parentKey, right) = parentPointer.unpack();
            Node parentNode = _get(nodesSlot, parentKey);
            if (right) {
                parentNode.setRight(key);
            } else {
                parentNode.setLeft(key);
            }
        } else {
            heapMetadata = HeapMetadataType.createHeapMetadata({
                _rootKey: key,
                _size: 1,
                _leftmostNodeKey: key,
                _lastNodeKey: key,
                _insertPointer: PointerType.createPointer(key, false)
            });
        }
        // create node for new value and update it in the nodes mapping
        Node newNode = NodeType.createNode({
            _value: nodeValue,
            _parent: parentKey,
            _left: EMPTY,
            _right: EMPTY
        });
        _update(nodesSlot, key, newNode);

        // percolate new node up in the heap and store updated heap metadata
        heap.heapMetadata = percUp(nodesSlot, heapMetadata, key, newNode);
    }

    /**
     * @dev Percolate a node up the heap until heap properties are satisfied.
     */
    function percUp(
        uint256 nodesSlot,
        HeapMetadata heapMetadata,
        uint256 key,
        Node node
    ) internal returns (HeapMetadata) {
        uint256 parentKey = node.parent();
        Node parentNode;
        while (parentKey != EMPTY) {
            parentNode = _get(nodesSlot, parentKey);
            // if node is less than parent, swap
            if (node.value() < parentNode.value()) {
                // decide which side of parent to swap with
                bool isRight = parentNode.right() == key;
                Node tmp;
                uint256 newParentKey = parentNode.parent();
                if (isRight) {
                    tmp = node.setLeft(parentNode.left()).setRight(parentKey)
                        .setParent(newParentKey);
                } else {
                    tmp = node.setLeft(parentKey).setRight(parentNode.right())
                        .setParent(newParentKey);
                }
                parentNode = parentNode.setLeft(node.left()).setRight(
                    node.right()
                ).setParent(key);
                node = tmp;
                _update(nodesSlot, key, node);
                _update(nodesSlot, parentKey, parentNode);

                heapMetadata = _updateMetadata(heapMetadata, key, parentKey);
                // node is now in the place of its parent
                parentKey = newParentKey;
                parentNode = _get(nodesSlot, parentKey);
            } else {
                // do nothing, since tree above is always already balanced when
                // inserting one element + percolating up
                break;
            }
        }
        return heapMetadata;
    }

    /**
     * @dev Update heap metadata when a key is swapped with its parent.
     */
    function _updateMetadata(
        HeapMetadata heapMetadata,
        uint256 key,
        uint256 parentKey
    ) internal pure returns (HeapMetadata) {
        // update root pointer if necessary
        if (parentKey == heapMetadata.rootKey()) {
            heapMetadata = heapMetadata.setRootKey(key);
        }
        // update leftmost pointer if necessary
        if (key == heapMetadata.leftmostNodeKey()) {
            heapMetadata = heapMetadata.setLeftmostNodeKey(parentKey);
        }
        // update last node pointer if necessary
        if (key == heapMetadata.lastNodeKey()) {
            heapMetadata = heapMetadata.setLastNodeKey(parentKey);
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
        return heapMetadata;
    }

    function _prePopUpdateMetadata(uint256 nodesSlot, HeapMetadata heapMetadata)
        internal
        view
        returns (uint256 oldRootKey, uint256 oldLastNodeKey, HeapMetadata)
    {
        uint256 rootKey = heapMetadata.rootKey();
        uint256 lastNodeKey = heapMetadata.lastNodeKey();
        // if popping root, metadata becomes empty
        if (rootKey == lastNodeKey) {
            return (rootKey, lastNodeKey, HeapMetadata.wrap(0));
        }

        // update root pointer
        heapMetadata = heapMetadata.setRootKey(lastNodeKey);

        // update lastNode pointer; either left sibling, or rightmost node
        if (heapMetadata.leftmostNodeKey() == lastNodeKey) {
            heapMetadata =
                heapMetadata.setLastNodeKey(getRightmostKey(nodesSlot, rootKey));

            // if the leftmost node has been removed, the new leftmost node is
            // the parent of the old leftmost node
            Node previousLeftmostNode = _get(nodesSlot, lastNodeKey);
            uint256 leftmostParent = previousLeftmostNode.parent();
            heapMetadata = heapMetadata.setLeftmostNodeKey(leftmostParent);
        } else {
            heapMetadata = heapMetadata.setLastNodeKey(
                getPreviousSiblingKey(nodesSlot, lastNodeKey)
            );
        }

        unchecked {
            heapMetadata = heapMetadata.setSize(heapMetadata.size() - 1);
        }
        heapMetadata = heapMetadata.setInsertPointer(
            getNextInsertPointer(
                nodesSlot,
                heapMetadata.size(),
                heapMetadata.leftmostNodeKey(),
                heapMetadata.lastNodeKey()
            )
        );

        return (rootKey, lastNodeKey, heapMetadata);
    }

    function getNextInsertPointer(
        uint256 nodesSlot,
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
            // child of a different parent)
            pointer = getNextSiblingPointer(nodesSlot, lastNodeKey);
        }
    }

    function getNextSiblingPointer(uint256 nodesSlot, uint256 key)
        internal
        view
        returns (Pointer siblingPointer)
    {
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

    /**
     * @dev get the key of a node's "previous" sibling (NOTE: assumes key is
     * never leftmost key)
     */
    function getPreviousSiblingKey(uint256 nodesSlot, uint256 key)
        internal
        view
        returns (uint256 siblingKey)
    {
        Node node = _get(nodesSlot, key);
        uint256 ancestorKey = node.parent();
        require(ancestorKey != EMPTY, "no parent");
        Node ancestor = _get(nodesSlot, ancestorKey);
        uint256 ancestorLeftChild = ancestor.left();
        bool isLeft = ancestorLeftChild == key;
        if (!isLeft) {
            // if it's not the left child, then the left child is the "previous"
            // sibling
            return ancestorLeftChild;
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
        // when isLeft is no longer true, the pointer key will be the key of
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
        return tempKey;
    }

    /**
     * @dev Determine if all layers of the heap are filled.
     */
    function allLayersFilled(uint256 numNodes)
        internal
        pure
        returns (bool _allLayersFilled)
    {
        assembly {
            // all layers are full if numNodes + 1 is a power of 2 (only 1 bit
            // set which does not overlap with others)
            // e.g. heap with 1 element is full, 3 elements is full, 7 elements
            // is full... etc. 1 & 2 == 3 & 4 == 7 & 8 == 0
            _allLayersFilled := iszero(and(add(1, numNodes), numNodes))
        }
    }

    /**
     * @dev Percolate a node down the heap to satisfy heap properties.
     */
    function percDown(
        uint256 nodesSlot,
        HeapMetadata heapMetadata,
        uint256 key,
        Node node
    ) internal returns (HeapMetadata) {
        uint256 childKey = node.left();
        // right child can only be non-empty if left child is non-empty
        uint256 rightKey = node.right();

        while (childKey != EMPTY) {
            Node child = _get(nodesSlot, childKey);
            // check if it has a right child
            if (rightKey != EMPTY) {
                // if so, retrieve and compare to left child
                Node rightNode = _get(nodesSlot, rightKey);
                // whichever is smaller is suitable to be parent of both parent
                // and sibling (if parent is larger)
                if (rightNode.value() < child.value()) {
                    child = rightNode;
                    childKey = rightKey;
                }
            }
            // if node val is greater than smallest child, swap
            if (node.value() > child.value()) {
                _swap(nodesSlot, key, node, childKey, child);
                heapMetadata = _updateMetadata(heapMetadata, key, childKey);

                // if node was swapped, its new children are old children of
                // child
                childKey = child.left();
                rightKey = child.right();
            } else {
                // assuming tree was constructed correctly, no need to continue
                // downward
                break;
            }
        }
        return heapMetadata;
    }

    /**
     * @notice Remove the root node and return its value.
     */
    function pop(Heap storage heap) internal returns (uint256) {
        uint256 nodesSlot = _nodesSlot(heap);
        // pre-emptively update with new root and new lastNode
        (uint256 oldRootKey, uint256 oldLastNodeKey, HeapMetadata heapMetadata)
        = _prePopUpdateMetadata(nodesSlot, heap.heapMetadata);
        // swap root with last node and delete root node
        (uint256 rootVal, uint256 newRootKey, Node newRoot) =
            _pop(nodesSlot, oldRootKey, oldLastNodeKey);
        // percolate new root downwards through tree
        percDown(nodesSlot, heapMetadata, newRootKey, newRoot);
        heap.heapMetadata = heapMetadata;
        return rootVal;
    }

    /**
     * @notice Get the value of the root node without removing it.
     */
    function peek(Heap storage heap) internal view returns (uint256) {
        return _get(_nodesSlot(heap), heap.heapMetadata.rootKey()).value();
    }

    function update(Heap storage heap, uint256 key, uint256 newValue)
        internal
    {
        uint256 nodesSlot = _nodesSlot(heap);
        Node node = _get(nodesSlot, key);
        uint256 oldValue = node.value();
        if (newValue == oldValue) {
            return;
        }
        // set new value and update
        node = node.setValue(newValue);
        // todo: write first?
        _update(nodesSlot, key, node);
        // if new value is less than old value, percolate up to satisfy minHeap
        // properties
        if (newValue < oldValue) {
            percUp(nodesSlot, heap.heapMetadata, key, node);
        } else {
            // else percolateDown to satisfy minHeap properties
            percDown(nodesSlot, heap.heapMetadata, key, node);
        }
    }

    function _nodesSlot(Heap storage heap) internal pure returns (uint256) {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        return nodesSlot;
    }
}
