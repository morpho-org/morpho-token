// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address, address) external returns uint256 envfree;

    // Avoids checking delegation related overflows.
    function _._moveDelegateVotes(address, address, uint256) internal => CONSTANT;
}

// Check that transfers with zero address or too large amounts revert.
rule transferReverts(env e, address to,uint256 amount) {
    // Safe require as transfer is a non-payable function.
    require e.msg.value == 0;

    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);

    transfer@withrevert(e, to, amount);
    assert !lastReverted <=> e.msg.sender != 0 && to !=0 && balanceOfSenderBefore >= amount;
}


// Check that transfersFrom with zero address or too large allowances revert.
rule transferFromReverts(env e, address from, address to,uint256 amount) {
    // Safe require as transferFrom is a non-payable function.
    require e.msg.value == 0;

    uint256 allowanceOfSenderBefore = allowance(from, e.msg.sender);

    // Safe require that implies allowance is infinite.
    require allowanceOfSenderBefore != max_uint256;

    uint256 balanceOfFromBefore = balanceOf(from);

    transferFrom@withrevert(e, from, to, amount);
    assert !lastReverted <=> e.msg.sender != 0 && from != 0 && to !=0 && balanceOfFromBefore >= amount && allowanceOfSenderBefore >= amount;

}

// Check that approving with zero address reverts.
rule approveReverts(env e, address to, uint256 value) {
    // Safe require as approve is a non-payable function.
    require e.msg.value == 0;

    approve@withrevert(e, to, value);
    assert !(lastReverted) <=> e.msg.sender != 0 && to != 0;
}
