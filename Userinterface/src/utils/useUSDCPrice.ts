import { Currency, Price } from '@uniswap/sdk';
import { useMemo } from 'react';
import { ARC_USDC } from '../constants';
import { PairState, usePairs } from '../data/Reserves';
import { useActiveWeb3React } from '../hooks';
import { wrappedCurrency } from './wrappedCurrency';

/** Returns the direct canonical-USDC price of an Arc ERC-20. */
export default function useUSDCPrice(currency?: Currency): Price | undefined {
  const { chainId } = useActiveWeb3React();
  const token = wrappedCurrency(currency, chainId);
  const [[pairState, pair]] = usePairs([[token?.equals(ARC_USDC) ? undefined : token, ARC_USDC]]);

  return useMemo(() => {
    if (!currency || !token) return undefined;
    if (token.equals(ARC_USDC)) return new Price(ARC_USDC, ARC_USDC, '1', '1');
    if (pairState !== PairState.EXISTS || !pair) return undefined;
    const price = pair.priceOf(token);
    return new Price(currency, ARC_USDC, price.denominator, price.numerator);
  }, [currency, pair, pairState, token]);
}
