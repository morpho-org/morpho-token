// SPDX-License-Identifier: GPL-2.0-or-later

// True when a delegate call has been placed.
persistent ghost bool delegateCall;

hook DELEGATECALL(uint g, address addr, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    delegateCall = true;
}

// Check that the contract is truly immutable.
rule noDelegateCalls(method f, env e, calldataarg data) filtered {
    f -> f.selector != sig:upgradeToAndCall(address, bytes memory).selector
} {
    // Set up the initial state.
    require !delegateCall;
    f(e,data);
    assert !delegateCall;
}
