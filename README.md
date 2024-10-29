# Morpho token

This repository contains the Morpho protocol's ERC20 token.
It is designed to be upgradable and support onchain delegation.
Additionally, it ships a wrapper contract to simplify the migration of assets from the previous token contract to the new Morpho token contract.

## Features

### Upgradeability

The Morpho token complies with [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967) to support upgradeability.

### Delegation

The Morpho token supports onchain voting and voting power delegation.

### Role-based permission

The new Morpho token does not have role-based permission of functions.

### Burning tokens

In the legacy Morpho token, it was possible to transfer tokens to the zero address.
This is no longer possible in the new Morpho token, but it's possible for approved users to burn tokens by calling the `burn` function.

## Migration

### Wrapper contract

The `Wrapper` contract enables the migration of legacy tokens to the new token version at a one-to-one ratio.
With the functions `depositFor` and `withdrawTo`, this contract ensures compliance with `ERC20WrapperBundler` from the [Morpho bundler](https://github.com/morpho-org/morpho-blue-bundlers) contracts, enabling one-click migrations.
The `Wrapper` contract will hold the migrated legacy tokens.

### Migration flow

During contract initialization, 1 billion tokens will be minted for the `Wrapper` contract, which will initially hold the entire supply.
Any legacy token holder will then be able to migrate their tokens provided that the migration amount is approved for the wrapper.
Migrated legacy tokens may be recovered in order to revert a migration.

## Getting started

### Install dependencies

```shell
$ forge install
```

### Test

```shell
$ forge test
```

## License

The Morpho token is licensed under `GPL-2.0-or-later`, see [`LICENSE`](./LICENSE).
