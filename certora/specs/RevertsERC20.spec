// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address, address) external returns uint256 envfree;
    function delegatee(address) external returns address envfree;
    function delegatedVotingPower(address) external returns uint256 envfree;
}

// Check the revert conditions for the transfer function.
rule transferRevertConditions(env e, address to, uint256 amount) {
    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);
    uint256 senderVotingPowerBefore = delegatedVotingPower(delegatee(e.msg.sender));
    uint256 recipientVotingPowerBefore = delegatedVotingPower(delegatee(to));

    // Assume that the delegatee voting power is greater or equal to the holder's balance.
    require delegatee(e.msg.sender) != 0 => senderVotingPowerBefore >= balanceOfSenderBefore;
    // Assume that if the holder's and recipient's delegatees are different and not the zero address then, the recipient delegatee's voting power doesn't count the holder's voting power.
    require delegatee(to) != 0 && delegatee(to) != delegatee(e.msg.sender) => recipientVotingPowerBefore <= totalSupply() - balanceOfSenderBefore;

    transfer@withrevert(e, to, amount);
    assert lastReverted <=> e.msg.sender == 0 || to == 0 || balanceOfSenderBefore < amount || e.msg.value != 0;
}

// Check the revert conditions for the transferFrom function.
rule transferFromRevertConditions(env e, address from, address to, uint256 amount) {
    uint256 allowanceOfSenderBefore = allowance(from, e.msg.sender);
    uint256 balanceOfHolderBefore = balanceOf(from);
    uint256 holderVotingPowerBefore = delegatedVotingPower(delegatee(from));
    uint256 recipientVotingPowerBefore = delegatedVotingPower(delegatee(to));

    // Assume that the delegatee voting power is greater or equal to the holder's balance.
    require delegatee(from) != 0 => holderVotingPowerBefore >= balanceOfHolderBefore;
    // Assume that if the holder's and recipient's delegatees are different and not the zero address then, the recipient delegatee's voting power doesn't count the holder's voting power.
    require delegatee(to) != 0 && delegatee(to) != delegatee(from) => recipientVotingPowerBefore <= totalSupply() - balanceOfHolderBefore;

    transferFrom@withrevert(e, from, to, amount);
    bool generalRevertConditions = from == 0 || to == 0 || balanceOfHolderBefore < amount || e.msg.value != 0;
    if (allowanceOfSenderBefore != max_uint256) {
        assert lastReverted <=>  e.msg.sender == 0 || allowanceOfSenderBefore < amount || generalRevertConditions;
    } else {
        assert lastReverted <=> generalRevertConditions;
    }

}

// Check the revert conditions for the approve function.
rule approveRevertConditions(env e, address to, uint256 value) {
    approve@withrevert(e, to, value);
    assert lastReverted <=> e.msg.sender == 0 || to == 0 || e.msg.value != 0;
}
