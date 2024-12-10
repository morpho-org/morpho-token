// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function delegatee(address) external returns address envfree;
    function delegatedVotingPower(address) external returns uint256 envfree;
    function upgradeToAndCall(address, bytes) external => NONDET DELETE;
}

// Paramater for any address that is not the zero address.
persistent ghost address A {
    axiom A != 0;
}

// Ghost variable to hold the sum of delegated votes to parameterized address A.
// To reason exhaustively on the value of of delegated voting power we proceed to compute the partial sum of delegated votes to parametre A for each possible address.
// We call the partial sum of votes to parameter A up to an addrress a, to sum of delegated votes to parameter A for all addresses within the range [0..a[.
// Formally, we write ∀ a:address, sumsOfVotesDelegatedToA[a] = Σ balanceOf(i), where the sum ranges over addresses i such that i < a and delegatee(i) = A, provided that the address zero holds no voting power and that it never performs transactions.
// With this approach, we are able to write and check more abstract properties about the computation of the total delegated voting power using universal quantifiers.
// From this follows the property such that, ∀ a:address, delegatee(a) = A ⇒ balanceOf(a) ≤ delegatedVotingPower(A).
// In particular, we have the equality sumsOfVotesDelegatedToA[2^160] = delegatedVotingPower(A).
// Finally, we reason by parametricity to observe since we have ∀ a:address, delegatee(a) = A ⇒ balanceOf(a) ≤ delegatedVotingPower(A).
// We also have ∀ A:address, ∀ a:address, A ≠ 0 ∧ delegatee(a) = A ⇒ balanceOf(a) ≤ delegatedVotingPower(A), which is what we want to show.

// sumOfvotes[x] = \sum_{i=0}^{x-1} balances[i] when delegatee[i] == A;
ghost mapping(mathint => mathint) sumsOfVotesDelegatedToA {
    init_state axiom forall mathint account. sumsOfVotesDelegatedToA[account] == 0;
}

// Ghost copy of DelegationTokenStorage._delegatee for quantification.
ghost mapping(address => address) ghostDelegatee {
    init_state axiom forall address account. ghostDelegatee[account] == 0;
}

// Slot is DelegationTokenStorage._delegatee.
hook Sload address delegatee (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1100)[KEY address account] {
    require ghostDelegatee[account] == delegatee;
}

// Slot is DelegationTokenStorage._delegatee.
hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1100)[KEY address account] address delegatee (address delegateeOld) {
    mathint changeOfAccountVotesForA;
    // Track delegation changes from the parameterized address.
    if (delegateeOld == A && delegatee != A) {
        require changeOfAccountVotesForA == - ghostBalances[account];
    // Track delegation changes to the prameterized address.
    } else if (delegateeOld != A && delegatee == A) {
        require changeOfAccountVotesForA == ghostBalances[account];
    } else {
        require changeOfAccountVotesForA == 0;
    }
    // Update partial sums for x > to_mathint(account)
    havoc sumsOfVotesDelegatedToA assuming
        forall mathint x. sumsOfVotesDelegatedToA@new[x] ==
        sumsOfVotesDelegatedToA@old[x] + (to_mathint(account) < x ? changeOfAccountVotesForA : 0);
    // Update ghost copy of DelegationTokenStorage._delegatee.
    ghostDelegatee[account] = delegatee;
}

// Ghost variable to hold the sum of balances.
// To reason exhaustively on the value of the sum of balances we proceed to compute the partial sum of balances for each possible address.
// We call the partial sum of balances up to an addrress a, to sum of balances for all addresses within the range [0..a[.
// Formally, we write ∀ a:address, sumOfBalances[a] = Σ balanceOf(i) where the sum ranges over addresses i < a, provided that the address zero holds no token and that it never performs transactions.
// With this approach, we are able to write and check more abstract properties about the computation of the total supply of tokens using universal quantifiers.
// From this follows the property such that, ∀ a:address, balanceOf(a) ≤ totalSupply().
// In particular we have the equality, sumOfBalances[2^160] = totalSupply() and we are able to to show that the sum of two different balances is lesser than or equal to the total supply.
ghost mapping(mathint => mathint) sumOfBalances {
    init_state axiom forall mathint addr. sumOfBalances[addr] == 0;
}

// Ghost copy of ERC20Storage._balances for quantification.
ghost mapping(address => uint256) ghostBalances {
    init_state axiom forall address account. ghostBalances[account] == 0;
}

// Slot is ERC20Storage._balances slot.
hook Sload uint256 balance (slot 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00)[KEY address account] {
    require ghostBalances[account] == balance;
}

// Slot is ERC20Storage._balances slot
hook Sstore (slot 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00)[KEY address account] uint256 newValue (uint256 oldValue) {
    // Update partial sum of balances, for x > to_mathint(account)
    // Track balance changes in balances.
    havoc sumOfBalances assuming
        forall mathint x. sumOfBalances@new[x] ==
            sumOfBalances@old[x] + (to_mathint(account) < x ? newValue - oldValue : 0);
    // Update partial sums of votes delegated to the parameterized address, for x > to_mathint(account)
    // Track balance changes when the delegatee is the parameterized address.
    if (ghostDelegatee[account] == A) {
        havoc sumsOfVotesDelegatedToA assuming
            forall mathint x. sumsOfVotesDelegatedToA@new[x] ==
                sumsOfVotesDelegatedToA@old[x] + (to_mathint(account) < x ? newValue - oldValue : 0);
    }
    // Update ghost copy of ERC20Storage._balances.
    ghostBalances[account] = newValue;
}

invariant sumOfBalancesStartsAtZero()
    sumOfBalances[0] == 0;

invariant sumOfBalancesGrowsCorrectly()
    forall address addr. sumOfBalances[to_mathint(addr) + 1] ==
        sumOfBalances[to_mathint(addr)] + ghostBalances[addr];

invariant sumOfBalancesMonotone()
    forall mathint i. forall mathint j. i <= j => sumOfBalances[i] <= sumOfBalances[j]
    {
        preserved {
            requireInvariant sumOfBalancesStartsAtZero();
            requireInvariant sumOfBalancesGrowsCorrectly();
        }
    }

// Check that the sum of balances equals the total supply.
invariant totalSupplyIsSumOfBalances()
    sumOfBalances[2^160] == to_mathint(totalSupply())
    {
        preserved {
            requireInvariant sumOfBalancesStartsAtZero();
            requireInvariant sumOfBalancesGrowsCorrectly();
            requireInvariant sumOfBalancesMonotone();
        }
    }

invariant balancesLTEqTotalSupply()
    forall address a. ghostBalances[a] <= sumOfBalances[2^160]
    {
        preserved {
            requireInvariant sumOfBalancesStartsAtZero();
            requireInvariant sumOfBalancesGrowsCorrectly();
            requireInvariant sumOfBalancesMonotone();
            requireInvariant totalSupplyIsSumOfBalances();
        }
    }

rule twoBalancesCannotExceedTotalSupply(address accountA, address accountB) {
    requireInvariant sumOfBalancesStartsAtZero();
    requireInvariant sumOfBalancesGrowsCorrectly();
    requireInvariant sumOfBalancesMonotone();
    requireInvariant totalSupplyIsSumOfBalances();
    uint256 balanceA = balanceOf(accountA);
    uint256 balanceB = balanceOf(accountB);

    assert accountA != accountB =>
        balanceA + balanceB <= to_mathint(totalSupply());
    satisfy(accountA != accountB && balanceA > 0 && balanceB > 0);
}

// Check that zero address's balance is equal to zero.
invariant zeroAddressNoBalance()
    balanceOf(0) == 0;
