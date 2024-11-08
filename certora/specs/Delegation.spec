import "ERC20.spec";

ghost mathint sumOfVotingPower {
    init_state axiom sumOfVotingPower == 0;
}

// Slot for DelegationTokenStorage._delegatedVotingPower
hook Sload uint256 votingPower (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address addr] {
    require sumOfVotingPower >= to_mathint(votingPower);
}

// Slot for DelegationTokenStorage._delegatedVotingPower
hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address addr] uint256 newValue (uint256 oldValue) {
    sumOfVotingPower = sumOfVotingPower - oldValue + newValue;
}

// Check that zero address has no voting power assuming that zero address can't make transactions.
invariant zeroAddressNoVotingPower()
    delegatee(0x0) == 0x0 && delegatedVotingPower(0x0) == 0
    filtered {
      // Ignore upgrades.
      f-> f.selector != sig:upgradeToAndCall(address, bytes).selector
    }
    { preserved with (env e) { require e.msg.sender != 0; } }

// Check that the voting power is never greater than the total supply of tokens.
invariant totalSupplyLTEqSumOfVotingPower()
    to_mathint(totalSupply()) == sumOfVotingPower + currentContract._zeroVirtualVotingPower
    filtered {
      // Ignore upgrades.
      f-> f.selector != sig:upgradeToAndCall(address, bytes).selector
    }
    {
      preserved  with (env e) {
          requireInvariant totalSupplyIsSumOfBalances();
          requireInvariant zeroAddressNoVotingPower();
      }
    }

// Check that user can restore their voting power by delegating to zero address then delgating back to themselves.
rule delgatingSelfConsistent {
    requireInvariant totalSupplyLTEqSumOfVotingPower();
    env e;
    address user = e.msg.sender;

    // Safe require as the user can't possibly be zero.
    require user != 0;

    // Ensure that user has delegated to zero address.
    require delegatee(user) == 0;

    mathint sumOfVotingPowerBefore = sumOfVotingPower  + currentContract._zeroVirtualVotingPower;
    mathint delegatedBefore = delegatedVotingPower(user);

    delegate(e, user);

    // Check that no extra voting power hasn't been created.
    assert sumOfVotingPowerBefore == sumOfVotingPower  + currentContract._zeroVirtualVotingPower;
    // Check that the voting power has been restored.
    assert delegatedVotingPower(user) == balanceOf(user) + delegatedBefore;
}
