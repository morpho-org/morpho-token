// SPDX-License-Identifier: GPL-2.0-or-later

methods {
    function owner() external returns address envfree;
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;

    // Avoids checking delegation related overflows.
    function _._moveDelegateVotes(address, address, uint256) internal => CONSTANT;
}

// Check that minting to zero address or minter is not owner revert.
rule mintReverts(env e, address to, uint256 amount) {
    // Safe require as mint is a non-payable function.
    require e.msg.value == 0;

    require totalSupply() + amount <= max_uint256;

    mint@withrevert(e, to, amount);
    assert   !(lastReverted) <=> e.msg.sender == owner() && to != 0;
}

// Check that burnning from zero address or too large amounts revert.
rule burnReverts(env e, address from, uint256 amount) {
    // Safe require as burn is a non-payable function.

    uint256 balanceOfSenderBefore = balanceOf(e.msg.sender);
    require e.msg.value == 0 ;

    burn@withrevert(e, amount);
    assert !lastReverted <=> e.msg.sender != 0 && balanceOfSenderBefore >= amount;
}
