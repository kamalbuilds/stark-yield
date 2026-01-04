// StarkYield Contract Addresses (Starknet Mainnet)
// Deployed: January 9, 2026
import SYxSTRKAbi from './abi/sy_xstrk.json';
import TokenizerAbi from './abi/tokenizer.json';
import PrincipalTokenAbi from './abi/principal_token.json';
import YieldTokenAbi from './abi/yield_token.json';

export const CONTRACTS = {
  // Starknet Mainnet addresses
  SY_XSTRK: '0x064b00209f10d0742b4a6810f63ecd42b3a29de917f5de2bb70289a9de96963d', // SYxSTRK contract
  TOKENIZER: '0x00d427093135a5c481228648c2478563d9be0483384ceb04b2e95a8f37fa7eba', // Tokenizer contract
  PT_TOKEN: '0x017fcf185327a00359ae5f72be797d369dce5a4f680ba521490fd1a0bd37b97c', // PT-xSTRK-JUL26
  YT_TOKEN: '0x047a52c7cab3e8233984cb0ede7a533723c81f308112e7c245cae3b9699ed9c7', // YT-xSTRK-JUL26
  XSTRK: '0x028d709c875C0CEAc3dCE7065beC5328186Dc89FE254527084D1689910954B0a', // Underlying xSTRK token (Endur.fi)
} as const;

// Export ABIs from compiled contracts
export const SY_ABI = SYxSTRKAbi;
export const TOKENIZER_ABI = TokenizerAbi;
export const PT_ABI = PrincipalTokenAbi;
export const YT_ABI = YieldTokenAbi;

// Standard ERC20 ABI for token interactions
export const ERC20_ABI = [
  {
    type: 'function',
    name: 'name',
    inputs: [],
    outputs: [{ type: 'core::byte_array::ByteArray' }],
    state_mutability: 'view',
  },
  {
    type: 'function',
    name: 'symbol',
    inputs: [],
    outputs: [{ type: 'core::byte_array::ByteArray' }],
    state_mutability: 'view',
  },
  {
    type: 'function',
    name: 'decimals',
    inputs: [],
    outputs: [{ type: 'core::integer::u8' }],
    state_mutability: 'view',
  },
  {
    type: 'function',
    name: 'total_supply',
    inputs: [],
    outputs: [{ type: 'core::integer::u256' }],
    state_mutability: 'view',
  },
  {
    type: 'function',
    name: 'balance_of',
    inputs: [{ name: 'account', type: 'core::starknet::contract_address::ContractAddress' }],
    outputs: [{ type: 'core::integer::u256' }],
    state_mutability: 'view',
  },
  {
    type: 'function',
    name: 'allowance',
    inputs: [
      { name: 'owner', type: 'core::starknet::contract_address::ContractAddress' },
      { name: 'spender', type: 'core::starknet::contract_address::ContractAddress' },
    ],
    outputs: [{ type: 'core::integer::u256' }],
    state_mutability: 'view',
  },
  {
    type: 'function',
    name: 'transfer',
    inputs: [
      { name: 'recipient', type: 'core::starknet::contract_address::ContractAddress' },
      { name: 'amount', type: 'core::integer::u256' },
    ],
    outputs: [{ type: 'core::bool' }],
    state_mutability: 'external',
  },
  {
    type: 'function',
    name: 'transfer_from',
    inputs: [
      { name: 'sender', type: 'core::starknet::contract_address::ContractAddress' },
      { name: 'recipient', type: 'core::starknet::contract_address::ContractAddress' },
      { name: 'amount', type: 'core::integer::u256' },
    ],
    outputs: [{ type: 'core::bool' }],
    state_mutability: 'external',
  },
  {
    type: 'function',
    name: 'approve',
    inputs: [
      { name: 'spender', type: 'core::starknet::contract_address::ContractAddress' },
      { name: 'amount', type: 'core::integer::u256' },
    ],
    outputs: [{ type: 'core::bool' }],
    state_mutability: 'external',
  },
];

// Scale factor for 18 decimal tokens
export const SCALE = BigInt('1000000000000000000');

// Maturity date (July 2026)
export const MATURITY_TIMESTAMP = 1783513797;

export function formatTokenAmount(amount: bigint, decimals: number = 18): string {
  const divisor = BigInt(10 ** decimals);
  const intPart = amount / divisor;
  const fracPart = amount % divisor;
  const fracStr = fracPart.toString().padStart(decimals, '0').slice(0, 4);
  return `${intPart}.${fracStr}`;
}

export function parseTokenAmount(amount: string, decimals: number = 18): bigint {
  const [intPart, fracPart = ''] = amount.split('.');
  const paddedFrac = fracPart.padEnd(decimals, '0').slice(0, decimals);
  return BigInt(intPart + paddedFrac);
}

export function formatAPY(apy: bigint): string {
  // APY is in basis points (1% = 100)
  const percentage = Number(apy) / 100;
  return percentage.toFixed(2) + '%';
}

export function formatMaturityDate(): string {
  const date = new Date(MATURITY_TIMESTAMP * 1000);
  return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
}

export function isMatured(): boolean {
  return Date.now() / 1000 >= MATURITY_TIMESTAMP;
}

export function daysToMaturity(): number {
  const now = Date.now() / 1000;
  if (now >= MATURITY_TIMESTAMP) return 0;
  return Math.ceil((MATURITY_TIMESTAMP - now) / (24 * 60 * 60));
}
