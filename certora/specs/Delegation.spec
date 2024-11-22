import "ERC20.spec";

// ghost copy of balances
ghost mapping(address => uint256) ghost_balances {
    init_state axiom forall address addr. ghost_balances[addr] == 0;
}

hook Sload uint256 balance (slot 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00)[KEY address addr] {
    require ghost_balances[addr] == balance;
}

//Slot is ERC20Storage._balances slot
hook Sstore (slot 0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00)[KEY address addr] uint256 newValue (uint256 oldValue) {
    ghost_balances[addr] = newValue;
}

// ghost copy of delegatees
ghost mapping(address => address) ghost_delegatees {
    init_state axiom forall address addr. ghost_delegatees[addr] == 0;
}

hook Sload address _delegatee (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1100)[KEY address account] {
    require ghost_delegatees[account] == _delegatee;
}

hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1100)[KEY address account] address _delegatee (address _delegatee_old) {
    ghost_delegatees[account] = _delegatee;
}

// Partial sum of voting power.
//  sumOfvotes[x] = \sum_{i=0}^{x-1} delegatedVotingPower[i];
ghost mapping(mathint => mathint) sumsOfVotes {
    init_state axiom forall mathint addr. sumsOfVotes[addr] == 0;
}

// ghost copy of votingPower
ghost mapping(address => uint256) ghost_delegatedVotingPower {
    init_state axiom forall address addr. ghost_delegatedVotingPower[addr] == 0;
}

hook Sload uint256 _votingPower (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] {
    require ghost_delegatedVotingPower[account] == _votingPower;
}

hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] uint256 _votingPower (uint256 _votingPower_old) {
    // update partial sums for x > to_mathint(account)
    havoc sumsOfVotes assuming
        forall mathint x. sumsOfVotes@new[x] ==
            sumsOfVotes@old[x] + (to_mathint(account) < x ? _votingPower - _votingPower_old : 0);
    ghost_delegatedVotingPower[account] = _votingPower;
}

invariant sumOfVotesStartsAtZero()
    sumsOfVotes[0] == 0;

invariant sumOfVotesGrowsCorrectly()
    forall address addr. sumsOfVotes[to_mathint(addr) + 1] ==
        sumsOfVotes[to_mathint(addr)] + ghost_delegatedVotingPower[addr];

invariant sumOfVotesMonotone()
    forall mathint i. forall mathint j. i <= j => sumsOfVotes[i] <= sumsOfVotes[j]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
        }
    }

invariant sumOfVotesMonotone2()
    forall address i. forall address j. to_mathint(i)+1 == to_mathint(j) && to_mathint(j) <= 2^160 => sumsOfVotes[to_mathint(j)] - sumsOfVotes[to_mathint(i)]  == ghost_delegatedVotingPower[j]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
        }
    }


invariant sumOfVotesLTEqTotalSupply()
    sumsOfVotes[2^160] + currentContract._zeroVirtualVotingPower == to_mathint(totalSupply())
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
        }
    }

invariant Y()
    forall address a. forall address b.
    a != 1 && ghost_delegatedVotingPower[a] == 0  &&
    (ghost_delegatees[b] == 0 || ghost_delegatees[b] == 1) =>
    ghost_delegatedVotingPower[1] == sumsOfVotes[1]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
            requireInvariant sumOfVotesLTEqTotalSupply();
        }
    }


invariant X(address holder)
    ghost_delegatees[holder] == 1  =>
    ghost_delegatedVotingPower[1] == sumsOfVotes[1] &&
    ghost_delegatedVotingPower[1] >= ghost_balances[holder]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
            requireInvariant sumOfVotesLTEqTotalSupply();
        }
    }

ghost mathint sumOfVotingPower {
    init_state axiom sumOfVotingPower == 0;
}

// // Slot for DelegationTokenStorage._delegatedVotingPower
// hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address addr] uint256 newValue (uint256 oldValue) {
//     sumOfVotingPower = sumOfVotingPower - oldValue + newValue;
// }

// Check that zero address has no voting power assuming that zero address can't make transactions.
invariant zeroAddressNoVotingPower()
    delegatee(0x0) == 0x0 && delegatedVotingPower(0x0) == 0
    { preserved with (env e) { require e.msg.sender != 0; } }

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

function isTotalSupplyGTEqSumOfVotingPower() returns bool {
    requireInvariant totalSupplyIsSumOfVirtualVotingPower();
    return totalSupply() >= sumOfVotingPower;
}

// Check that the total supply of tokens is greater than or equal to the sum of voting power.
rule totalSupplyGTEqSumOfVotingPower {
    assert isTotalSupplyGTEqSumOfVotingPower();
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
