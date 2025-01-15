// SPDX-License-Identifier: GPL-2.0-or-later
import "ERC20.spec";

methods {
    function delegatorFromSig(DelegationToken.Delegation, DelegationToken.Signature) external returns address envfree;
    function delegationNonce(address) external returns uint256 envfree;
}

// Ghost variable to hold the sum of voting power.
// To reason exhaustively on the value of the sum of voting power we proceed to compute the partial sum of voting power for each possible address.
// We call the partial sum of balances up to an addrress a, to sum of balances for all addresses within the range [0..a[.
// Formally, we write ∀ a:address, sumOfVotes[a] = Σ delegatedVotingPower(i) where the sum ranges over addresses i < a, provided that the address zero holds no token and that it never performs transactions.
// With this approach, we are able to write and check more abstract properties about the computation of the total voting power using universal quantifiers.
// From this follows the property such that, ∀ a:address, delegatedVotingpower(a) ≤ total sum of votes.
// In particular, we are able to to show that the sum voting powers of two different accounts is lesser than or equal to the total sum of votes.
ghost mapping (mathint => mathint) sumOfVotes {
    init_state axiom forall mathint account. sumOfVotes[account] == 0;
}

// Ghost copy of DelegationTokenStorage._delegatedVotingPower.
ghost mapping(address => uint256) ghostDelegatedVotingPower {
    init_state axiom forall address account. ghostDelegatedVotingPower[account] == 0;
}

hook Sload uint256 votingPower (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] {
    require ghostDelegatedVotingPower[account] == votingPower;
}

// Slot is DelegationTokenStorage._delegatedVotingPower.
hook Sstore (slot 0x669be2f4ee1b0b5f3858e4135f31064efe8fa923b09bf21bf538f64f2c3e1101)[KEY address account] uint256 votingPower (uint256 votingPowerOld) {
    // Update DelegationTokenStorage._delegatedVotingPower
    ghostDelegatedVotingPower[account] = votingPower;
    // Track balance changes in sum of votes.
    havoc sumOfVotes assuming
        forall mathint x. sumOfVotes@new[x] ==
            sumOfVotes@old[x] + (to_mathint(account) < x ? votingPower - votingPowerOld : 0);
}

// Check that zero address has no voting power assuming that zero address can't make transactions.
invariant zeroAddressNoVotingPower()
    delegatee(0x0) == 0x0 && delegatedVotingPower(0x0) == 0
    { preserved with (env e) { require e.msg.sender != 0; } }

// Check that initially zero votes are delegated to parameterized address A.
invariant sumOfVotesDelegatedToAStartsAtZero()
    sumsOfVotesDelegatedToA[0] == 0;

invariant sumOfVotesDelegatedToAGrowsCorrectly()
    forall address account. sumsOfVotesDelegatedToA[to_mathint(account) + 1] ==
    sumsOfVotesDelegatedToA[to_mathint(account)] + (ghostDelegatee[account] == A ? ghostBalances[account] : 0) ;

invariant sumOfVotesDelegatedToAMonotone()
    forall mathint i. forall mathint j. i <= j => sumsOfVotesDelegatedToA[i] <= sumsOfVotesDelegatedToA[j]
    {
        preserved {
            requireInvariant sumOfVotesDelegatedToAStartsAtZero();
            requireInvariant sumOfVotesDelegatedToAGrowsCorrectly();
        }
    }

invariant delegatedLTEqPartialSum()
    forall address account. ghostDelegatee[account] == A =>
      ghostBalances[account] <= sumsOfVotesDelegatedToA[to_mathint(account)+1]
    {
        preserved {
            requireInvariant sumOfVotesDelegatedToAStartsAtZero();
            requireInvariant sumOfVotesDelegatedToAGrowsCorrectly();
            requireInvariant sumOfVotesDelegatedToAMonotone();
        }
    }


invariant sumOfVotesDelegatedToAIsDelegatedToA()
    sumsOfVotesDelegatedToA[2^160] == ghostDelegatedVotingPower[A]
    {
        preserved {
            requireInvariant zeroAddressNoVotingPower();
            requireInvariant sumOfVotesDelegatedToAStartsAtZero();
            requireInvariant sumOfVotesDelegatedToAGrowsCorrectly();
            requireInvariant sumOfVotesDelegatedToAMonotone();
        }
    }

invariant delegatedLTEqDelegateeVP()
    forall address account.
      ghostDelegatee[account] == A =>
      ghostBalances[account] <= ghostDelegatedVotingPower[A]
    {
        preserved with (env e){
            requireInvariant zeroAddressNoVotingPower();
            requireInvariant sumOfVotesDelegatedToAStartsAtZero();
            requireInvariant sumOfVotesDelegatedToAGrowsCorrectly();
            requireInvariant sumOfVotesDelegatedToAMonotone();
            requireInvariant delegatedLTEqPartialSum();
            requireInvariant sumOfVotesDelegatedToAIsDelegatedToA();
        }
    }

invariant sumOfVotesStartsAtZero()
    sumOfVotes[0] == 0;

invariant sumOfVotesGrowsCorrectly()
    forall address addr. sumOfVotes[to_mathint(addr) + 1] ==
      sumOfVotes[to_mathint(addr)] + ghostDelegatedVotingPower[addr];

invariant sumOfVotesMonotone()
    forall mathint i. forall mathint j. i <= j => sumOfVotes[i] <= sumOfVotes[j]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
        }
    }

// Check that the voting power plus the virtual voting power of address zero is equal to the total supply of tokens.
invariant totalSupplyIsSumOfVirtualVotingPower()
    sumOfVotes[2^160] + currentContract._zeroVirtualVotingPower == to_mathint(totalSupply())
    {
        preserved {
            requireInvariant sumOfBalancesStartsAtZero();
            requireInvariant sumOfBalancesGrowsCorrectly();
            requireInvariant sumOfBalancesMonotone();
            requireInvariant totalSupplyIsSumOfBalances();
            requireInvariant zeroAddressNoVotingPower();
            requireInvariant balancesLTEqTotalSupply();

        }
        preserved MorphoTokenOptimismHarness.initialize(address _) with (env e) {
            // Safe require because the proxy contract should be initialized right after construction.
            require totalSupply() == 0;
        }
        preserved MorphoTokenEthereumHarness.initialize(address _, address _) with (env e) {
            // Safe requires because the proxy contract should be initialized right after construction.
            require totalSupply() == 0;
            require forall mathint account. sumOfVotes[account] == 0;
        }
    }

invariant delegatedVotingPowerLTEqTotalVotingPower()
    forall address a. ghostDelegatedVotingPower[a] <= sumOfVotes[2^160]
    {
        preserved {
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
            requireInvariant totalSupplyIsSumOfVirtualVotingPower();
        }
    }

invariant sumOfTwoDelegatedVPLTEqTotalVP()
    forall address a. forall address b. a != b => ghostDelegatedVotingPower[a] + ghostDelegatedVotingPower[b] <= sumOfVotes[2^160]
    {
        preserved {
            requireInvariant delegatedVotingPowerLTEqTotalVotingPower();
            requireInvariant sumOfVotesStartsAtZero();
            requireInvariant sumOfVotesGrowsCorrectly();
            requireInvariant sumOfVotesMonotone();
            requireInvariant totalSupplyIsSumOfVirtualVotingPower();
        }
    }

function isTotalSupplyGTEqSumOfVotingPower() returns bool {
    requireInvariant totalSupplyIsSumOfVirtualVotingPower();
    return totalSupply() >= sumOfVotes[2^160];
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

// Check that the delegated voting power of a delegatee after an update is lesser than or equal to the total supply of tokens.
rule updatedDelegatedVPLTEqTotalSupply(env e, address to, uint256 amount) {
    // Safe require as implementation woud revert.
    require amount <= balanceOf(e.msg.sender);

    // Safe rquire as zero address can't initiate transactions.
    require e.msg.sender != 0;

    // Safe require as since we consider only updates.
    require delegatee(to) != delegatee(e.msg.sender);

    delegate(e, e.msg.sender);

    assert delegatee(e.msg.sender) == e.msg.sender && delegatee(e.msg.sender) != 0;

    // Safe require that follows from delegatedLTEqDelegateeVP.
    require amount <= delegatedVotingPower(e.msg.sender) ;

    requireInvariant delegatedVotingPowerLTEqTotalVotingPower();
    requireInvariant sumOfVotesStartsAtZero();
    requireInvariant sumOfVotesGrowsCorrectly();
    requireInvariant sumOfVotesMonotone();
    requireInvariant totalSupplyIsSumOfVirtualVotingPower();
    requireInvariant sumOfTwoDelegatedVPLTEqTotalVP();

    assert isTotalSupplyGTEqSumOfVotingPower();

    assert delegatedVotingPower(to) + amount <=  totalSupply();
}
