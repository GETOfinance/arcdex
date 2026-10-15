# Arc Mainnet AMM

This directory contains the complete deployable contract source for the Arc
Mainnet DEX:

- Factory with permissionless creation of canonical-USDC pairs
- Standard 0.30% constant-product Pair and ARC-LP token
- ERC-20-only Router02
- Required interfaces and math/transfer libraries

The SushiSwap migrator extension and every ETH/WETH native-value path have
been removed. See the project-level README for deployment and testing.
