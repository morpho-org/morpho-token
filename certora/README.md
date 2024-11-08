# Morpho Token Contract Formal Verification

This folder contains the [CVL](https://docs.certora.com/en/latest/docs/cvl/index.html) specification and verification setup for the [MorphoTokenEthereum](../src/MorphoTokenEthereum.sol) and  [MorphoTokenOptimism](../src/MorphoTokenOptimism.sol) contracts.

## Getting Started

This project depends on [Solidity](https://soliditylang.org/) which is required for running the verification.
The compiler binary should be available in the path:

- `solc-0.8.27` for the solidity compiler version `0.8.27`.

To verify a specification, run the command `certoraRun Spec.conf` where `Spec.conf` is the configuration file of the matching CVL specification.
Configuration files are available in [`certora/confs`](confs).
Please ensure that `CERTORAKEY` is set up in your environment.

## Overview

These Morpho token contracts replace the legacy version and add support for delegation of voting power, upgradeability and cross-chain interactions.

### Reentrancy

This is checked in [`Reentrancy.spec`](specs/Reentrancy.spec).

### Immutability

This is checked in [`Immutability.spec`](specs/Immutability.spec).

### ERC20 Compliance

This is checked in [`ERC20.spec`](specs/ERC20.spec).

## Verification architecture

### Folders and file structure

The [`certora/specs`](specs) folder contains the following files:

- [`Reentrancy.spec`](specs/Reentrancy.spec) checks that Morpho token contracts are reentrancy safe by ensuring that no function is making external call;
- [`Immutability.spec`](specs/Immutability.spec) checks that Morpho token implementation contract is immutable because it doesn't perform any delegate call other than to the upgrade function;
- [`ERC20.spec`](specs/ERC20.spec) ensure that the Morpho token is compliant with the [ERC20](https://eips.ethereum.org/EIPS/eip-20) specification;


The [`certora/confs`](confs) folder contains a configuration file for each corresponding specification file for both the Ethereum and the Optimism version.
