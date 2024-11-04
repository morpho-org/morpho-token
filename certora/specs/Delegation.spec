import "ERC20.spec";

ghost mathint sumOfVotingPower {
    init_state axiom sumOfVotingPower == 0;
}

// Slot is DelegationTokenStorage._delegatedVotingPower slot
hook Sload uint256 votingPower (slot 0xd583ef41af40c9ecf9cd08176e1b50741710eaecf057b22e93a6b99fa47a6401)[KEY address addr] {
   require sumOfVotingPower >= to_mathint(votingPower);
}

// Slot is DelegationTokenStorage._delegatedVotingPower slot
hook Sstore (slot 0xd583ef41af40c9ecf9cd08176e1b50741710eaecf057b22e93a6b99fa47a6401)[KEY address addr] uint256 newValue (uint256 oldValue) {
    sumOfVotingPower = sumOfVotingPower - oldValue + newValue;
}

invariant zeroAddressNoVotingPower()
    delegatee(0x0) == 0x0 && delegatedVotingPower(0x0) == 0
    { preserved with (env e) { require e.msg.sender != 0; } }

invariant totalSupplyLargerThanSumOfVotingPower()
    to_mathint(totalSupply()) >= sumOfVotingPower || sumOfVotingPower > max_uint256
{
    preserved {
        requireInvariant totalSupplyIsSumOfBalances();
    }
}
