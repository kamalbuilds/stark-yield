'use client';

import { useAccount, useConnect, useDisconnect } from '@starknet-react/core';
import { Wallet, LogOut, Loader2 } from 'lucide-react';

export function Header() {
  const { address, isConnected } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  return (
    <header className="sticky top-0 z-50 w-full glass-panel border-b border-white/5">
      <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
        <div className="flex items-center gap-8">
          <div className="flex items-center gap-3 group cursor-pointer">
            <div className="w-10 h-10 bg-gradient-to-br from-emerald-500 to-emerald-700 rounded-xl flex items-center justify-center shadow-lg shadow-emerald-500/20 group-hover:scale-105 transition-transform">
              <span className="text-white font-bold text-lg">SY</span>
            </div>
            <div>
              <h1 className="text-lg font-bold text-white tracking-tight">StarkYield</h1>
              <div className="flex items-center gap-1.5">
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                <span className="text-[10px] uppercase font-bold text-emerald-500 tracking-widest">Mainnet</span>
              </div>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-6">
            <a href="#" className="text-sm font-medium text-zinc-400 hover:text-white transition-colors">Markets</a>
            <a href="#" className="text-sm font-medium text-zinc-400 hover:text-white transition-colors">Portfolio</a>
            <a href="#" className="text-sm font-medium text-zinc-400 hover:text-white transition-colors">Governance</a>
          </nav>
        </div>

        <div className="flex items-center gap-4">
          {isConnected ? (
            <div className="flex items-center gap-2 p-1 pl-3 bg-[#111118] border border-white/5 rounded-xl">
              <span className="text-xs font-mono text-emerald-500">
                {formatAddress(address || '')}
              </span>
              <button
                onClick={() => disconnect()}
                className="p-1.5 hover:bg-white/5 text-zinc-500 hover:text-red-400 rounded-lg transition-all"
                title="Disconnect"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              {connectors.map((connector) => (
                <button
                  key={connector.id}
                  onClick={() => connect({ connector })}
                  disabled={isPending}
                  className="flex items-center gap-2 px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-black rounded-xl font-bold text-sm transition-all shadow-lg shadow-emerald-500/10 active:scale-95 disabled:opacity-50"
                >
                  {isPending ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Wallet className="w-4 h-4" />
                  )}
                  {connector.name}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
