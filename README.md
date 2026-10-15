# ArcSwap

ArcSwap is an ERC-20 decentralized exchange for Arc Mainnet. It is based on the Uniswap V2 automated market maker design and pairs every supported asset with Arc's canonical ERC-20 USDC. The repository contains the Solidity contracts and the React user interface required to use the deployed exchange.

## Repository structure

- [`smart contract`](./smart%20contract) contains the Foundry project, AMM contracts, deployment scripts, tests, and the Arc Mainnet deployment record.
- [`Userinterface`](./Userinterface) contains the ArcSwap React frontend and its Arc-patched Uniswap SDK dependency.

## Features

- Create and manage USDC-based liquidity pools.
- Add and remove ERC-20 liquidity.
- Execute exact-input and exact-output token swaps.
- Support fee-on-transfer exact-input swaps.
- Use LP-token permits when removing liquidity.
- Discover tokens by ERC-20 contract address.
- Connect an Arc-compatible browser wallet or MetaMask.
- Display balances, pool positions, transaction status, and Arc Explorer links.
- Restrict the application and contracts to Arc Mainnet, chain ID `5042`.
- Use Arc's canonical six-decimal ERC-20 USDC at `0x3600000000000000000000000000000000000000` as the required base asset.

Arc exposes USDC through native and ERC-20 interfaces. ArcSwap pool accounting and router operations use only the ERC-20 interface; the router does not accept native value and does not expose ETH/WETH routes.

## Arc Mainnet deployment

| Contract | Address | Explorer |
| --- | --- | --- |
| UniswapV2Factory | `0x4Cd7fDFf83DC1540696BdaF38840a93134336dF8` | [View factory on Arc Explorer](https://explorer.arc.io/address/0x4Cd7fDFf83DC1540696BdaF38840a93134336dF8) |
| UniswapV2Router02 | `0xB433a6F3c690D17E78aa3dD87eC01cdc304278a9` | [View router on Arc Explorer](https://explorer.arc.io/address/0xB433a6F3c690D17E78aa3dD87eC01cdc304278a9) |

Network configuration:

| Field | Value |
| --- | --- |
| Network | Arc Mainnet |
| Chain ID | `5042` |
| RPC URL | `https://rpc.mainnet.arc.io` |
| Explorer | [explorer.arc.io](https://explorer.arc.io) |
| Canonical ERC-20 USDC | `0x3600000000000000000000000000000000000000` |

The deployment transaction hashes and block numbers are recorded in [`smart contract/deployments/arc-mainnet.json`](./smart%20contract/deployments/arc-mainnet.json).

## Smart contract development

Install [Foundry](https://book.getfoundry.sh/getting-started/installation), then run:

```sh
cd "smart contract"
forge build
forge test -vv
```

For deployment or the optional on-chain smoke test, copy `.env.example` to `.env` and supply the required values. Never commit private keys or the resulting `.env` file.

## Frontend development

The frontend uses Node.js `20.20.1`, recorded in `.nvmrc`.

```sh
cd Userinterface
cp .env.example .env.local
npm ci
npm test -- --watchAll=false
npm run build
npm start
```

The local application is served at [http://localhost:3000](http://localhost:3000). The provided environment template already targets the deployed Arc Mainnet factory and router.

## License

The contract and frontend directories contain their respective GPL-3.0-or-later license files.
