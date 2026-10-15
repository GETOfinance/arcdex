import { CurrencyAmount, JSBI, Token, TokenAmount } from '@uniswap/sdk';
import { ARC_USDC, MIN_USDC_FOR_GAS } from '../constants';

/**
 * Given some token amount, return the max that can be spent of it
 * @param currencyAmount to return max of
 */
export function maxAmountSpend(currencyAmount?: CurrencyAmount): CurrencyAmount | undefined {
  if (!currencyAmount) return undefined;
  if (currencyAmount.currency instanceof Token && currencyAmount.currency.equals(ARC_USDC)) {
    if (JSBI.greaterThan(currencyAmount.raw, MIN_USDC_FOR_GAS)) {
      return new TokenAmount(ARC_USDC, JSBI.subtract(currencyAmount.raw, MIN_USDC_FOR_GAS));
    } else {
      return new TokenAmount(ARC_USDC, JSBI.BigInt(0));
    }
  }
  return currencyAmount;
}
