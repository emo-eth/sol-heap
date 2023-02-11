// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Node, NodeType } from "./NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "./HeapMetadataType.sol";
import { Pointer, PointerType } from "./PointerType.sol";
import { Heap } from "./Structs.sol";
import { EMPTY } from "./Constants.sol";

library MinHeapMapHelper {
    /**
     * @dev Read the node for a given key
     */
    function _get(uint256 slot, uint256 key) internal returns (Node node) {
        // emit Get(key);
        // require(key != EMPTY, "empty");
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
     * @dev when swapping node with its parent, the grandparent of the node will
     * need to be updated to point to node as a child
     */
    function _updateGrandParent(
        uint256 nodesSlot,
        uint256 key,
        uint256 grandParentKey,
        uint256 replacingParentKey
    ) internal {
        Node parentNode = _get(nodesSlot, grandParentKey);
        if (parentNode.left() == replacingParentKey) {
            parentNode = parentNode.setLeft(key);
        } else {
            parentNode = parentNode.setRight(key);
        }
        _update(nodesSlot, grandParentKey, parentNode);
    }

    /**
     * @dev update a node
     */
    function _updateNodeAndSibling(
        uint256 nodesSlot,
        uint256 key,
        Node node,
        uint256 parentKey,
        Node parentNode,
        uint256 childNewParent
    ) internal returns (Node) {
        bool isRight = parentNode.right() == key;

        //  update node with new parent and left/right children
        node = node.setParent(childNewParent);
        if (isRight) {
            uint256 parentLeft = parentNode.left();
            node = node.setRight(parentKey).setLeft(parentLeft);
            if (parentLeft != EMPTY) {
                Node parentLeftNode = _get(nodesSlot, parentLeft);
                parentLeftNode = parentLeftNode.setParent(key);
                _update(nodesSlot, parentLeft, parentLeftNode);
            }
        } else {
            uint256 parentRight = parentNode.right();
            node = node.setLeft(parentKey).setRight(parentRight);
            if (parentRight != EMPTY) {
                Node parentRightNode = _get(nodesSlot, parentRight);
                parentRightNode = parentRightNode.setParent(key);
                _update(nodesSlot, parentRight, parentRightNode);
            }
        }
        _update(nodesSlot, key, node);
        return node;
    }

    function _updateParent(
        uint256 nodesSlot,
        uint256 key,
        uint256 parentKey,
        Node parentNode,
        uint256 leftChildKey,
        uint256 rightChildKey
    ) internal returns (Node) {
        // update parent node with new parent and left/right children
        parentNode = parentNode.setParent(key).setLeft(leftChildKey).setRight(
            rightChildKey
        );

        // update storage before percolating (which reads from storage)
        _update(nodesSlot, parentKey, parentNode);

        return parentNode;
    }

    function _updateChildrenWithNewParent(
        uint256 nodesSlot,
        uint256 newParent,
        uint256 leftChildKey,
        uint256 rightChildKey
    ) internal {
        if (leftChildKey != EMPTY) {
            Node leftChildNode = _get(nodesSlot, leftChildKey);
            leftChildNode = leftChildNode.setParent(newParent);
            _update(nodesSlot, leftChildKey, leftChildNode);
        }
        if (rightChildKey != EMPTY) {
            Node rightChildNode = _get(nodesSlot, rightChildKey);
            rightChildNode = rightChildNode.setParent(newParent);
            _update(nodesSlot, rightChildKey, rightChildNode);
        }
    }

    /**
     * @dev Swap a child node with its parent node by updating their respective
     * parent and left/right pointers, and update storage
     */
    function _swap(
        uint256 nodesSlot,
        uint256 key,
        Node node,
        uint256 parentKey,
        Node parentNode
    )
        internal
        returns (
            Node updatedFormerChild,
            Node updateFormerParent,
            uint256 grandParentKey
        )
    {
        uint256 childLeftKey = node.left();
        uint256 childRightKey = node.right();

        grandParentKey = parentNode.parent();
        if (grandParentKey != EMPTY) {
            _updateGrandParent(nodesSlot, key, grandParentKey, parentKey);
        }
        _updateChildrenWithNewParent(
            nodesSlot, parentKey, childLeftKey, childRightKey
        );

        node = _updateNodeAndSibling(
            nodesSlot, key, node, parentKey, parentNode, grandParentKey
        );
        parentNode = _updateParent(
            nodesSlot, key, parentKey, parentNode, childLeftKey, childRightKey
        );

        return (node, parentNode, grandParentKey);
    }

    function _swapWithRoot(
        uint256 nodesSlot,
        Node rootNode,
        uint256 lastNodeKey,
        Node lastNode
    ) internal returns (Node) {
        uint256 lastNodeParentKey = lastNode.parent();

        // update root children if they are not the last node
        uint256 rootLeftKey = rootNode.left(); //== lastNodeKey ? EMPTY :
            // rootNode.left();
        uint256 rootRightKey = rootNode.right(); // == lastNodeKey ? EMPTY :
            // rootNode.right();
        if (rootLeftKey != EMPTY && rootLeftKey != lastNodeKey) {
            Node leftNode = _get(nodesSlot, rootLeftKey);
            leftNode = leftNode.setParent(lastNodeKey);
            _update(nodesSlot, rootLeftKey, leftNode);
        }
        if (rootRightKey != EMPTY && rootRightKey != lastNodeKey) {
            Node rightNode = _get(nodesSlot, rootRightKey);
            rightNode = rightNode.setParent(lastNodeKey);
            _update(nodesSlot, rootRightKey, rightNode);
        }

        // update last node parent to point to empty
        Node lastNodeParent = _get(nodesSlot, lastNodeParentKey);
        uint256 lastNodeParentLeft = lastNodeParent.left();
        if (lastNodeParentLeft == lastNodeKey) {
            lastNodeParent = lastNodeParent.setLeft(EMPTY);
        } else {
            lastNodeParent = lastNodeParent.setRight(EMPTY);
        }
        _update(nodesSlot, lastNodeParentKey, lastNodeParent);

        uint256 newLeft = rootLeftKey == lastNodeKey ? EMPTY : rootLeftKey;
        uint256 newRight = rootRightKey == lastNodeKey ? EMPTY : rootRightKey;

        lastNode = lastNode.setParent(EMPTY).setLeft(newLeft).setRight(newRight);
        _update(nodesSlot, lastNodeKey, lastNode);

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
            lastNode = _swapWithRoot({
                nodesSlot: nodesSlot,
                rootNode: rootNode,
                lastNodeKey: lastNodeKey,
                lastNode: lastNode
            });
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

    function getLeftmostKey(Heap storage heap) internal returns (uint256) {
        uint256 nodesSlot = _nodesSlot(heap);
        Node rootNode = _get(nodesSlot, heap.metadata.rootKey());
        uint256 leftmostKey = heap.metadata.rootKey();
        while (rootNode.left() != EMPTY) {
            leftmostKey = rootNode.left();
            rootNode = _get(nodesSlot, rootNode.left());
        }
        return leftmostKey;
    }

    /**
     * @dev Update heap metadata before percolating up after inserting a node
     */
    function _preInsertUpdateHeapMetadata(
        uint256 nodesSlot,
        HeapMetadata metadata,
        uint256 key
    ) internal returns (HeapMetadata) {
        (
            uint256 root,
            uint256 _size,
            uint256 leftmostNodeKey,
            ,
            Pointer insertPointer
        ) = metadata.unpack();

        if (_size == 0) {
            return HeapMetadataType.createHeapMetadata({
                _rootKey: key,
                _size: 1,
                _leftmostNodeKey: key,
                _lastNodeKey: key,
                _insertPointer: PointerType.createPointer({
                    _key: key,
                    _right: false
                })
            });
        }
        unchecked {
            _size += 1;
        }
        if (insertPointer.key() == leftmostNodeKey) {
            leftmostNodeKey = key;
        }
        uint256 insertPointerKey;
        // branchless version of:
        // if (insertPointer.key() == leftmostNodeKey)
        //     leftmostNodeKey = key;
        assembly {
            let areEq := eq(insertPointerKey, leftmostNodeKey)
            leftmostNodeKey :=
                add(mul(areEq, key), mul(iszero(areEq), leftmostNodeKey))
        }

        insertPointer = getNextInsertPointer(
            nodesSlot, _size, leftmostNodeKey, insertPointer
        );

        metadata = HeapMetadataType.createHeapMetadata({
            _rootKey: root,
            _size: _size,
            _leftmostNodeKey: leftmostNodeKey,
            _lastNodeKey: key,
            _insertPointer: insertPointer
        });

        return metadata;
    }

    /**
     * @dev Percolate a node up the heap until heap properties are satisfied.
     */
    function percUp(
        uint256 nodesSlot,
        HeapMetadata metadata,
        uint256 key,
        Node node
    ) internal returns (HeapMetadata) {
        uint256 parentKey = node.parent();
        Node parentNode;
        while (parentKey != EMPTY) {
            parentNode = _get(nodesSlot, parentKey);
            // if node is less than parent, swap
            if (node.value() < parentNode.value()) {
                uint256 newParentKey;
                (node,, newParentKey) =
                    _swap(nodesSlot, key, node, parentKey, parentNode);

                metadata = _updateMetadata(metadata, key, parentKey);
                // node is now in the place of its parent
                parentKey = newParentKey;
            } else {
                // do nothing, since tree above is always already balanced when
                // inserting one element + percolating up
                break;
            }
        }
        return metadata;
    }

    /**
     * @dev Update heap metadata when a key is swapped with its parent.
     */
    function _updateMetadata(
        HeapMetadata metadata,
        uint256 key,
        uint256 parentKey
    ) internal pure returns (HeapMetadata) {
        // update root pointer if necessary
        (
            uint256 rootKey,
            ,
            uint256 leftmostNodeKey,
            uint256 lastNodeKey,
            Pointer insertPointer
        ) = metadata.unpack();
        if (parentKey == rootKey) {
            metadata = metadata.setRootKey(key);
        }
        // update leftmost pointer if necessary
        if (key == leftmostNodeKey) {
            metadata = metadata.setLeftmostNodeKey(parentKey);
        }
        // update last node pointer if necessary
        if (key == lastNodeKey) {
            metadata = metadata.setLastNodeKey(parentKey);
        }
        if (key == insertPointer.key()) {
            // TODO: assume insertPointer has been udpated at this
            // point, ie, it knows if right leaf is full
            metadata = metadata.setInsertPointer(
                PointerType.createPointer(parentKey, insertPointer.right())
            );
        } else if (parentKey == insertPointer.key()) {
            // i think we can always assume that if swapping with a
            // parent that used to be insert pointer then only the right
            // child is free
            metadata =
                metadata.setInsertPointer(PointerType.createPointer(key, true));
        }
        return metadata;
    }

    /**
     * Pre-emptively update heap metadata before popping the root, returning the
     * old root key and last node key.
     */
    function _prePopUpdateMetadata(uint256 nodesSlot, HeapMetadata metadata)
        internal
        returns (uint256, uint256, HeapMetadata)
    {
        (
            uint256 oldRootKey,
            uint256 _size,
            uint256 leftmostNodeKey,
            uint256 oldLastNodeKey,
            Pointer insertPointer
        ) = metadata.unpack();

        // uint256 rootKey = originalRootKey;
        // uint256 lastNodeKey = originalLastNodeKey;
        uint256 originalSize = _size;

        // if popping root, metadata becomes empty
        if (oldRootKey == oldLastNodeKey) {
            return (oldRootKey, oldLastNodeKey, HeapMetadata.wrap(0));
        }

        bool poppingLeftChildOfRoot = insertPointer.key() == oldRootKey;
        bool poppingChildOfRoot;
        {
            Node rootNode = _get(nodesSlot, oldRootKey);
            poppingChildOfRoot =
                poppingLeftChildOfRoot || rootNode.right() == oldLastNodeKey;
        }
        uint256 newLastNodeKey;

        if (poppingChildOfRoot) {
            if (poppingLeftChildOfRoot) {
                // if popping left child - insert pointer is left child of new
                // root
                insertPointer = PointerType.createPointer(oldLastNodeKey, false);
                // leftmost node becomes new root
                leftmostNodeKey = oldLastNodeKey;
                // new last node is new root
                newLastNodeKey = oldLastNodeKey;
            } else {
                // otherwise new insert pointer is the right child of the new
                // root
                insertPointer = PointerType.createPointer(oldLastNodeKey, true);
                // and the new last node is the old leftmost node
                newLastNodeKey = leftmostNodeKey;
            }
        } else {
            insertPointer = getPreviousInsertPointer(
                nodesSlot, originalSize, oldRootKey, insertPointer
            );

            if (insertPointer.key() == oldRootKey) {
                insertPointer = PointerType.createPointer(
                    oldLastNodeKey, insertPointer.right()
                );
            }

            // update lastNode pointer; either left sibling, or rightmost node
            if (leftmostNodeKey == oldLastNodeKey) {
                newLastNodeKey = getRightmostKey(nodesSlot, oldRootKey);
                // if the leftmost node has been removed, the new leftmost node
                // is
                // the parent of the old leftmost node
                Node previousLeftmostNode = _get(nodesSlot, leftmostNodeKey);
                leftmostNodeKey = previousLeftmostNode.parent();
            } else {
                // otherwise it's the "previous" node
                newLastNodeKey =
                    getPreviousSiblingKey(nodesSlot, oldLastNodeKey);
            }
        }

        unchecked {
            _size = _size - 1;
        }

        metadata = HeapMetadataType.createHeapMetadata({
            _rootKey: oldLastNodeKey,
            _size: _size,
            _leftmostNodeKey: leftmostNodeKey,
            _lastNodeKey: newLastNodeKey,
            _insertPointer: insertPointer
        });

        return (oldRootKey, oldLastNodeKey, metadata);
    }

    /**
     * @dev Get the child pointer where the next inserted node should go in the
     * heap.
     */
    function getNextInsertPointer(
        uint256 nodesSlot,
        uint256 _size,
        uint256 leftmostNodeKey,
        Pointer insertPointer
    ) internal returns (Pointer pointer) {
        if (allLayersFilled(_size)) {
            // if all layers are filled, we need to add a new layer
            // and add the new node to the leftmost position
            pointer = PointerType.createPointer(leftmostNodeKey, false);
        } else {
            // if all layers are not filled, we need to add the new node
            // to the position to the "right" of the last node (which may be a
            // child of a different parent)
            pointer = getNextSiblingPointer(nodesSlot, insertPointer);
        }
    }

    function getPreviousInsertPointer(
        uint256 nodesSlot,
        uint256 _size,
        uint256 rootKey,
        Pointer insertPointer
    ) internal returns (Pointer pointer) {
        if (insertPointer.right()) {
            return PointerType.createPointer(insertPointer.key(), false);
        } else if (allLayersFilled(_size)) {
            uint256 rightmostNodeKey = getRightmostKey(nodesSlot, rootKey);
            Node rightmostNode = _get(nodesSlot, rightmostNodeKey);
            return PointerType.createPointer(rightmostNode.parent(), true);
        } else {
            uint256 previousSiblingKey =
                getPreviousSiblingKey(nodesSlot, insertPointer.key());
            return PointerType.createPointer(previousSiblingKey, true);
        }
    }

    /**
     * @dev Get the child pointer to the next sibling of the node at the given
     * key. Used when inserting a node.
     */
    function getNextSiblingPointer(uint256 nodesSlot, Pointer nextInsertPointer)
        internal
        returns (Pointer siblingPointer)
    {
        // Node node = _get(nodesSlot, key);
        (uint256 ancestorKey, bool isRight) = nextInsertPointer.unpack();
        // uint256 ancestorKey = node.parent();
        require(ancestorKey != EMPTY, "no parent");
        // bool isRight = node.right() == key;
        if (!isRight) {
            // if it's not the right child, then that child is "next"
            return PointerType.createPointer(ancestorKey, true);
        }
        uint256 numAncestors;
        Node ancestorNode = _get(nodesSlot, ancestorKey);
        uint256 tempKey;
        while (isRight) {
            // load parent node
            tempKey = ancestorKey;
            ancestorKey = ancestorNode.parent();
            if (ancestorKey == EMPTY) {
                break;
            }
            // require(ancestorKey != EMPTY, "no intermediate parent");
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
        Node tempNode = _get(nodesSlot, tempKey);
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
     * never leftmost key). Used when removing the last node.
     */
    function getPreviousSiblingKey(uint256 nodesSlot, uint256 key)
        internal
        returns (uint256 siblingKey)
    {
        Node node = _get(nodesSlot, key);
        uint256 ancestorKey = node.parent();
        require(ancestorKey != EMPTY, "no parent");
        Node ancestorNode = _get(nodesSlot, ancestorKey);
        uint256 ancestorLeftChild = ancestorNode.left();
        bool isLeft = ancestorLeftChild == key;
        if (!isLeft) {
            // if it's not the left child, then the left child is the "previous"
            // sibling
            return ancestorLeftChild;
        }
        uint256 numAncestors;
        uint256 tempKey;
        while (isLeft) {
            // load parent node
            tempKey = ancestorKey;
            ancestorKey = ancestorNode.parent();
            if (ancestorKey == EMPTY) {
                // we have reached the root; break
                break;
            }
            // require(ancestorKey != EMPTY, "no intermediate parent");
            ancestorNode = _get(nodesSlot, ancestorKey);
            isLeft = ancestorNode.left() == tempKey;
            unchecked {
                ++numAncestors;
            }
        }
        // when isLeft is no longer true, the pointer key will be the key of
        // rightmost descendent of the left child of the ancestor
        tempKey = ancestorNode.left();
        Node tempNode = _get(nodesSlot, tempKey);
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
        for (uint256 i = 0; i < numAncestors;) {
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
     * @dev Determine if all layers of the heap are filled. Used when computing
     * insertion pointer.
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
        HeapMetadata metadata,
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
                (, node,) = _swap(nodesSlot, childKey, child, key, node);
                metadata = _updateMetadata(metadata, childKey, key);

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
        return metadata;
    }

    function _nodesSlot(Heap storage heap) internal pure returns (uint256) {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        return nodesSlot;
    }
}