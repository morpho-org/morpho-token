// SPDX-License-Identifier: GPL-2.0-or-later
import "ERC20.spec";

methods {
    function delegatorFromSig(DelegationToken.Delegation, DelegationToken.Signature) external returns address envfree;
    function delegationNonce(address) external returns uint256 envfree;
}

// Ghost variable to hold the sum of voting power.
ghost mathint sumOfVotingPower {
    init_state axiom sumOfVotingPower == 0;
}

// Ghost copy of DelegationTokenStorage._delegatedVotingPower.
ghost mapping(address => uint256) ghost_delegatedVotingPower {
    init_state axiom forall address account. ghost_delegatedVotingPower[account] == 0;
}

hook Sload uint256 votingPower (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] {
    require ghost_delegatedVotingPower[account] == votingPower;
}

// Slot is DelegationTokenStorage._delegatedVotingPower.
hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] uint256 votingPower (uint256 votingPowerOld) {
    // Update DelegationTokenStorage._delegatedVotingPower
    ghost_delegatedVotingPower[account] = votingPower;
    // Track changes of total voting power.
    sumOfVotingPower = sumOfVotingPower - votingPowerOld + votingPower;
}

// Check that zero address has no voting power assuming that zero address can't make transactions.
invariant zeroAddressNoVotingPower()
    delegatee(0x0) == 0x0 && delegatedVotingPower(0x0) == 0
    { preserved with (env e) { require e.msg.sender != 0; } }

function isTotalSupplyGTEqSumOfVotingPower() returns bool {
    requireInvariant totalSupplyIsSumOfVirtualVotingPower();
    return totalSupply() >= sumOfVotingPower;
}

// Check that the total supply of tokens is greater than or equal to the sum of voting power.
rule totalSupplyGTEqSumOfVotingPower {
    assert isTotalSupplyGTEqSumOfVotingPower();
}

// Check that initially zero votes are delegated to parameterized address A.
invariant sumOfVotesStartsAtZero()
    sumsOfVotes[0] == 0;

invariant sumOfVotesGrowsCorrectly()
    forall address account. sumsOfVotes[to_mathint(account) + 1] ==
    sumsOfVotes[to_mathint(account)] + (ghost_delegatee[account] == A ? ghost_balances[account] : 0) ;

invariant sumOfVotesMonotone()
    forall mathint i. forall mathint j. i <= j => sumsOfVotes[i] <= sumsOfVotes[j]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
        }
    }

invariant delegatedLTEqPartialSum()
    forall address account. ghost_delegatee[account] == A =>
      ghost_balances[account] <= sumsOfVotes[to_mathint(account)+1]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
        }
    }


invariant sumOfVotesIsDelegatedToA()
    sumsOfVotes[2^160] == ghost_delegatedVotingPower[A]
    {
        preserved {
            requireInvariant zeroAddressNoVotingPower();
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
        }
    }

invariant delegatedLTEqDelegateeVP()
    forall address account.
      ghost_delegatee[account] == A =>
      ghost_balances[account] <= ghost_delegatedVotingPower[A]
    {
        preserved with (env e){
            requireInvariant zeroAddressNoVotingPower();
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
            requireInvariant delegatedLTEqPartialSum();
            requireInvariant sumOfVotesIsDelegatedToA();
        }
    }

// Check that the voting power plus the virtual voting power of address zero is equal to the total supply of tokens.
invariant totalSupplyIsSumOfVirtualVotingPower()
    to_mathint(totalSupply()) == sumOfVotingPower + currentContract._zeroVirtualVotingPower
    {
      preserved {
          // Safe requires because the proxy contract should be initialized right after construction.
          require totalSupply() == 0;
          require sumOfVotingPower == 0;
          require forall address a. ghost_balances[a] == 0;
          requireInvariant totalSupplyIsSumOfBalances();
          requireInvariant zeroAddressNoVotingPower();
      }
    }

// Check that users can delegate their voting power.
rule delegatingUpdatesVotingPower(env e, address newDelegatee) {
    requireInvariant zeroAddressNoVotingPower();
    assert isTotalSupplyGTEqSumOfVotingPower();

    address oldDelegatee = delegatee(e.msg.sender);

    mathint delegatedVotingPowerBefore = delegatedVotingPower(newDelegatee);

    delegate(e, newDelegatee);

    // Check that, if the delegatee changed and it's not the zero address then its voting power is greater than or equal to the delegator's balance, otherwise its voting power remains unchanged.
    if ((newDelegatee == 0) || (newDelegatee == oldDelegatee)) {
        assert delegatedVotingPower(newDelegatee) == delegatedVotingPowerBefore;
    } else {
        assert delegatedVotingPower(newDelegatee) == delegatedVotingPowerBefore + balanceOf(e.msg.sender);
    }
}

// Check that users can delegate their voting power.
rule delegatingWithSigUpdatesVotingPower(env e, DelegationToken.Delegation delegation, DelegationToken.Signature signature) {
    requireInvariant zeroAddressNoVotingPower();
    assert isTotalSupplyGTEqSumOfVotingPower();

    address delegator = delegatorFromSig(delegation, signature);

    address oldDelegatee = delegatee(delegator);
    mathint delegationNonceBefore = delegationNonce(delegator);

    mathint delegatedVotingPowerBefore = delegatedVotingPower(delegation.delegatee);

    delegateWithSig(e, delegation, signature);

    // Check that the delegation's nonce matches the delegator's nonce.
    assert delegation.nonce == delegationNonceBefore;
    // Check that the current block timestamp is not later than the delegation's expiry timestamp.
    assert e.block.timestamp <= delegation.expiry;

    // Check that, if the delegatee changed and it's not the zero address then its voting power is greater than or equal to the delegator's balance, otherwise its voting power remains unchanged.
    if ((delegation.delegatee == 0) || (delegation.delegatee == oldDelegatee)) {
        assert delegatedVotingPower(delegation.delegatee) == delegatedVotingPowerBefore;
    } else {
        assert delegatedVotingPower(delegation.delegatee) == delegatedVotingPowerBefore + balanceOf(delegator);
    }
}
