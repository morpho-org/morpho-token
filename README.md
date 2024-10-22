# Morpho Token

This repository contains the Morpho protocol’s ERC20 token.
It is designed to be upgradable and support onchain delegation.
Additionally, it ships a wrapper contract to simplify the migration of assets from the previous token contract to the new Morpho token contract.

## Upgradability

The Morpho token complies with the EIP-1967 to support upgradability.

## Delegation

The Morpho token supports onchain voting and voting power delegation.

## Migration

### Wrapper Contract

The `Wrapper` contract simplifies migration of legacy tokens to the new token version at a one-to-one ratio.
With the functions `depositFor` and `withdrawTo`, this contract ensures compliance with `ERC20WrapperBundler` from the [Morpho bundler](https://github.com/morpho-org/morpho-blue-bundlers) contracts, enabling one-click migrations..
The `Wrapper` contract will hold the migrated legacy tokens.

### Migration Flow

Note: the `Wrapper` contract must be deployed before the new token's initialization.

During contract intialization, 1 billion tokens will be minted for the `Wrapper` contract, which will initially hold the entire supply.
Any legacy token holder will then be able to migrate their tokens provided that,the migration amount is the approved for the wrapper.
Migrated legacy tokens may be recovered in order to revert a migration.

### Install dependencies

```shell
$ forge install
```

### Test

```shell
$ forge test
```
