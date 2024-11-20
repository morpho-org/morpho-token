// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;

    // Avoids checking delegation related overflows.
    function _._moveDelegateVotes(address, address, uint256) internal => CONSTANT;
}

// Check the revert conditions for the mint function.
rule mintRevertConditions(env e, address to, uint256 amount) {
    mathint totalSupplyBefore = totalSupply();

    mint@withrevert(e, to, amount);
    assert lastReverted <=> e.msg.sender != currentContract.bridge || to == 0 || e.msg.value != 0 || totalSupplyBefore + amount > max_uint256;
}

// Check the revert conditions for the burn function.
rule burnRevertConditions(env e, address from, uint256 amount) {
    uint256 balanceOfFromBefore = balanceOf(from);
    burn@withrevert(e, from, amount);
    assert lastReverted <=> e.msg.sender != currentContract.bridge || from == 0 || balanceOfFromBefore < amount ||  e.msg.value != 0;
}
