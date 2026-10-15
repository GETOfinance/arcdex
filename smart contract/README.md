# Arc Mainnet DEX contracts

An ERC-20-only Uniswap V2 AMM configured for Arc Mainnet.

## Network

| Field | Value |
| --- | --- |
| Network | Arc |
| Chain ID | `5042` |
| RPC | `https://rpc.mainnet.arc.io` |
| Explorer | `https://explorer.arc.io` |
| Native gas symbol | USDC |
| Canonical ERC-20 USDC | `0x3600000000000000000000000000000000000000` |
| ERC-20 USDC decimals | 6 |

The RPC reports chain ID `5042`. The canonical USDC predeploy is live at the
address above and reports symbol `USDC` and 6 decimals.

## Scope

The deployable contracts are only:

- `UniswapV2Factory`
- `UniswapV2Pair` and its LP ERC-20
- `UniswapV2Router02`

Every pair must contain canonical USDC. The router supports ERC-20 liquidity,
exact-input swaps, exact-output swaps, LP permits, and exact-input
fee-on-transfer swaps. It has no payable receive function and no ETH/WETH or
native-value methods. Farming, token issuance, governance, migration, and fee
conversion are deliberately out of scope.

Arc exposes one USDC balance through an 18-decimal native interface and a
6-decimal ERC-20 interface. Pool accounting uses only ERC-20 `balanceOf`,
`transfer`, and `transferFrom`; do not pass native value to these contracts.

Both factory and router reject deployment on any chain other than `5042`.

## Arc Mainnet deployment

| Contract | Address |
| --- | --- |
| Factory | [`0x4Cd7fDFf83DC1540696BdaF38840a93134336dF8`](https://explorer.arc.io/address/0x4Cd7fDFf83DC1540696BdaF38840a93134336dF8) |
| Router02 | [`0xB433a6F3c690D17E78aa3dD87eC01cdc304278a9`](https://explorer.arc.io/address/0xB433a6F3c690D17E78aa3dD87eC01cdc304278a9) |

The initial `feeToSetter` is
`0x3a18f9f0E07269D2a9161A0E83745b4e8BbAdEE8`. Deployment transaction details
are recorded in `deployments/arc-mainnet.json`.

## Build and test

```sh
forge clean
forge build
forge test -vv
```

## Deploy

Copy `.env.example` to `.env`, set `PRIVATE_KEY`, and set `FEE_TO_SETTER` to a
secure nonzero address (preferably a multisig). The deployment account must
hold enough Arc Mainnet USDC to pay gas.

```sh
cp .env.example .env
# Edit .env without exposing the private key in shell history.
set -a
source .env
set +a

# Read-only preflight: this must print 5042.
cast chain-id --rpc-url "$ARC_RPC_URL"

# Simulate first. This does not broadcast transactions.
forge script script/DeployArcDex.s.sol:DeployArcDex \
  --rpc-url arc \
  -vvv

# Broadcast only after reviewing the simulation output.
forge script script/DeployArcDex.s.sol:DeployArcDex \
  --rpc-url arc \
  --broadcast \
  -vvv
```

Record the emitted factory and router addresses, then confirm them in
`https://explorer.arc.io`. The factory deploys first and the router is bound to
that factory. The factory's `feeToSetter` is the configured `FEE_TO_SETTER`.

After deployment, set `FACTORY_ADDRESS` and `ROUTER_ADDRESS` in `.env`. The
following optional smoke test deploys a disposable token and performs real
add-liquidity, swap, and remove-liquidity transactions. It spends approximately
1 USDC plus gas and should only be run intentionally:

```sh
forge script script/SmokeTestArcDex.s.sol:SmokeTestArcDex \
  --rpc-url arc \
  --broadcast \
  -vvv
```

Before integrating a frontend, verify that `factory.pairCodeHash()` matches the
pair init-code hash used by `UniswapV2Library`.

## Production warning

This is adapted legacy Solidity `0.6.12` code and is not an audit. A successful
build and simulation do not make it production-safe. Obtain an independent
security review and validate USDC blocklist behavior, flash swaps, protocol
fees, fee-on-transfer tokens, CREATE2 address derivation, admin key management,
and Arc-native transfer rejection before production use.
