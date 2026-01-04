import { create } from 'zustand';

interface YieldState {
  // User balances
  xstrkBalance: bigint;
  syBalance: bigint;
  ptBalance: bigint;
  ytBalance: bigint;

  // Protocol data
  exchangeRate: bigint;
  apyBps: number;
  maturityTimestamp: number;
  isMatured: boolean;
  totalSyLocked: bigint;

  // UI state
  selectedTab: 'deposit' | 'tokenize' | 'redeem';
  isLoading: boolean;

  // Actions
  setBalances: (balances: Partial<{
    xstrkBalance: bigint;
    syBalance: bigint;
    ptBalance: bigint;
    ytBalance: bigint;
  }>) => void;
  setProtocolData: (data: Partial<{
    exchangeRate: bigint;
    apyBps: number;
    maturityTimestamp: number;
    isMatured: boolean;
    totalSyLocked: bigint;
  }>) => void;
  setSelectedTab: (tab: 'deposit' | 'tokenize' | 'redeem') => void;
  setIsLoading: (loading: boolean) => void;
}

export const useYieldStore = create<YieldState>((set) => ({
  // Initial balances
  xstrkBalance: BigInt(0),
  syBalance: BigInt(0),
  ptBalance: BigInt(0),
  ytBalance: BigInt(0),

  // Initial protocol data
  exchangeRate: BigInt('1000000000000000000'), // 1:1
  apyBps: 500, // 5%
  maturityTimestamp: 0,
  isMatured: false,
  totalSyLocked: BigInt(0),

  // Initial UI state
  selectedTab: 'deposit',
  isLoading: false,

  // Actions
  setBalances: (balances) => set((state) => ({ ...state, ...balances })),
  setProtocolData: (data) => set((state) => ({ ...state, ...data })),
  setSelectedTab: (tab) => set({ selectedTab: tab }),
  setIsLoading: (loading) => set({ isLoading: loading }),
}));
