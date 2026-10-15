# ArcSwap Mainnet interface

This frontend is intentionally restricted to Arc Mainnet (`5042`) and ERC-20 router operations. Canonical USDC at `0x3600000000000000000000000000000000000000` is represented as a six-decimal ERC-20 and is the required base token for every pool. Native-value/ETH routes, wrapping, and multi-chain wallet connectors are not exposed.

## Configuration

Copy `.env.example` to `.env.local`. The example is populated with the current
Arc Mainnet deployment:

- `REACT_APP_FACTORY_ADDRESS`: `0x4Cd7fDFf83DC1540696BdaF38840a93134336dF8`
- `REACT_APP_ROUTER_ADDRESS`: `0xB433a6F3c690D17E78aa3dD87eC01cdc304278a9`
- `REACT_APP_MULTICALL_ADDRESS`: `0xcA11bde05977b3631167028862be2a173976CA11`

The Arc RPC and explorer defaults are already built in. The local SDK uses the final pair init-code hash `0x63c73377a673092dc48b28aa63fa4353314c943e33a48ff8d829a9b005f8e108`; the configured factory must use the matching pair bytecode.

## Reproducible setup

Use Node `20.20.1` (recorded in `.nvmrc`) and install exactly the committed lockfile:

```sh
nvm use
npm ci
npm test -- --watchAll=false
npm run lint
npm run build
```

The Arc-patched SDK is a normal local `file:` dependency at `forks/@uniswap/sdk`; no post-install copying or hand-edited `node_modules` is required.
