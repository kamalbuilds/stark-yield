'use client';

import { useState } from 'react';
import { useAccount } from '@starknet-react/core';
import { useYieldStore } from '@/lib/store';
import { formatTokenAmount, parseTokenAmount, SCALE } from '@/lib/contracts';
import { useStarkYieldContracts } from '@/hooks/use-starkyield-contracts';
import { ArrowDown, Loader2, Info, TrendingUp, Calendar } from 'lucide-react';

export function TokenizePanel() {
  const { address, isConnected } = useAccount();
  const {
    syBalance,
    ptBalance,
    ytBalance,
    apyBps,
    maturityTimestamp,
    isMatured,
    selectedTab,
    setSelectedTab,
    isLoading
  } = useYieldStore();
  const { approveSYForTokenizer, tokenize, approvePTYTForTokenizer, redeem, redeemPT, isPending, txHash } = useStarkYieldContracts();

  const [amount, setAmount] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);

  const apy = apyBps / 100;
  const maturityDate = new Date(maturityTimestamp * 1000);
  const daysUntilMaturity = Math.max(0, Math.ceil((maturityTimestamp * 1000 - Date.now()) / (1000 * 60 * 60 * 24)));

  const handleTokenize = async () => {
    if (!address || !amount) return;
    setIsProcessing(true);
    try {
      const tokenizeAmount = parseTokenAmount(amount);
      // Step 1: Approve SY for Tokenizer
      await approveSYForTokenizer(tokenizeAmount);
      // Step 2: Tokenize SY into PT + YT
      await tokenize(tokenizeAmount);
      setAmount('');
    } catch (error) {
      console.error('Tokenize failed:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleRedeem = async () => {
    if (!address || !amount) return;
    setIsProcessing(true);
    try {
      const redeemAmount = parseTokenAmount(amount);
      if (isMatured) {
        // After maturity: redeem PT only for underlying
        await redeemPT(redeemAmount);
      } else {
        // Before maturity: need both PT + YT
        // Step 1: Approve PT and YT for Tokenizer
        await approvePTYTForTokenizer(redeemAmount);
        // Step 2: Redeem PT + YT for SY
        await redeem(redeemAmount);
      }
      setAmount('');
    } catch (error) {
      console.error('Redeem failed:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const parsedAmount = amount ? parseTokenAmount(amount) : BigInt(0);
  const canTokenize = parsedAmount > 0 && parsedAmount <= syBalance && !isMatured;
  const canRedeem = parsedAmount > 0 && (isMatured ? parsedAmount <= ptBalance : (parsedAmount <= ptBalance && parsedAmount <= ytBalance));

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="flex p-1 bg-[#111118] rounded-2xl border border-white/5">
        <button
          onClick={() => setSelectedTab('tokenize')}
          className={`flex-1 py-3 text-xs font-black uppercase tracking-widest transition-all rounded-xl ${selectedTab === 'tokenize'
              ? 'text-emerald-400 bg-emerald-500/10 shadow-[0_0_20px_rgba(16,185,129,0.1)]'
              : 'text-zinc-600 hover:text-zinc-400'
            }`}
        >
          Tokenize
        </button>
        <button
          onClick={() => setSelectedTab('redeem')}
          className={`flex-1 py-3 text-xs font-black uppercase tracking-widest transition-all rounded-xl ${selectedTab === 'redeem'
              ? 'text-emerald-400 bg-emerald-500/10 shadow-[0_0_20px_rgba(16,185,129,0.1)]'
              : 'text-zinc-600 hover:text-zinc-400'
            }`}
        >
          Redeem
        </button>
      </div>

      <div className="space-y-4">
        {/* Market Context */}
        <div className="grid grid-cols-2 gap-4">
          <div className="p-3 bg-emerald-500/5 border border-emerald-500/10 rounded-xl flex items-center justify-between">
            <span className="text-[9px] font-black uppercase tracking-widest text-zinc-600">Current APY</span>
            <span className="text-xs font-black text-emerald-500">{apy.toFixed(2)}%</span>
          </div>
          <div className={`p-3 border rounded-xl flex items-center justify-between ${isMatured ? 'bg-emerald-500/5 border-emerald-500/10' : 'bg-blue-500/5 border-blue-500/10'}`}>
            <span className="text-[9px] font-black uppercase tracking-widest text-zinc-600">Remaining</span>
            <span className={`text-xs font-black ${isMatured ? 'text-emerald-500' : 'text-blue-500'}`}>{isMatured ? 'Finalized' : `${daysUntilMaturity}D`}</span>
          </div>
        </div>

        {selectedTab === 'tokenize' ? (
          <>
            {/* Input: SY Amount */}
            <div className="relative group">
              <div className="flex items-center justify-between mb-2.5 px-1">
                <label className="text-[10px] uppercase tracking-widest font-black text-zinc-500 group-focus-within:text-emerald-500 transition-colors">
                  Tokenize SY
                </label>
                <div className="flex items-center gap-1.5">
                  <span className="text-[10px] font-bold text-zinc-600">Balance:</span>
                  <span className="text-[10px] font-black text-zinc-400">{formatTokenAmount(syBalance)} SY</span>
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
                  onClick={() => setAmount(formatTokenAmount(syBalance))}
                  className="absolute right-4 top-1/2 -translate-y-1/2 px-3 py-1.5 bg-emerald-500/10 text-emerald-500 text-[10px] font-black uppercase tracking-tighter rounded-lg hover:bg-emerald-500/20 transition-all border border-emerald-500/20"
                >
                  MAX
                </button>
              </div>
            </div>

            <div className="flex justify-center -my-2 relative z-10">
              <div className="w-10 h-10 rounded-full bg-[#111118] border border-white/5 flex items-center justify-center shadow-2xl">
                <ArrowDown className="w-4 h-4 text-emerald-500" />
              </div>
            </div>

            {/* Output: PT + YT Preview */}
            <div className="grid grid-cols-2 gap-4">
              <div className="p-5 bg-blue-500/5 border border-blue-500/10 rounded-2xl group hover:border-blue-500/30 transition-all">
                <div className="text-[9px] font-black uppercase tracking-widest text-zinc-600 mb-2 group-hover:text-blue-400">Principal (PT)</div>
                <div className="text-xl font-black text-blue-400 border-b border-blue-500/10 pb-2 mb-2">{amount || '0.00'}</div>
                <p className="text-[9px] text-zinc-500 font-bold leading-tight">Fixed yield instrument.</p>
              </div>
              <div className="p-5 bg-purple-500/5 border border-purple-500/10 rounded-2xl group hover:border-purple-500/30 transition-all">
                <div className="text-[9px] font-black uppercase tracking-widest text-zinc-600 mb-2 group-hover:text-purple-400">Yield (YT)</div>
                <div className="text-xl font-black text-purple-400 border-b border-purple-500/10 pb-2 mb-2">{amount || '0.00'}</div>
                <p className="text-[9px] text-zinc-500 font-bold leading-tight">Leveraged yield rights.</p>
              </div>
            </div>

            {/* Tokenize Button */}
            <button
              onClick={handleTokenize}
              disabled={!isConnected || !canTokenize || isProcessing || isMatured}
              className={`w-full py-5 rounded-[1.25rem] font-black uppercase tracking-[0.2em] text-sm transition-all flex items-center justify-center gap-3 shadow-lg ${!isConnected || !canTokenize || isProcessing || isMatured
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
              ) : isMatured ? (
                'Matured'
              ) : (
                'Initiate Tokenization'
              )}
            </button>
          </>
        ) : (
          <>
            {/* Redeem UI */}
            <div className="relative group">
              <div className="flex items-center justify-between mb-2.5 px-1">
                <label className="text-[10px] uppercase tracking-widest font-black text-zinc-500 group-focus-within:text-emerald-500 transition-colors">
                  Redeem PT/YT
                </label>
                <div className="flex items-center gap-1.5">
                  <span className="text-[10px] font-bold text-zinc-600">PT:</span>
                  <span className="text-[10px] font-black text-blue-400 mr-2">{formatTokenAmount(ptBalance)}</span>
                  <span className="text-[10px] font-bold text-zinc-600">YT:</span>
                  <span className="text-[10px] font-black text-purple-400">{formatTokenAmount(ytBalance)}</span>
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
                  onClick={() => {
                    const maxAmount = isMatured ? ptBalance : (ptBalance < ytBalance ? ptBalance : ytBalance);
                    setAmount(formatTokenAmount(maxAmount));
                  }}
                  className="absolute right-4 top-1/2 -translate-y-1/2 px-3 py-1.5 bg-emerald-500/10 text-emerald-500 text-[10px] font-black uppercase tracking-tighter rounded-lg hover:bg-emerald-500/20 transition-all border border-emerald-500/20"
                >
                  MAX
                </button>
              </div>
            </div>

            <div className="flex justify-center -my-2 relative z-10">
              <div className="w-10 h-10 rounded-full bg-[#111118] border border-white/5 flex items-center justify-center shadow-2xl">
                <ArrowDown className="w-4 h-4 text-emerald-500" />
              </div>
            </div>

            {/* Output: SY Preview */}
            <div className="p-5 bg-emerald-500/5 border border-emerald-500/10 rounded-2xl group hover:border-emerald-500/30 transition-all">
              <div className="text-[9px] font-black uppercase tracking-widest text-zinc-600 mb-2 group-hover:text-emerald-400">Receive Output (SY)</div>
              <div className="text-xl font-black text-emerald-400">{amount || '0.00'}</div>
            </div>

            {/* Redeem Button */}
            <button
              onClick={handleRedeem}
              disabled={!isConnected || !canRedeem || isProcessing}
              className={`w-full py-5 rounded-[1.25rem] font-black uppercase tracking-[0.2em] text-sm transition-all flex items-center justify-center gap-3 shadow-lg ${!isConnected || !canRedeem || isProcessing
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
                'Confirm Redemption'
              )}
            </button>
          </>
        )}
      </div>
    </div>
  );
}
