'use client';

import { useYieldStore } from '@/lib/store';
import { formatTokenAmount } from '@/lib/contracts';
import { TrendingUp, Lock, Coins, Calendar, Percent, Activity } from 'lucide-react';

export function StatsPanel() {
  const {
    syBalance,
    ptBalance,
    ytBalance,
    exchangeRate,
    apyBps,
    totalSyLocked,
    maturityTimestamp,
    isMatured
  } = useYieldStore();

  const apy = apyBps / 100;
  const maturityDate = new Date(maturityTimestamp * 1000);
  const daysUntilMaturity = Math.max(0, Math.ceil((maturityTimestamp * 1000 - Date.now()) / (1000 * 60 * 60 * 24)));

  return (
    <div className="space-y-4">
      {/* Protocol Stats */}
      <div className="glass-card rounded-[2rem] p-6 border-white/5 shadow-2xl">
        <h3 className="text-[10px] font-black text-emerald-500 uppercase tracking-[0.2em] mb-6 flex items-center gap-2">
          <Activity className="w-3 h-3" />
          Protocol Engine
        </h3>

        <div className="space-y-5">
          <StatRow
            label="Live Yield APY"
            value={`${apy.toFixed(2)}%`}
            highlight
          />
          <StatRow
            label="Standard Exchange"
            value={`${formatTokenAmount(exchangeRate)} xSTRK`}
          />
          <StatRow
            label="Total Value Locked"
            value={`${formatTokenAmount(totalSyLocked)} SY`}
          />
          <StatRow
            label="Maturity Status"
            value={isMatured ? 'Finalized' : `${daysUntilMaturity} Days`}
            subValue={maturityDate.toLocaleDateString()}
          />
        </div>
      </div>

      {/* Your Balances */}
      <div className="glass-card rounded-[2rem] p-6 border-white/5">
        <h3 className="text-[10px] font-black text-zinc-500 uppercase tracking-[0.2em] mb-6 flex items-center gap-2">
          <Coins className="w-3 h-3" />
          Portfolio Overview
        </h3>

        <div className="space-y-3">
          <BalanceRow
            token="SY-xSTRK"
            balance={formatTokenAmount(syBalance)}
            color="emerald"
          />
          <BalanceRow
            token="PT-xSTRK"
            balance={formatTokenAmount(ptBalance)}
            color="blue"
          />
          <BalanceRow
            token="YT-xSTRK"
            balance={formatTokenAmount(ytBalance)}
            color="purple"
          />
        </div>
      </div>

      {/* Quick Guide */}
      <div className="glass-panel rounded-[2rem] p-6 border-emerald-500/10 bg-emerald-500/[0.02]">
        <h3 className="text-[10px] font-black text-white uppercase tracking-[0.2em] mb-4">Operations</h3>
        <div className="space-y-3">
          <Step number={1} text="Wrap xSTRK to SY" />
          <Step number={2} text="Split SY into PT + YT" />
          <Step number={3} text="Trade yield exposure" />
        </div>
      </div>
    </div>
  );
}

function StatRow({
  label,
  value,
  subValue,
  highlight
}: {
  label: string;
  value: string;
  subValue?: string;
  highlight?: boolean;
}) {
  return (
    <div className="flex items-center justify-between group">
      <span className="text-[10px] font-black uppercase tracking-widest text-zinc-600 group-hover:text-zinc-400 transition-colors">{label}</span>
      <div className="text-right">
        <div className={`text-sm font-black tracking-tight ${highlight ? 'text-emerald-500 glow-emerald' : 'text-white'}`}>
          {value}
        </div>
        {subValue && (
          <div className="text-[9px] font-bold text-zinc-600 uppercase tracking-tighter">{subValue}</div>
        )}
      </div>
    </div>
  );
}

function BalanceRow({
  token,
  balance,
  color
}: {
  token: string;
  balance: string;
  color: 'emerald' | 'blue' | 'purple';
}) {
  const colorClasses = {
    emerald: 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20 shadow-[0_0_15px_rgba(16,185,129,0.05)]',
    blue: 'text-blue-500 bg-blue-500/10 border-blue-500/20',
    purple: 'text-purple-500 bg-purple-500/10 border-purple-500/20',
  };

  return (
    <div className="flex items-center justify-between p-3.5 bg-[#0a0a0f] border border-white/5 rounded-[1.25rem] hover:border-white/10 transition-all">
      <span className={`px-2.5 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest border ${colorClasses[color]}`}>
        {token}
      </span>
      <span className="text-sm font-black text-white tracking-tight">{balance}</span>
    </div>
  );
}

function Step({ number, text }: { number: number; text: string }) {
  return (
    <div className="flex items-center gap-3 group">
      <div className="w-5 h-5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 flex items-center justify-center text-[9px] font-black group-hover:bg-emerald-500 group-hover:text-black transition-all">
        {number}
      </div>
      <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-tight group-hover:text-zinc-300 transition-colors">{text}</p>
    </div>
  );
}
