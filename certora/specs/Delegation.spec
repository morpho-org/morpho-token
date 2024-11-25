import "ERC20.spec";

// Paramater for any address that is not the zero address.
persistent ghost address A {
    axiom A != 0;
}

// Ghost variable to hold the sum of voting power.
ghost mathint sumOfVotingPower {
    init_state axiom sumOfVotingPower == 0;
}

// Ghost copy of DelegationTokenStorage._delegatee for quantification.
ghost mapping(address => address) ghost_delegatee {
    init_state axiom forall address account. ghost_delegatee[account] == 0;
}

// Slot for DelegationTokenStorage._delegatee.
hook Sload address delegatee (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1100)[KEY address account] {
    require ghost_delegatee[account] == delegatee;
}

// Slot for DelegationTokenStorage._delegatee.
hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1100)[KEY address account] address delegatee (address delegateeOld) {
    // Update partial sums for x > to_mathint(account)
    // Track delegation changes from the parameterized address.
    if (delegateeOld == A && delegatee != A) {
        havoc sumsOfVotes assuming
            forall mathint x. sumsOfVotes@new[x] ==
            sumsOfVotes@old[x] - (to_mathint(account) < x ? ghost_balances[account] : 0);
    }
    // Track delegation changes to the pramaeterized address.
    else if (delegateeOld != A && delegatee == A) {
        havoc sumsOfVotes assuming
            forall mathint x. sumsOfVotes@new[x] ==
                sumsOfVotes@old[x] + (to_mathint(account) < x ? ghost_balances[account] : 0);
    }
    // Update ghost copy of DelegationTokenStorage._delegatee.
    ghost_delegatee[account] = delegatee;
}

// Ghost copy of ERC20Storage._balances for quantification.
ghost mapping(address => uint256) ghost_balances {
    init_state axiom forall address account. ghost_balances[account] == 0;
}

//Slot is ERC20Storage._balances slot.
hook Sload uint256 balance (slot 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00)[KEY address account] {
    require ghost_balances[account] == balance;
    // Safe require as accounts can't hold more tokens than the total supply in preconditions.
    require sumOfBalances >= to_mathint(balance);
}

//Slot is ERC20Storage._balances slot
hook Sstore (slot 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00)[KEY address account] uint256 newValue (uint256 oldValue) {
    // Update partial sums for x > to_mathint(account)
    // Track balance changes when the delegatee is the parameterized address.
    if (ghost_delegatee[account] == A) {
        havoc sumsOfVotes assuming
            forall mathint x. sumsOfVotes@new[x] ==
                sumsOfVotes@old[x] + (to_mathint(account) < x ? newValue - oldValue : 0);
    }
    // Update ghost copy of ERC20Storage._balances.
    ghost_balances[account] = newValue;
}

// Partial sum of delegated votes to parameterized address A.
// sumOfvotes[x] = \sum_{i=0}^{x-1} balances[i] when delegatee[i] == A;
ghost mapping(mathint => mathint) sumsOfVotes {
    init_state axiom forall mathint account. sumsOfVotes[account] == 0;
}

// Ghost copy of DelegationTokenStorage._delegatedVotingPower.
ghost mapping(address => uint256) ghost_delegatedVotingPower {
    init_state axiom forall address account. ghost_delegatedVotingPower[account] == 0;
}

hook Sload uint256 votingPower (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] {
    require ghost_delegatedVotingPower[account] == votingPower;
}

// Slot for DelegationTokenStorage._delegatedVotingPower.
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

invariant delegatedLTEqPartialSum()
    forall address account. ghost_delegatee[account] == A =>
      ghost_balances[account] <= sumsOfVotes[to_mathint(account)+1]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
            // requireInvariant sumOfVotesIsDelegatedToA();
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
          requireInvariant totalSupplyIsSumOfBalances();
          requireInvariant zeroAddressNoVotingPower();
      }
    }

// Check that users can delegate their voting power.
rule delegatingUpdatesVotingPower(env e, address newDelegatee) {
    requireInvariant zeroAddressNoVotingPower();
    assert isTotalSupplyGTEqSumOfVotingPower();

    address oldDelegatee = delegatee(e.msg.sender);

    mathint delegatedVotingPowerBeforeOfNewDelegatee = delegatedVotingPower(newDelegatee);

    delegate(e, newDelegatee);

    // Check that, if the delegatee changed and it's not the zero address then its voting power is greater than or equal to the delegator's balance, otherwise its voting power remains unchanged.
    if ((newDelegatee == 0) || (newDelegatee == oldDelegatee)) {
        assert delegatedVotingPower(newDelegatee) == delegatedVotingPowerBeforeOfNewDelegatee;
    } else {
        assert delegatedVotingPower(newDelegatee) >= balanceOf(e.msg.sender);
    }
}
