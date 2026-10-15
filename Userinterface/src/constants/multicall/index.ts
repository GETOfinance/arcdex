import { ARC_CHAIN_ID } from '../arc';
import MULTICALL_ABI from './abi.json';

const MULTICALL_NETWORKS: { [chainId: number]: string | undefined } = {
  [ARC_CHAIN_ID]: process.env.REACT_APP_MULTICALL_ADDRESS,
};

export { MULTICALL_ABI, MULTICALL_NETWORKS };
