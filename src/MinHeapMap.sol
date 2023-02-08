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

    function _update(uint256 nodesSlot, uint256 key, Node node) internal {
        assembly {
            mstore(0, key)
            mstore(0x20, nodesSlot)
            sstore(keccak256(0, 0x40), node)
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

        uint256 parentLeft = parentNode.left();
        uint256 parentRight = parentNode.right();
        uint256 parentNewLeft = childNode.left();
        uint256 parentNewRight = childNode.right();
        {
            uint256 childNewLeft;
            uint256 childNewRight;
            assembly {
                // if child is right node, set child left to parent left and
                // child
                // right to parent

                // do this in a branchless way by multiplying respective values
                // by
                // isRight and its inverse and adding them
                // if child is left - new left is parent, otherwise parentLeft
                childNewLeft :=
                    add(mul(iszero(isRight), parentKey), mul(isRight, parentLeft))
                // if child is right - new right is parent, otherwise
                // parentRight
                childNewRight :=
                    add(mul(isRight, parentKey), mul(iszero(isRight), parentRight))
            }
            childNode = childNode.setParent(childNewParent);
            childNode = childNode.setLeft(childNewLeft);
            childNode = childNode.setRight(childNewRight);
        }

        parentNode = parentNode.setParent(childKey).setLeft(parentNewLeft)
            .setRight(parentNewRight);

        _update(nodesSlot, childKey, childNode);
        _update(nodesSlot, parentKey, parentNode);
    }

    function _updateChildrenParentPointers(
        uint256 nodesSlot,
        Node parentNode,
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

    function _pop(uint256 nodesSlot, uint256 oldRoot, HeapMetadata heapMetadata)
        internal
        returns (uint256 oldRootVal, uint256 newRootKey, Node newRoot)
    {
        uint256 lastNodeKey = heapMetadata.lastNodeKey();
        uint256 rootKey = heapMetadata.root();
        Node lastNode;
        Node rootNode;
        if (rootKey != EMPTY) {
            lastNode = _get(nodesSlot, lastNodeKey);
            rootNode = _get(nodesSlot, rootKey);
            // update root's childrens' parent pointers
            _updateChildrenParentPointers(nodesSlot, rootNode, lastNodeKey);
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
                lastParentNode = lastParentNode.setRight(lastParentRight)
                    .setLeft(lastParentLeft);
                // update parent of old last node
                _update(nodesSlot, lastParentKey, lastParentNode);
            }

            // update lastNode, which is now the root node
            _update(nodesSlot, lastNodeKey, lastNode);
        } else {
            rootNode = _get(nodesSlot, oldRoot);
            lastNode = Node.wrap(0);
        }
        // delete slot of old root node
        _update(nodesSlot, rootKey, Node.wrap(0));

        return (rootNode.value(), lastNodeKey, lastNode);
    }

    function getRightmostKey(uint256 nodesSlot, uint256 rootKey)
        internal
        view
        returns (uint256)
    {
        Node rootNode = _get(nodesSlot, rootKey);
        uint256 rightmostKey = rootKey;
        while (rootNode.right() != EMPTY) {
            rightmostKey = rootNode.right();
            rootNode = _get(nodesSlot, rightmostKey);
        }
        return rightmostKey;
    }

    function insert(Heap storage heap, uint256 key, uint256 nodeValue)
        internal
    {
        uint256 nodesSlot = _nodesSlot(heap);
        HeapMetadata heapMetadata = heap.heapMetadata;
        uint256 parentKey = EMPTY;
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
                _root: key,
                _size: 1,
                _leftmostNodeKey: key,
                _lastNodeKey: key,
                _insertPointer: PointerType.createPointer(key, false)
            });
        }
        Node newNode = NodeType.createNode({
            _value: nodeValue,
            _parent: parentKey,
            _left: EMPTY,
            _right: EMPTY
        });

        _update(nodesSlot, key, newNode);

        heap.heapMetadata = percUp(nodesSlot, heapMetadata, key, newNode); //,
            // parentKey, parentNode, right);
    }

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

    function _updateMetadata(
        HeapMetadata heapMetadata,
        uint256 key,
        uint256 parentKey
    ) internal pure returns (HeapMetadata) {
        // update root pointer if necessary
        if (parentKey == heapMetadata.root()) {
            heapMetadata = heapMetadata.setRoot(key);
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
        returns (uint256, HeapMetadata)
    {
        uint256 rootKey = heapMetadata.root();
        uint256 lastNodeKey = heapMetadata.lastNodeKey();
        if (rootKey == lastNodeKey) {
            return (rootKey, HeapMetadata.wrap(0));
        }

        // update root pointer
        heapMetadata = heapMetadata.setRoot(lastNodeKey);

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
                getPreviousSiblingPointer(nodesSlot, lastNodeKey)
            );
        }
        unchecked {
            heapMetadata = heapMetadata.setSize(heapMetadata.size() - 1);
        }

        return (rootKey, heapMetadata);
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
            // child of a different parnet)
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

    function getPreviousSiblingPointer(uint256 nodesSlot, uint256 key)
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
        return tempKey;
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
                // whichever is smaller is suitable to be parent of both
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
                // no need to continue downward
                break;
            }
        }
        return heapMetadata;
    }

    function pop(Heap storage heap) internal returns (uint256) {
        uint256 nodesSlot = _nodesSlot(heap);
        (uint256 oldRoot, HeapMetadata heapMetadata) =
            _prePopUpdateMetadata(nodesSlot, heap.heapMetadata);
        (uint256 rootVal, uint256 newRootKey, Node newRoot) =
            _pop(nodesSlot, oldRoot, heapMetadata);
        percDown(nodesSlot, heapMetadata, newRootKey, newRoot);
        heap.heapMetadata = heapMetadata;
        return rootVal;
    }

    function peek(Heap storage heap) internal view returns (uint256) {
        return _get(_nodesSlot(heap), heap.heapMetadata.root()).value();
    }

    function _nodesSlot(Heap storage heap) internal pure returns (uint256) {
        uint256 nodesSlot;
        assembly {
            nodesSlot := heap.slot
        }
        return nodesSlot;
    }
}
