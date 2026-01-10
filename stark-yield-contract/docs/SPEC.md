 StarkYield - Tokenized Interest Rates Protocol
 Specification Document

Bounty Overview
Prize: $8,000 STRK
Category: DeFi - Yield Tokenization
Platform: Starknet (Cairo)

---

 1. Protocol Summary

StarkYield is a Pendle-like yield tokenization protocol on Starknet that splits yield-bearing assets into two components:
- PT (Principal Token): Represents the principal value redeemable at maturity
- YT (Yield Token): Represents the right to yield until maturity

Core Value Proposition
- Fixed yield exposure through PT
- Leveraged yield exposure through YT
- Yield trading and speculation markets
- Capital efficiency through yield stripping

---

 2. Technical Architecture

2.1 Smart Contract Structure

```
stark-yield/
├── src/
│   ├── lib.cairo                     Module declarations
│   ├── core/
│   │   └── tokenizer.cairo           Main PT/YT minting & redemption
│   ├── tokens/
│   │   ├── sy_xstrk.cairo            Standardized Yield wrapper for xSTRK
│   │   ├── principal_token.cairo     PT ERC20 implementation
│   │   └── yield_token.cairo         YT ERC20 implementation
│   └── interfaces/
│       ├── i_tokenizer.cairo         ITokenizer interface
│       └── i_standardized_yield.cairo  ISY interface
└── tests/
    ├── lib.cairo
    ├── test_tokenizer.cairo          20+ Tokenizer tests
    └── test_sy_xstrk.cairo           15+ SY tests
```

2.2 Contract Specifications

SYxSTRK (Standardized Yield Token)
- Purpose: Wrap xSTRK (staked STRK) into a standardized yield interface
- Key Functions:
  - `deposit(receiver, amount_underlying) -> sy_amount`
  - `redeem(receiver, amount_sy) -> underlying_amount`
  - `exchange_rate() -> u256` (current conversion rate)
  - `get_apy() -> u256` (APY in basis points)
  - `preview_deposit/preview_redeem` (view functions)
- Exchange Rate: Automatically accrues based on APY over time
- Scale Factor: 1e18 for precision

Tokenizer (PT/YT Minting)
- Purpose: Split SY tokens into PT and YT
- Key Functions:
  - `tokenize(sy_amount, receiver) -> (pt_amount, yt_amount)`
  - `redeem(pt_amount, yt_amount, receiver) -> sy_amount` (before maturity)
  - `redeem_pt_after_maturity(pt_amount, receiver) -> sy_amount`
- Maturity: Fixed timestamp after which PT can be redeemed 1:1
- Yield Tracking: `implied_apy()` returns current yield rate

Principal Token (PT)
- Standard ERC20 with mintable/burnable by Tokenizer
- Represents principal value at maturity
- Tradeable before maturity at discount

Yield Token (YT)
- Standard ERC20 with mintable/burnable by Tokenizer
- Represents yield rights until maturity
- Value approaches 0 at maturity

---

 3. Protocol Mechanics

3.1 Tokenization Flow

```
User deposits xSTRK
        │
        ▼
  SYxSTRK minted (1:1 at start, accrues yield)
        │
        ▼
  Tokenizer.tokenize()
        │
        ├──► PT minted (1:1 to SY)
        │
        └──► YT minted (1:1 to SY)
```

3.2 Redemption Flows

Before Maturity:
```
User burns PT + YT (equal amounts)
        │
        ▼
  Tokenizer returns SY tokens
        │
        ▼
  User redeems SY for xSTRK (with accrued yield)
```

After Maturity:
```
User burns PT only
        │
        ▼
  Tokenizer returns SY tokens 1:1
        │
        ▼
  User redeems SY for xSTRK
```

3.3 Exchange Rate Calculation

```cairo
// Time-weighted APY accrual
yield_factor = (apy_bps * time_elapsed * SCALE) / (10000 * 31536000)
new_rate = old_rate + (old_rate * yield_factor / SCALE)
```

---

 4. Security Considerations

4.1 Access Control
- Owner-only functions: `set_apy`, `pause`, `unpause`, `transfer_ownership`
- Tokenizer-only minting for PT/YT tokens
- Pausable for emergency stops

4.2 Validation
- Zero amount checks on all deposit/redeem functions
- Maturity state checks (pre/post maturity logic)
- Balance/allowance validation

4.3 Arithmetic Safety
- Cairo's native overflow protection
- Scale factor (1e18) for precision
- Integer division ordering for minimal precision loss

---

 5. Integration Points

5.1 Underlying Asset: xSTRK
- Staked STRK from Starknet native staking
- Existing yield-bearing token
- Address: TBD (mainnet deployment)

5.2 Frontend Requirements
- Connect wallet (Starknet wallets via starknet-react)
- Deposit xSTRK → Get SY
- Tokenize SY → Get PT + YT
- Redeem PT/YT → Get SY
- Withdraw SY → Get xSTRK

---

 6. Test Coverage (35 tests, 100% passing)

Tokenizer Tests (20 tests)
- Deployment and initial state
- Maturity detection (before, at, after)
- Tokenization (PT/YT equality, zero amount, paused state)
- Redemption (before/after maturity, unequal amounts)
- Admin functions (pause, unpause, ownership)

SYxSTRK Tests (15 tests)
- ERC20 functionality (transfer, approve, transferFrom)
- Deposit/redeem mechanics
- Exchange rate calculations
- Preview functions
- Zero amount validation

---

 7. Deployment Plan

1. Testnet (Sepolia)
   - Deploy SYxSTRK with mock xSTRK
   - Deploy PT and YT token contracts
   - Deploy Tokenizer with test maturity date
   - Verify all functions via tests

2. Mainnet
   - Deploy SYxSTRK pointing to real xSTRK
   - Deploy production PT/YT tokens
   - Deploy Tokenizer with real maturity (e.g., Mar 2025)
   - Transfer ownership to multisig

---

 8. Dependencies

- Scarb 2.14.0
- Cairo 2.14.0
- snforge (Starknet Foundry)
- OpenZeppelin Cairo Contracts v1.0.0

---

 9. Future Enhancements

- AMM for PT/YT trading
- Multiple maturity dates
- Additional yield sources (LST variants)
- Governance token integration
- Fee mechanisms
