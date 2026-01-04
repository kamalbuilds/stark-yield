'use client';

import { useState } from 'react';
import { useAccount } from '@starknet-react/core';
import { useYieldStore } from '@/lib/store';
import { formatTokenAmount, parseTokenAmount, SCALE } from '@/lib/contracts';
import { useStarkYieldContracts } from '@/hooks/use-starkyield-contracts';
import { ArrowDown, Loader2, Info, ArrowRightLeft } from 'lucide-react';

type Mode = 'deposit' | 'withdraw';

export function DepositPanel() {
  const { address, isConnected } = useAccount();
  const { xstrkBalance, syBalance, exchangeRate, isLoading } = useYieldStore();
  const { approveXSTRK, depositToSY, withdrawFromSY, isPending, txHash } = useStarkYieldContracts();

  const [mode, setMode] = useState<Mode>('deposit');
  const [amount, setAmount] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  // Calculate preview amounts based on exchange rate
  const parsedAmount = amount ? parseTokenAmount(amount) : BigInt(0);
  const previewAmount = mode === 'deposit'
    ? (parsedAmount * SCALE) / exchangeRate
    : (parsedAmount * exchangeRate) / SCALE;

  const handleDeposit = async () => {
    if (!address || !amount) return;
    setIsProcessing(true);
    try {
      const depositAmount = parseTokenAmount(amount);
      // Step 1: Approve xSTRK for SY contract
      await approveXSTRK(depositAmount);
      // Step 2: Deposit xSTRK to get SY tokens
      await depositToSY(depositAmount);
      setAmount('');
    } catch (error) {
      console.error('Deposit failed:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleWithdraw = async () => {
    if (!address || !amount) return;
    setIsProcessing(true);
    try {
      const withdrawAmount = parseTokenAmount(amount);
      // Withdraw SY to get xSTRK back
      await withdrawFromSY(withdrawAmount);
      setAmount('');
    } catch (error) {
      console.error('Withdraw failed:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const canDeposit = parsedAmount > 0 && parsedAmount <= xstrkBalance;
  const canWithdraw = parsedAmount > 0 && parsedAmount <= syBalance;

  return (
    <div className="space-y-6">
      {/* Mode Toggle */}
      <div className="flex p-1 bg-[#111118] rounded-2xl border border-white/5">
        <button
          onClick={() => { setMode('deposit'); setAmount(''); }}
          className={`flex-1 py-3 text-xs font-black uppercase tracking-widest transition-all rounded-xl ${mode === 'deposit'
              ? 'text-emerald-400 bg-emerald-500/10 shadow-[0_0_20px_rgba(16,185,129,0.1)]'
              : 'text-zinc-600 hover:text-zinc-400'
            }`}
        >
          Wrap
        </button>
        <button
          onClick={() => { setMode('withdraw'); setAmount(''); }}
          className={`flex-1 py-3 text-xs font-black uppercase tracking-widest transition-all rounded-xl ${mode === 'withdraw'
              ? 'text-emerald-400 bg-emerald-500/10 shadow-[0_0_20px_rgba(16,185,129,0.1)]'
              : 'text-zinc-600 hover:text-zinc-400'
            }`}
        >
          Unwrap
        </button>
      </div>

      <div className="space-y-4">
        {/* Input */}
        <div className="relative group">
          <div className="flex items-center justify-between mb-2.5 px-1">
            <label className="text-[10px] uppercase tracking-widest font-black text-zinc-500 group-focus-within:text-emerald-500 transition-colors">
              Deposit Amount
            </label>
            <div className="flex items-center gap-1.5">
              <span className="text-[10px] font-bold text-zinc-600">Balance:</span>
              <span className="text-[10px] font-black text-zinc-400">
                {formatTokenAmount(mode === 'deposit' ? xstrkBalance : syBalance)} {mode === 'deposit' ? 'xSTRK' : 'SY'}
              </span>
            </div>
          </div>

          <div className="relative overflow-hidden rounded-[1.25rem] border border-white/5 bg-[#111118] focus-within:border-emerald-500/30 transition-all focus-within:shadow-[0_0_30px_rgba(16,185,129,0.05)]">
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="w-full pl-6 pr-20 py-6 bg-transparent text-white text-2xl font-black placeholder:text-zinc-800 focus:outline-none"
            />
            <button
              onClick={() => setAmount(formatTokenAmount(mode === 'deposit' ? xstrkBalance : syBalance))}
              className="absolute right-4 top-1/2 -translate-y-1/2 px-3 py-1.5 bg-emerald-500/10 text-emerald-500 text-[10px] font-black uppercase tracking-tighter rounded-lg hover:bg-emerald-500/20 transition-all border border-emerald-500/20"
            >
              MAX
            </button>
          </div>
        </div>

        {/* Arrow / Exchange Rate */}
        <div className="flex items-center justify-center -my-2 relative z-10">
          <div className="w-10 h-10 rounded-full bg-[#111118] border border-white/5 flex items-center justify-center shadow-2xl">
            <ArrowDown className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="absolute right-0 flex items-center gap-2 px-3 py-1 bg-white/5 rounded-full border border-white/5">
            <span className="text-[9px] font-bold text-zinc-500 uppercase tracking-tighter">1 SY = {formatTokenAmount(exchangeRate)} xSTRK</span>
          </div>
        </div>

        {/* Output */}
        <div className="relative group">
          <div className="flex items-center justify-between mb-2.5 px-1">
            <label className="text-[10px] uppercase tracking-widest font-black text-zinc-500">
              You Receive
            </label>
          </div>

          <div className="relative overflow-hidden rounded-[1.25rem] border border-white/5 bg-[#0a0a0f] transition-all">
            <div className="w-full px-6 py-6 text-emerald-400 text-2xl font-black flex items-center justify-between">
              <span>{amount ? formatTokenAmount(previewAmount) : '0.00'}</span>
              <span className="text-xs uppercase tracking-widest text-emerald-500/50">{mode === 'deposit' ? 'SY-xSTRK' : 'xSTRK'}</span>
            </div>
          </div>
        </div>

        {/* Info Text */}
        <div className="p-4 rounded-xl bg-blue-500/5 border border-blue-500/10">
          <div className="flex gap-3">
            <Info className="w-4 h-4 text-blue-500 shrink-0 mt-0.5" />
            <p className="text-[10px] text-zinc-500 font-medium leading-normal">
              {mode === 'deposit' ? (
                "SY-xSTRK is a standardized yield token. Your xSTRK will be wrapped and start accruing yield immediately on Starknet."
              ) : (
                "Unwrapping your SY-xSTRK will return your principal plus all accrued yield in xSTRK at the current exchange rate."
              )}
            </p>
          </div>
        </div>

        {/* Action Button */}
        <button
          onClick={mode === 'deposit' ? handleDeposit : handleWithdraw}
          disabled={!isConnected || (mode === 'deposit' ? !canDeposit : !canWithdraw) || isProcessing}
          className={`w-full py-5 rounded-[1.25rem] font-black uppercase tracking-[0.2em] text-sm transition-all flex items-center justify-center gap-3 shadow-lg ${!isConnected || (mode === 'deposit' ? !canDeposit : !canWithdraw) || isProcessing
              ? 'bg-zinc-900 text-zinc-600 border border-white/5'
              : 'bg-emerald-500 text-black hover:bg-emerald-400 shadow-emerald-500/20 active:scale-[0.98]'
            }`}
        >
          {isProcessing ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              Processing
            </>
          ) : !isConnected ? (
            'Connect Wallet'
          ) : (
            mode === 'deposit' ? 'Confirm Wrap' : 'Confirm Unwrap'
          )}
        </button>
      </div>
    </div>
  );
}
