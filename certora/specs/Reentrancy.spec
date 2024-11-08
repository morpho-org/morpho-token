// SPDX-License-Identifier: GPL-2.0-or-later

// True when a CALL has been done.
persistent ghost bool hasExternalCall  {
    init_state axiom hasExternalCall == false;
}

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
        hasExternalCall = true;
}

// Check that no function is making an external CALL.
invariant reentrancySafe()
  !hasExternalCall;
