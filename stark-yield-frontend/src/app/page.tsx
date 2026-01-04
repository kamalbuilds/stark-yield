'use client';

import { useState } from 'react';
import { Header } from '@/components/header';
import { DepositPanel } from '@/components/deposit-panel';
import { TokenizePanel } from '@/components/tokenize-panel';
import { StatsPanel } from '@/components/stats-panel';
import { useYieldStore } from '@/lib/store';
import { Coins, Layers, ArrowLeftRight } from 'lucide-react';

type MainTab = 'deposit' | 'tokenize';

export default function Home() {
  const [mainTab, setMainTab] = useState<MainTab>('deposit');
  const { setSelectedTab } = useYieldStore();

  return (
    <div className="min-h-screen bg-[#030305] selection:bg-emerald-500/30">
      <Header />

      <main className="max-w-7xl mx-auto px-4 py-10">
        <div className="grid lg:grid-cols-12 gap-8">
          {/* Action Center - Left/Central */}
          <div className="lg:col-span-8 space-y-8">
            <div className="glass-card rounded-[2rem] p-1 border-white/5 shadow-2xl overflow-hidden">
              <div className="flex bg-[#0a0a0f] rounded-t-[1.9rem] border-b border-white/5">
                <button
                  onClick={() => setMainTab('deposit')}
                  className={`flex-1 flex items-center justify-center gap-3 py-5 text-sm font-bold transition-all relative ${mainTab === 'deposit'
                    ? 'text-emerald-400 bg-emerald-500/5'
                    : 'text-zinc-500 hover:text-zinc-300 hover:bg-white/5'
                    }`}
                >
                  <Coins className={`w-4 h-4 ${mainTab === 'deposit' ? 'animate-pulse' : ''}`} />
                  Wrap xSTRK
                  {mainTab === 'deposit' && (
                    <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
                  )}
                </button>
                <button
                  onClick={() => { setMainTab('tokenize'); setSelectedTab('tokenize'); }}
                  className={`flex-1 flex items-center justify-center gap-3 py-5 text-sm font-bold transition-all relative ${mainTab === 'tokenize'
                    ? 'text-emerald-400 bg-emerald-500/5'
                    : 'text-zinc-500 hover:text-zinc-300 hover:bg-white/5'
                    }`}
                >
                  <Layers className={`w-4 h-4 ${mainTab === 'tokenize' ? 'animate-pulse' : ''}`} />
                  Tokenize Yield
                  {mainTab === 'tokenize' && (
                    <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]" />
                  )}
                </button>
              </div>

              <div className="p-8 bg-[#0a0a0f]/40 backdrop-blur-sm">
                {mainTab === 'deposit' ? (
                  <DepositPanel />
                ) : (
                  <TokenizePanel />
                )}
              </div>
            </div>

            {/* Token Flow - Visual Diagram */}
            <div className="glass-card rounded-[2rem] p-8 border-white/5 relative overflow-hidden group">
              <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                <Layers className="w-32 h-32" />
              </div>

              <h3 className="text-xs uppercase tracking-[0.2em] font-black text-emerald-500/60 mb-8 px-2">
                Yield Tokenization Architecture
              </h3>

              <div className="relative flex flex-col md:flex-row items-center justify-between gap-6 px-4">
                <TokenBox label="xSTRK" sublabel="LST Token" color="zinc" />
                <Arrow />
                <TokenBox label="SY-xSTRK" sublabel="Std. Yield" color="emerald" glow />
                <Arrow />
                <div className="flex flex-col gap-4">
                  <TokenBox label="PT-xSTRK" sublabel="Principal" color="blue" small />
                  <div className="flex justify-center">
                    <div className="h-4 w-px bg-zinc-800" />
                  </div>
                  <TokenBox label="YT-xSTRK" sublabel="Yield" color="purple" small />
                </div>
              </div>

              <p className="mt-8 text-xs text-zinc-500 font-medium leading-relaxed max-w-xl mx-auto text-center italic">
                Separating yield from principal allows for advanced delta-neutral strategies and fixed-rate maturity cycles on Starknet.
              </p>
            </div>
          </div>

          {/* Sidebar - Right */}
          <div className="lg:col-span-4 space-y-6">
            <StatsPanel />

            <div className="grid grid-cols-1 gap-4">
              <FeatureCard
                icon={<Coins className="w-5 h-5 text-emerald-500" />}
                title="Fixed Yield"
                description="Hedge against rate volatility."
              />
              <FeatureCard
                icon={<Layers className="w-5 h-5 text-purple-500" />}
                title="Leveraged Yield"
                description="Long yield expectations."
              />
            </div>
          </div>
        </div>
      </main>

      <footer className="py-12 border-t border-white/5 mt-auto">
        <div className="max-w-7xl mx-auto px-4 flex flex-col md:flex-row justify-between items-center gap-4 text-[10px] uppercase tracking-widest font-bold text-zinc-600">
          <div>© 2026 STARK-YIELD LABS</div>
          <div className="flex gap-8">
            <a href="#" className="hover:text-emerald-500 transition-colors">Documentation</a>
            <a href="#" className="hover:text-emerald-500 transition-colors">Governance</a>
            <a href="#" className="hover:text-emerald-500 transition-colors">Security</a>
          </div>
        </div>
      </footer>
    </div>
  );
}

function TokenBox({
  label,
  sublabel,
  color,
  small,
  glow
}: {
  label: string;
  sublabel: string;
  color: 'zinc' | 'emerald' | 'blue' | 'purple';
  small?: boolean;
  glow?: boolean;
}) {
  const colorClasses = {
    zinc: 'bg-zinc-500/5 border-zinc-500/20 text-zinc-300',
    emerald: 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400',
    blue: 'bg-blue-500/10 border-blue-500/30 text-blue-400',
    purple: 'bg-purple-500/10 border-purple-500/30 text-purple-400',
  };

  return (
    <div className={`
      ${small ? 'px-4 py-3 min-w-[120px]' : 'px-8 py-5 min-w-[160px]'} 
      rounded-2xl border transition-all duration-500
      ${colorClasses[color]}
      ${glow ? 'shadow-[0_0_30px_rgba(16,185,129,0.15)] glow-emerald' : ''}
    `}>
      <div className={`font-black tracking-tight ${small ? 'text-sm' : 'text-xl'}`}>{label}</div>
      <div className={`font-bold opacity-50 uppercase tracking-tighter ${small ? 'text-[10px]' : 'text-xs'}`}>{sublabel}</div>
    </div>
  );
}

function Arrow() {
  return (
    <div className="text-zinc-800 flex items-center">
      <div className="w-8 h-[2px] bg-gradient-to-r from-zinc-800/0 via-zinc-800 to-zinc-800/0" />
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  description
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
}) {
  return (
    <div className="glass-card rounded-[1.5rem] p-5 border-white/5 hover:border-white/10 transition-all group cursor-default">
      <div className="flex items-center gap-4">
        <div className="p-3 bg-zinc-900 rounded-xl group-hover:scale-110 transition-transform">
          {icon}
        </div>
        <div>
          <h3 className="text-sm font-bold text-white mb-0.5">{title}</h3>
          <p className="text-xs text-zinc-500 font-medium">{description}</p>
        </div>
      </div>
    </div>
  );
}
