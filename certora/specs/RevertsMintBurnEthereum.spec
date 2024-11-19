// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function owner() external returns address envfree;
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;

    // Avoids checking delegation related overflows.
    function _._moveDelegateVotes(address, address, uint256) internal => CONSTANT;
}

// Check the revert conditions for the burn function.
rule mintRevertConditions(env e, address to, uint256 amount) {
    mathint totalSupplyBefore = totalSupply();

    mint@withrevert(e, to, amount);
    assert lastReverted <=> e.msg.sender != owner() || to == 0 || e.msg.value != 0 || totalSupplyBefore + amount > max_uint256;
}

// Check the revert conditions for the burn function.
rule burnRevertConditions(env e, address from, uint256 amount) {
    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);
    require e.msg.value == 0 ;

    burn@withrevert(e, amount);
    assert lastReverted <=> e.msg.sender == 0 || balanceOfSenderBefore < amount || e.msg.value != 0;
}
