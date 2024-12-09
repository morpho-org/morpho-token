// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function delegatee(address) external returns address envfree;
    function delegatedVotingPower(address) external returns uint256 envfree;
}

// Check the revert conditions for the mint function.
rule mintRevertConditions(env e, address to, uint256 amount) {
    mathint totalSupplyBefore = totalSupply();
    uint256 toVotingPowerBefore = delegatedVotingPower(delegatee(to));

    // Safe require as zero address can't possibly delegate voting power which is verified in zeroAddressNoVotingPower.
    require delegatee(0) == 0;

    // Safe require as it is verified in totalSupplyGTEqSumOfVotingPower.
    require toVotingPowerBefore <= totalSupply();

    mint@withrevert(e, to, amount);
    assert lastReverted <=> e.msg.sender != currentContract.bridge || to == 0 || e.msg.value != 0 || totalSupplyBefore + amount > max_uint256;
}

// Check the revert conditions for the burn function.
rule burnRevertConditions(env e, address from, uint256 amount) {
    uint256 balanceOfFromBefore = balanceOf(from);
    uint256 fromVotingPowerBefore = delegatedVotingPower(delegatee(from));

    // Safe require as zero address can't possibly delegate voting power which is verified in zeroAddressNoVotingPower.
    require delegatee(0) == 0;

    // Safe require as it is verified in delegatedLTEqDelegateeVP.
    require fromVotingPowerBefore >= balanceOfFromBefore;

    burn@withrevert(e, from, amount);
    assert lastReverted <=> e.msg.sender != currentContract.bridge || from == 0 || balanceOfFromBefore < amount ||  e.msg.value != 0;
}
