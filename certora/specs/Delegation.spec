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

// Check that the voting power plus the virtual voting power of address zero is equal to the total supply of tokens.
invariant totalSupplyIsSumOfVirtualVotingPower()
    to_mathint(totalSupply()) == sumOfVotingPower + currentContract._zeroVirtualVotingPower
    filtered {
      // Ignore upgrades.
      f-> f.selector != sig:upgradeToAndCall(address, bytes).selector
    }
    {
      preserved {
          requireInvariant totalSupplyIsSumOfBalances();
          requireInvariant zeroAddressNoVotingPower();
      }
    }

// Check that the total supply of tokens is greater than or equal to the sum of voting power.
invariant totalSupplyGTEqSumOfVotingPower()
    totalSupply() >= sumOfVotingPower
    filtered {
      // Ignore upgrades.
      f-> f.selector != sig:upgradeToAndCall(address, bytes).selector
    }
    {
      preserved {
          requireInvariant totalSupplyIsSumOfVirtualVotingPower();
      }
    }

// Check that users can delegate their voting power.
rule delgatingUpdatesVotingPower {
    requireInvariant totalSupplyGTEqSumOfVotingPower();
    requireInvariant zeroAddressNoVotingPower();

    env e;

    // Safe require as the msg.sender can't possibly be zero.
    require e.msg.sender == zero;

    address delegator = e.msg.sender;
    address newDelegatee;
    address oldDelegatee = delegatee(delegator);

    mathint delegatedVotingPowerBeforeOfNewDelegatee = delegatedVotingPower(newDelegatee);

    delegate(e, newDelegatee);

    // Check that, if the delegatee changed and it's not the zero address then its voting power is greater than or equal to the delegator's balance, otherwise its voting power remains unchanged.
    if ((newDelegatee == 0) || (newDelegatee == oldDelegatee)) {
           assert delegatedVotingPower(newDelegatee) == delegatedVotingPowerBeforeOfNewDelegatee;
    } else {
           assert delegatedVotingPower(newDelegatee) >= balanceOf(delegator);
    }
}
