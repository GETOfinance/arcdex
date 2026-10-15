import { JSBI, Percent, Token } from '@uniswap/sdk';
import { AbstractConnector } from '@web3-react/abstract-connector';
import { injected } from '../connectors';
import { ARC_CHAIN_ID, ARC_USDC_ADDRESS } from './arc';

export { ARC_CHAIN_ID, ARC_USDC_ADDRESS } from './arc';

export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
export const FACTORY_ADDRESS = process.env.REACT_APP_FACTORY_ADDRESS || ZERO_ADDRESS;
export const ROUTER_ADDRESS = process.env.REACT_APP_ROUTER_ADDRESS || ZERO_ADDRESS;

export const LP_TOKEN_NAME = 'ArcSwap LP Token';
export const LP_TOKEN_SYMBOL = 'ARC-LP';

export const ARC_USDC = new Token(ARC_CHAIN_ID, ARC_USDC_ADDRESS, 6, 'USDC', 'USD Coin');
// Kept as an alias because pricing components historically import USDC.
export const USDC = ARC_USDC;

type ChainTokenList = { readonly [chainId: number]: Token[] };

// Every pool must include canonical ERC-20 USDC. Other ERC-20s are discovered
// from token lists or by address, but routing always uses USDC as the base.
export const BASES_TO_CHECK_TRADES_AGAINST: ChainTokenList = {
  [ARC_CHAIN_ID]: [ARC_USDC],
};
export const CUSTOM_BASES: { [chainId: number]: { [tokenAddress: string]: Token[] } | undefined } = {};
export const SUGGESTED_BASES: ChainTokenList = { [ARC_CHAIN_ID]: [ARC_USDC] };
export const BASES_TO_TRACK_LIQUIDITY_FOR: ChainTokenList = { [ARC_CHAIN_ID]: [ARC_USDC] };
export const PINNED_PAIRS: { readonly [chainId: number]: [Token, Token][] | undefined } = {};

export interface WalletInfo {
  connector?: AbstractConnector;
  name: string;
  iconName: string;
  description: string;
  href: string | null;
  color: string;
  primary?: true;
  mobile?: true;
  mobileOnly?: true;
}

export const SUPPORTED_WALLETS: { [key: string]: WalletInfo } = {
  INJECTED: {
    connector: injected,
    name: 'Browser Wallet',
    iconName: 'arrow-right.svg',
    description: 'Connect an Arc-compatible browser wallet.',
    href: null,
    color: '#010101',
    primary: true,
  },
  METAMASK: {
    connector: injected,
    name: 'MetaMask',
    iconName: 'metamask.png',
    description: 'Connect MetaMask to Arc Mainnet.',
    href: null,
    color: '#E8831D',
  },
};

export const NetworkContextName = 'NETWORK';
export const INITIAL_ALLOWED_SLIPPAGE = 50;
export const DEFAULT_DEADLINE_FROM_NOW = 60 * 20;
export const BIG_INT_SECONDS_IN_WEEK = JSBI.BigInt(60 * 60 * 24 * 7);
export const BIG_INT_ZERO = JSBI.BigInt(0);
export const ONE_BIPS = new Percent(JSBI.BigInt(1), JSBI.BigInt(10000));
export const BIPS_BASE = JSBI.BigInt(10000);
export const ALLOWED_PRICE_IMPACT_LOW = new Percent(JSBI.BigInt(100), BIPS_BASE);
export const ALLOWED_PRICE_IMPACT_MEDIUM = new Percent(JSBI.BigInt(300), BIPS_BASE);
export const ALLOWED_PRICE_IMPACT_HIGH = new Percent(JSBI.BigInt(500), BIPS_BASE);
export const PRICE_IMPACT_WITHOUT_FEE_CONFIRM_MIN = new Percent(JSBI.BigInt(1000), BIPS_BASE);
export const BLOCKED_PRICE_IMPACT_NON_EXPERT = new Percent(JSBI.BigInt(1500), BIPS_BASE);
// Reserve 0.01 USDC from max-spend so the unified Arc USDC balance can pay gas.
export const MIN_USDC_FOR_GAS = JSBI.BigInt(10_000);
export const BETTER_TRADE_LESS_HOPS_THRESHOLD = new Percent(JSBI.BigInt(50), JSBI.BigInt(10000));
export const ZERO_PERCENT = new Percent('0');
export const ONE_HUNDRED_PERCENT = new Percent('1');
