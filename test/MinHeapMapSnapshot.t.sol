// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";
import { MinHeapMap } from "../src/MinHeapMap.sol";
import { Node, NodeType } from "../src/lib/NodeType.sol";
import { HeapMetadata, HeapMetadataType } from "../src/lib/HeapMetadataType.sol";
import { Pointer, PointerType } from "../src/lib/PointerType.sol";
import { Heap } from "../src/lib/Structs.sol";
import { MinHeapMapHelper as Helper } from "../src/lib/MinHeapMapHelper.sol";
import { LibPRNG } from "solady/utils/LibPRNG.sol";

contract MinHeapMapSnapshotTest is BaseTest {
    using MinHeapMap for Heap;
    using Helper for Heap;

    Heap private heap;
    Heap private _100kHeap;
    Heap private _10kHeap;
    Heap private _1kHeap;
    Heap private _100Heap;
    Heap private _10Heap;
    LibPRNG.PRNG prng;

    function setUp() public virtual override {
        for (uint256 i = 1; i <= 100_000; i++) {
            _100kHeap.insert(i, i);
        }
        for (uint256 i = 1; i <= 10_000; i++) {
            _10kHeap.insert(i, i);
        }
        for (uint256 i = 1; i <= 1000; i++) {
            _1kHeap.insert(i, i);
        }
        for (uint256 i = 1; i <= 100; i++) {
            _100Heap.insert(i, i);
        }
        for (uint256 i = 1; i <= 10; i++) {
            _10Heap.insert(i, i);
        }
    }

    function test_snapshotPop100kRoot() public {
        _100kHeap.pop();
    }

    function test_snapshotPop10kRoot() public {
        _10kHeap.pop();
    }

    function test_snapshotPop1kRoot() public {
        _1kHeap.pop();
    }

    function test_snapshotPop100Root() public {
        _100Heap.pop();
    }

    function test_snapshotPop10Root() public {
        _10Heap.pop();
    }

    function test_snapshotInsert1kDescending() public {
        for (uint256 i = 1000; i > 0; i--) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert10kDescending() public {
        for (uint256 i = 10_000; i > 0; i--) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert100Descending() public {
        for (uint256 i = 100; i > 0; i--) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert10Descending() public {
        for (uint256 i = 10; i > 0; i--) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert10Ascending() public {
        for (uint256 i = 1; i <= 10; i++) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert100Ascending() public {
        for (uint256 i = 1; i <= 100; i++) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert1kAscending() public {
        for (uint256 i = 1; i <= 1000; i++) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert10kAscending() public {
        for (uint256 i = 1; i <= 10_000; i++) {
            heap.insert(i, i);
        }
    }

    function test_snapshotInsert10Alternating() public {
        for (uint256 i = 1; i <= 10 / 2; i++) {
            heap.insert(i, i);
            heap.insert(11 - i, 11 - i);
        }
    }

    function test_snapshotInsert100Alternating() public {
        for (uint256 i = 1; i <= 100 / 2; i++) {
            heap.insert(i, i);
            heap.insert(101 - i, 101 - i);
        }
    }

    function test_snapshotInsert1kAlternating() public {
        for (uint256 i = 1; i <= 1000 / 2; i++) {
            heap.insert(i, i);
            heap.insert(1001 - i, 1001 - i);
        }
    }

    function test_snapshotInsert10kAlternating() public {
        for (uint256 i = 1; i <= 10_000 / 2; i++) {
            heap.insert(i, i);
            heap.insert(10_001 - i, 10_001 - i);
        }
    }

    function test_snapshotInsert10Diverging() public {
        uint256 median = uint256(10) / 2;
        for (uint256 i = 0; i < median; i++) {
            uint256 low = median - i;
            uint256 high = median + i + 1;
            heap.insert(low, low);
            heap.insert(high, high);
        }
    }

    function test_snapshotInsert100Diverging() public {
        uint256 median = uint256(100) / 2;
        for (uint256 i = 0; i < median; i++) {
            uint256 low = median - i;
            uint256 high = median + i + 1;
            heap.insert(low, low);
            heap.insert(high, high);
        }
    }

    function test_snapshotInsert1kDiverging() public {
        uint256 median = uint256(1000) / 2;
        for (uint256 i = 0; i < median; i++) {
            uint256 low = median - i;
            uint256 high = median + i + 1;
            heap.insert(low, low);
            heap.insert(high, high);
        }
    }

    function test_snapshotInsert10kDiverging() public {
        uint256 median = uint256(10_000) / 2;
        for (uint256 i = 0; i < median; i++) {
            uint256 low = median - i;
            uint256 high = median + i + 1;
            heap.insert(low, low);
            heap.insert(high, high);
        }
    }

    function test_snapshotUpdateMedianMin100k() public {
        uint256 median = uint256(100_000) / 2;
        uint256 newVal = 0;
        _100kHeap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMax100k() public {
        uint256 median = uint256(100_000) / 2;
        uint256 newVal = 100_001;
        _100kHeap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMin10k() public {
        uint256 median = uint256(10_000) / 2;
        uint256 newVal = 0;
        _10kHeap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMax10k() public {
        uint256 median = uint256(10_000) / 2;
        uint256 newVal = 10_001;
        _10kHeap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMin1k() public {
        uint256 median = uint256(1000) / 2;
        uint256 newVal = 0;
        _1kHeap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMax1k() public {
        uint256 median = uint256(1000) / 2;
        uint256 newVal = 1001;
        _1kHeap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMin100() public {
        uint256 median = uint256(100) / 2;
        uint256 newVal = 0;
        _100Heap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMax100() public {
        uint256 median = uint256(100) / 2;
        uint256 newVal = 101;
        _100Heap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMin10() public {
        uint256 median = uint256(10) / 2;
        uint256 newVal = 0;
        _10Heap.update(median, newVal);
    }

    function test_snapshotUpdateMedianMax10() public {
        uint256 median = uint256(10) / 2;
        uint256 newVal = 11;
        _10Heap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMin100k() public {
        uint256 median = uint256(100_000) / 4;
        uint256 newVal = 0;
        _100kHeap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMax100k() public {
        uint256 median = uint256(100_000) / 4;
        uint256 newVal = 100_001;
        _100kHeap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMin10k() public {
        uint256 median = uint256(10_000) / 4;
        uint256 newVal = 0;
        _10kHeap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMax10k() public {
        uint256 median = uint256(10_000) / 4;
        uint256 newVal = 10_001;
        _10kHeap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMin1k() public {
        uint256 median = uint256(1000) / 4;
        uint256 newVal = 0;
        _1kHeap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMax1k() public {
        uint256 median = uint256(1000) / 4;
        uint256 newVal = 1001;
        _1kHeap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMin100() public {
        uint256 median = uint256(100) / 4;
        uint256 newVal = 0;
        _100Heap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMax100() public {
        uint256 median = uint256(100) / 4;
        uint256 newVal = 101;
        _100Heap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMin10() public {
        uint256 median = uint256(10) / 4;
        uint256 newVal = 0;
        _10Heap.update(median, newVal);
    }

    function test_snapshotUpdateFirstQuartileMax10() public {
        uint256 median = uint256(10) / 4;
        uint256 newVal = 11;
        _10Heap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMin100k() public {
        uint256 median = uint256(100_000) / 4 * 3;
        uint256 newVal = 0;
        _100kHeap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMax100k() public {
        uint256 median = uint256(100_000) / 4 * 3;
        uint256 newVal = 100_001;
        _100kHeap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMin10k() public {
        uint256 median = uint256(10_000) / 4 * 3;
        uint256 newVal = 0;
        _10kHeap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMax10k() public {
        uint256 median = uint256(10_000) / 4 * 3;
        uint256 newVal = 10_001;
        _10kHeap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMin1k() public {
        uint256 median = uint256(1000) / 4 * 3;
        uint256 newVal = 0;
        _1kHeap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMax1k() public {
        uint256 median = uint256(1000) / 4 * 3;
        uint256 newVal = 1001;
        _1kHeap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMin100() public {
        uint256 median = uint256(100) / 4 * 3;
        uint256 newVal = 0;
        _100Heap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMax100() public {
        uint256 median = uint256(100) / 4 * 3;
        uint256 newVal = 101;
        _100Heap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMin10() public {
        uint256 median = uint256(10) / 4 * 3;
        uint256 newVal = 0;
        _10Heap.update(median, newVal);
    }

    function test_snapshotUpdateThirdQuartileMax10() public {
        uint256 median = uint256(10) / 4 * 3;
        uint256 newVal = 11;
        _10Heap.update(median, newVal);
    }
}
