import "ERC20.spec";

methods {
    function _moveDelegateVotesExternal(address from, address to, uint256 amount) external envfree;
    function _burnExternal(address, uint256) external envfree;
    function ERC20Upgradeable._burn(address account, uint256 value) internal
        => summaryBurn(account, value);
    function DelegationTokenHarness._moveDelegateVotes(address from, address to, uint256 amount) internal
        => summaryMove(from, to, amount);
}

ghost mathint sumOfVotingPower {
    init_state axiom sumOfVotingPower == 0;
}

// The ghost variable burnCalled is used to track calls to burn.
persistent ghost bool burnCalled {
    init_state axiom burnCalled == false;
}

function summaryBurn(address a, uint256 amount) {
    // Mark _burn as being called.
    burnCalled = true;

    // Burn tokens.
    _burnExternal(a, amount);
}

function summaryMove(address from, address to, uint256 amount) {
    if (burnCalled) {
        // Ensure that burnt voting power is deducted from sumOfVotingPower.
        sumOfVotingPower = sumOfVotingPower - amount;
        burnCalled = false;
    } else if (from == 0 && to != 0) {
        // Ensure that voting power is deducted from sumOfVotingPower during a transfer or a delegation when delegatee is zero address.
        sumOfVotingPower = sumOfVotingPower - amount;
    } else if (to == 0 && from !=0) {
        // Ensure that voting power is added to sumOfVotingPower during a transfer or a delegation when delegatee is zero address.
        sumOfVotingPower = sumOfVotingPower + amount;
    }

    // Move tokens.
    _moveDelegateVotesExternal(from, to, amount);
}

// Slot for DelegationTokenStorage._delegatedVotingPower
hook Sload uint256 votingPower (slot 0xd583ef41af40c9ecf9cd08176e1b50741710eaecf057b22e93a6b99fa47a6401)[KEY address addr] {
    require sumOfVotingPower >= to_mathint(votingPower);
}

// Slot for DelegationTokenStorage._delegatedVotingPower
hook Sstore (slot 0xd583ef41af40c9ecf9cd08176e1b50741710eaecf057b22e93a6b99fa47a6401)[KEY address addr] uint256 newValue (uint256 oldValue) {
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
invariant totalSupplyLargerThanSumOfVotingPower()
    to_mathint(totalSupply()) >= sumOfVotingPower
    filtered {
      // Ensure that exposed internal functions in harnesses are filtered out and ignore upgrades.
      f-> f.selector != sig:_moveDelegateVotesExternal(address,address,uint256).selector
        && f.selector != sig:_burnExternal(address, uint256).selector
        && f.selector != sig:upgradeToAndCall(address, bytes).selector
    }
    {
      preserved  with (env e) {
          requireInvariant totalSupplyIsSumOfBalances();
          requireInvariant zeroAddressNoVotingPower();
      }
    }

// Check that user can restore their voting power by delegating to zero address then delgating back to themselves.
rule delgatingSelfConsistent {
    require !burnCalled;
    requireInvariant totalSupplyLargerThanSumOfVotingPower();
    env e;
    address user = e.msg.sender;

    // Safe require as the user can't possibly be zero.
    require user != 0;

    // Ensure that user has delegated to zero address.
    require delegatee(user) == 0;

    mathint sumOfVotingPowerBefore = sumOfVotingPower;
    mathint delegatedBefore = delegatedVotingPower(user);

    delegate(e, user);

    // Check that no extra voting power hasn't been created.
    assert sumOfVotingPowerBefore == sumOfVotingPower;
    // Check that the voting power has been restored.
    assert delegatedVotingPower(user) == balanceOf(user) + delegatedBefore;
}
