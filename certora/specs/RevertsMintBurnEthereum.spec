// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function owner() external returns address envfree;
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function delegatee(address) external returns address envfree;
    function delegatedVotingPower(address) external returns uint256 envfree;
}

// Check the revert conditions for the burn function.
rule mintRevertConditions(env e, address to, uint256 amount) {
    mathint totalSupplyBefore = totalSupply();
    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);
    uint256 toVotingPowerBefore = delegatedVotingPower(delegatee(to));

    // Safe require as zero address can't possibly delegate voting power.
    require delegatee(0) == 0;

    // Safe require because if the delegatee is not zero the recipient's voting power excludes the newly minted value.
    require delegatee(to) != 0 => toVotingPowerBefore <= totalSupply() - amount;

    mint@withrevert(e, to, amount);
    assert lastReverted <=> e.msg.sender != owner() || to == 0 || e.msg.value != 0 || totalSupplyBefore + amount > max_uint256;
}

// Check the revert conditions for the burn function.
rule burnRevertConditions(env e, uint256 amount) {
    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);
    uint256 senderVotingPowerBefore = delegatedVotingPower(delegatee(e.msg.sender));

    // Safe require as zero address can't possibly delegate voting power.
    require delegatee(0) == 0;

    // Safe require because a holder's balance is added to the delegatee's voting power upon delegation.
    require delegatee(e.msg.sender) != 0 => senderVotingPowerBefore >= balanceOfSenderBefore;

    burn@withrevert(e, amount);
    assert lastReverted <=> e.msg.sender == 0 || balanceOfSenderBefore < amount || e.msg.value != 0;
}
