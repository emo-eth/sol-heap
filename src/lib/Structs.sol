// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Node, NodeType } from "./NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "./HeapMetadataType.sol";

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
