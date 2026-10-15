import { Web3Provider } from '@ethersproject/providers';
import { InjectedConnector } from '@web3-react/injected-connector';
import { ARC_CHAIN_ID, ARC_RPC_URL } from '../constants/arc';
import { NetworkConnector } from './NetworkConnector';

export const NETWORK_CHAIN_ID = ARC_CHAIN_ID;

export const network = new NetworkConnector({
  urls: { [NETWORK_CHAIN_ID]: ARC_RPC_URL },
});

let networkLibrary: Web3Provider | undefined;
export function getNetworkLibrary(): Web3Provider {
  return (networkLibrary = networkLibrary ?? new Web3Provider(network.provider as any));
}

export const injected = new InjectedConnector({
  supportedChainIds: [ARC_CHAIN_ID],
});
