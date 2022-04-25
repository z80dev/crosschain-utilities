# Cross-Chain Utilities

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Some cross-chain apps built to experiment with a few cross-chain technologies, including but not limited to:

- Connext
- LayerZero
- Stargate
- IBC

## NFTYeeter

Accepts an NFT, locks it, and sends a message to mint an "equivalent" NFT on another chain.

That bridged NFT must be burned in order to redeem for the original underlying NFT.

Uses LayerZero

## VaultYeeter

Moves funds in/out/between vaults

Currently supports only moving USDC already in a user's wallet, into a balancer-based vault containing USDC (Reaper being used for initial implementation)

Will be expanded to support withdrawing from, and depositing into, any vault for any token/LP.


## Env

```sh
cp .env.example .env
```

## Test

```sh
yarn test
```

```sh
yarn test test/Greeter.ts
```

## Coverage

```sh
yarn test:coverage
```

<https://hardhat.org/plugins/solidity-coverage.html#tasks>

## Gas

```sh
yarn test:gas
```

<https://github.com/cgewecke/hardhat-gas-reporter>

## Lint

```sh
yarn lint
```

## Watch

```sh
npx hardhat watch compile
```

## Deployment

### Local

Running the following command will start a local node and run the defined deploy script on the local node.

```sh
npx hardhat node
```

### Mainnet

```sh
yarn mainnet:deploy
```

```sh
yarn mainnet:verify
```

```sh
hardhat tenderly:verify --network mainnet ContractName=Address
```

```sh
hardhat tenderly:push --network mainnet ContractName=Address
```

### Ropsten

```sh
yarn ropsten:deploy
```

```sh
yarn ropsten:verify
```

```sh
hardhat tenderly:verify --network ropsten ContractName=Address
```
