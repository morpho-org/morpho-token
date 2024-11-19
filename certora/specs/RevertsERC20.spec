// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address, address) external returns uint256 envfree;

    // Avoids checking delegation related overflows.
    function _._moveDelegateVotes(address, address, uint256) internal => CONSTANT;
}

// Check the revert conditions for the transfer function.
rule transferRevertConditions(env e, address to,uint256 amount) {
    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);

    transfer@withrevert(e, to, amount);
    assert lastReverted <=> e.msg.sender == 0 || to == 0 || balanceOfSenderBefore < amount || e.msg.value != 0;
}

// Check the revert conditions for the transferFrom function.
rule transferFromRevertConditions(env e, address from, address to,uint256 amount) {
    uint256 allowanceOfSenderBefore = allowance(from, e.msg.sender);
    uint256 balanceOfFromBefore = balanceOf(from);

    transferFrom@withrevert(e, from, to, amount);
    bool generalRevertConditions = from == 0 || to == 0 || balanceOfFromBefore < amount || e.msg.value != 0;
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
