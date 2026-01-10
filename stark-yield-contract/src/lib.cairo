// StarkYield - Pendle-like Yield Tokenization Protocol for Starknet
//
// This protocol enables tokenization of yield-bearing assets into:
// - PT (Principal Token): Represents the principal, redeemable 1:1 after maturity
// - YT (Yield Token): Represents future yield entitlement until maturity
//
// Architecture:
// - SY (Standardized Yield): Wraps yield-bearing assets with standard interface
// - Tokenizer: Splits SY into PT + YT, handles redemption
//
// Supported Assets (Phase 1):
// - xSTRK (staked STRK from Endur.fi, Nimbora, or Starknet staking)

pub mod interfaces;
pub mod tokens;
pub mod core;

// Re-export main components
pub use interfaces::{
    IStandardizedYield, IStandardizedYieldDispatcher, IStandardizedYieldDispatcherTrait,
    IPrincipalToken, IPrincipalTokenDispatcher, IPrincipalTokenDispatcherTrait,
    IYieldToken, IYieldTokenDispatcher, IYieldTokenDispatcherTrait,
    ITokenizer, ITokenizerDispatcher, ITokenizerDispatcherTrait,
};

pub use tokens::sy_xstrk::SYxSTRK;
pub use tokens::principal_token::PrincipalToken;
pub use tokens::yield_token::YieldToken;
pub use core::tokenizer::Tokenizer;
