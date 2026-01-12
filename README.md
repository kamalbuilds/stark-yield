# StarkYield - Yield Tokenization Protocol

A Pendle-like yield tokenization protocol on Starknet that splits yield-bearing assets into Principal Tokens (PT) and Yield Tokens (YT).

## Overview

StarkYield enables users to separate the principal and yield components of yield-bearing tokens. This unlocks powerful DeFi strategies including fixed-rate yields, yield speculation, and capital-efficient farming.

### Value Proposition

- **Yield Tokenization**: Split any yield-bearing asset into PT and YT
- **Fixed-Rate Yields**: Lock in yields by holding PT to maturity
- **Yield Speculation**: Trade future yields via YT tokens
- **Capital Efficiency**: Maximize returns with sophisticated strategies
- **First on Starknet**: Pioneer yield tokenization in the Starknet ecosystem

## How It Works

### Core Mechanism

1. **Wrap Asset**: Deposit xSTRK to receive SY-xSTRK (Standardized Yield token)
2. **Tokenize**: Split SY into PT (Principal Token) and YT (Yield Token)
3. **Trade/Hold**: Use PT for fixed yields, YT for yield speculation
4. **Redeem**: At maturity, PT holders receive principal, YT holders receive accumulated yield

### Token Types

| Token | Description | Value at Maturity |
|-------|-------------|-------------------|
| **SY** | Standardized Yield wrapper | Underlying + Yield |
| **PT** | Principal Token | 1:1 with underlying |
| **YT** | Yield Token | Accumulated yield |

### Example Flow

```
1 xSTRK → 1 SY-xSTRK → 1 PT-xSTRK-JUL26 + 1 YT-xSTRK-JUL26

At maturity (July 2026):
- PT holder receives: 1 xSTRK
- YT holder receives: All staking rewards accumulated
```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│    xSTRK        │────▶│    SY-xSTRK      │────▶│   Tokenizer     │
│  (Underlying)   │     │  (SY Wrapper)    │     │  (Split Logic)  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                          │
                                    ┌─────────────────────┴─────────────────────┐
                                    ▼                                           ▼
                           ┌─────────────────┐                         ┌─────────────────┐
                           │  PT-xSTRK-JUL26 │                         │  YT-xSTRK-JUL26 │
                           │  (Principal)    │                         │  (Yield)        │
                           └─────────────────┘                         └─────────────────┘
```

## Contract Addresses (Starknet Mainnet)

| Contract | Address |
|----------|---------|
| SY-xSTRK | `0x064b00209f10d0742b4a6810f63ecd42b3a29de917f5de2bb70289a9de96963d` |
| Tokenizer | `0x00d427093135a5c481228648c2478563d9be0483384ceb04b2e95a8f37fa7eba` |
| PT-xSTRK-JUL26 | `0x017fcf185327a00359ae5f72be797d369dce5a4f680ba521490fd1a0bd37b97c` |
| YT-xSTRK-JUL26 | `0x047a52c7cab3e8233984cb0ede7a533723c81f308112e7c245cae3b9699ed9c7` |
| xSTRK | `0x028d709c875C0CEAc3dCE7065beC5328186Dc89FE254527084D1689910954B0a` |

## Technical Stack

### Smart Contracts
- **Language**: Cairo 2.14.0
- **Framework**: Scarb 2.10.1
- **Testing**: 35/35 tests passing
- **Deployment**: sncast 0.53.0

### Frontend
- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS
- **Wallet**: starknet-react, get-starknet
- **State**: Zustand

## Key Features

### For Fixed-Rate Seekers
- Buy PT at discount, receive full principal at maturity
- Lock in current yields regardless of future rate changes
- Capital-efficient fixed income

### For Yield Speculators
- Buy YT to gain leveraged yield exposure
- Profit if yields exceed implied rate
- Trade yield expectations like commodities

### For LPs (Future)
- Provide PT/SY liquidity
- Earn trading fees + yield
- Auto-compounding strategies

## Core Functions

### Deposit (xSTRK → SY)
```cairo
fn deposit(
    ref self: ContractState,
    receiver: ContractAddress,
    amount: u256
) -> u256
```

### Tokenize (SY → PT + YT)
```cairo
fn tokenize(
    ref self: ContractState,
    receiver: ContractAddress,
    sy_amount: u256
) -> (u256, u256)
```

### Redeem PT (at maturity)
```cairo
fn redeem_pt(
    ref self: ContractState,
    receiver: ContractAddress,
    pt_amount: u256
) -> u256
```

### Claim Yield (YT)
```cairo
fn claim_yield(
    ref self: ContractState,
    receiver: ContractAddress,
    yt_amount: u256
) -> u256
```

## User Flow

1. **Connect Wallet** - ArgentX or Braavos
2. **Approve xSTRK** - Allow SY contract to spend tokens
3. **Deposit** - Convert xSTRK to SY-xSTRK
4. **Approve SY** - Allow Tokenizer to spend SY
5. **Tokenize** - Split SY into PT + YT
6. **Trade/Hold** - Use tokens for your strategy
7. **Redeem** - At maturity, claim principal (PT) or yield (YT)

## Strategies

### Fixed Yield (Conservative)
1. Buy PT at discount
2. Hold until maturity
3. Receive guaranteed principal
4. **APY**: Discount × (365 / Days to Maturity)

### Yield Farming (Aggressive)
1. Buy YT
2. Exposure to all future yield
3. Profit if yields stay high
4. **Leverage**: Full yield for fraction of principal cost

### Covered Yield (Balanced)
1. Hold SY
2. Sell YT for immediate income
3. Keep PT for principal protection
4. **Result**: Fixed income + guaranteed principal

## Development

### Prerequisites
- Scarb 2.10.1
- sncast 0.53.0
- Node.js 18+

### Build Contracts
```bash
cd contracts
scarb build
```

### Run Tests
```bash
scarb test
```

### Deploy
```bash
sncast --account mainnet deploy --class-hash <class_hash>
```

### Run Frontend
```bash
cd frontend
npm install
npm run dev
```

## Test Transactions (Mainnet)

| Action | Transaction Hash |
|--------|-----------------|
| Approve xSTRK | `0x01506f4bec039971214e85ce7c1d12857cd14757dc9519939ea204662262f1ef` |
| Deposit xSTRK | `0x010be2e98b92b7a4348d5669bc0e068b7001e8bcaea8b83b6960f461a9c1e645` |
| Approve SY | `0x05a48fca9fab4a91f22e40e96e1705b988c633c2dafff71d71f0c5a6a2181048` |
| Tokenize | `0x01744541134c2ccea438ad601d8037019092f4fde4da531eb6e7e230faf55ef5` |

## Maturity Schedule

| Pool | Maturity Date | Status |
|------|---------------|--------|
| PT-xSTRK-JUL26 | July 1, 2026 | Active |

## Security Considerations

- All contracts are immutable after deployment
- Maturity dates are fixed at deployment
- PT/YT supply always equals SY deposited
- No admin keys or upgrade mechanisms

## Comparison with Pendle

| Feature | Pendle (EVM) | StarkYield (Starknet) |
|---------|--------------|----------------------|
| Language | Solidity | Cairo |
| Gas Costs | High | Low |
| Finality | ~12 min | ~2 min |
| Native Token | ETH | STRK |

## License

MIT License

## Links

- [Starknet Explorer](https://starkscan.co/)
- [Documentation](./docs/)
- [Frontend](./frontend/)
