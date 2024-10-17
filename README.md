# Morpho Token

This repository contains the latest version of the Morpho protocol’s ERC-20 token, designed to enhance functionality, security, and compatibility within the Morpho ecosystem. This new version introduces upgradability and on-chain delegation features, allowing for greater flexibility and adaptability over time. Additionally, it includes a wrapper contract to facilitate a seamless migration from the previous token version, enabling users to transition their assets with minimal friction.

## Upgradability

The Morpho Token leverages the eip-1967 to enable upgrade of the logic. This will allow new features to be added in the future.

## Delegation

The Morpho Token enables onchain voting power delegation. The contract keeps track of all the addresses current voting power, which allows onchain votes thanks to storage proofs (on specific voting contracts).

## Migration

### Wrapper Contract

The `Wrapper` contract is designed to facilitate the migration of legacy tokens to the new token version at a 1:1 exchange ratio. By implementing depositFor and withdrawTo functions, this contract ensures compliance with the Morpho bundler, enabling one-click migrations that simplify the transition process.
The `Wrapper` contract will hold the migrated legacy tokens.

### Migration Flow

N.B. The `Wrapper` contract must be deployed before the new token's initialization.

At the token's initialization, 1B tokens will be minted for the `Wrapper` contract, which will initially hold the entire supply.

Any legacy token holder will then be able to migrate their tokens by calling the `depositFor` function of the `Wrapper` contract (Having previously approved the migration amount to the wrapper).

Migrated legacy tokens can be recovered thanks to the `withdrawTo`, that allow to revert a migration.

## Usage

### Install dependencies

```shell
$ forge install
```

### Test

```shell
$ forge test
```
