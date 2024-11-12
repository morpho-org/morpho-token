// SPDX-License-Identifier: GPL-2.0-or-later

// True when a CALL has been placed.
persistent ghost bool hasExternalCall  {
    init_state axiom hasExternalCall == false;
}

// True when a DELEGATECALL has been placed.
persistent ghost bool hasDelegateCall {
    init_state axiom hasDelegateCall == false;
}

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
        hasExternalCall = true;
}

hook DELEGATECALL(uint g, address addr, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    hasDelegateCall = true;
}

// Check that the contract is reentrant safe as it makes no external call.
invariant reentrancySafe()
  !hasExternalCall;

// Check that the contract makes no delegate call.
invariant noDelegateCalls()
  !hasDelegateCall
  filtered {
      f -> f.selector != sig:upgradeToAndCall(address, bytes).selector
  }
