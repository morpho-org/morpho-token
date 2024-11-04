// SPDX-License-Identifier: GPL-2.0-or-later

// True when storage has been accessed with either a SSTORE or a SLOAD.
persistent ghost bool hasAccessedStorage;
// True when a CALL has been done after storage has been accessed.
persistent ghost bool hasCallAfterAccessingStorage;
// True when storage has been accessed, after which an external call is made, followed by accessing storage again.
persistent ghost bool hasReentrancyUnsafeCall;

hook ALL_SSTORE(uint loc, uint v) {
    hasAccessedStorage = true;
    hasReentrancyUnsafeCall = hasCallAfterAccessingStorage;
}

hook ALL_SLOAD(uint loc) uint v {
    hasAccessedStorage = true;
    hasReentrancyUnsafeCall = hasCallAfterAccessingStorage;
}

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
        hasCallAfterAccessingStorage = hasAccessedStorage;
}

// Check that no function is accessing storage, then making an external CALL and accessing storage again.
rule reentrancySafe(method f, env e, calldataarg data) {
    // Set up the initial state.
    require !hasAccessedStorage && !hasCallAfterAccessingStorage && !hasReentrancyUnsafeCall;
    f(e,data);
    assert !hasReentrancyUnsafeCall;
}
