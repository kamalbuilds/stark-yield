'use client';

import { ReactNode } from 'react';
import { sepolia, mainnet } from '@starknet-react/chains';
import { StarknetConfig, publicProvider, argent, braavos } from '@starknet-react/core';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

// Configure chains - using Sepolia for testing, mainnet for production
const chains = [sepolia, mainnet];
const connectors = [argent(), braavos()];

export function Providers({ children }: { children: ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <StarknetConfig
        chains={chains}
        provider={publicProvider()}
        connectors={connectors}
        autoConnect
      >
        {children}
      </StarknetConfig>
    </QueryClientProvider>
  );
}
