// SPDX-License-Identifier: MIT
// StarkYield - Tokenizer Interface

use starknet::ContractAddress;

/// @notice Tokenizer Interface
/// The Tokenizer is the main contract that handles:
/// - Tokenization: Split SY into PT + YT
/// - Redemption: Burn PT + YT to get SY back
/// - After maturity: PT redeemable 1:1 for SY
#[starknet::interface]
pub trait ITokenizer<TContractState> {
    // ============ Core Tokenization Functions ============

    /// @notice Tokenize SY into PT and YT
    /// @dev Burns SY from caller and mints equal amounts of PT and YT
    /// @param sy_amount Amount of SY to tokenize
    /// @param receiver Address to receive PT and YT
    /// @return pt_amount Amount of PT minted (equal to sy_amount)
    /// @return yt_amount Amount of YT minted (equal to sy_amount)
    fn tokenize(
        ref self: TContractState,
        sy_amount: u256,
        receiver: ContractAddress
    ) -> (u256, u256);

    /// @notice Redeem PT and YT back to SY (before maturity)
    /// @dev Burns equal amounts of PT and YT, mints SY
    /// @param pt_amount Amount of PT to redeem
    /// @param yt_amount Amount of YT to redeem (must equal pt_amount)
    /// @param receiver Address to receive SY
    /// @return sy_amount Amount of SY minted
    fn redeem(
        ref self: TContractState,
        pt_amount: u256,
        yt_amount: u256,
        receiver: ContractAddress
    ) -> u256;

    /// @notice Redeem PT after maturity
    /// @dev After maturity, PT can be redeemed 1:1 for SY without YT
    /// @param pt_amount Amount of PT to redeem
    /// @param receiver Address to receive SY
    /// @return sy_amount Amount of SY received
    fn redeem_pt_after_maturity(
        ref self: TContractState,
        pt_amount: u256,
        receiver: ContractAddress
    ) -> u256;

    // ============ View Functions ============

    /// @notice Get SY token address
    fn sy_token(self: @TContractState) -> ContractAddress;

    /// @notice Get PT token address
    fn pt_token(self: @TContractState) -> ContractAddress;

    /// @notice Get YT token address
    fn yt_token(self: @TContractState) -> ContractAddress;

    /// @notice Get underlying asset address
    fn underlying(self: @TContractState) -> ContractAddress;

    /// @notice Get maturity timestamp
    fn maturity(self: @TContractState) -> u64;

    /// @notice Check if matured
    fn is_matured(self: @TContractState) -> bool;

    /// @notice Get implied APY based on PT discount
    fn implied_apy(self: @TContractState) -> u256;

    /// @notice Get PT/YT supply ratio info
    fn get_token_info(self: @TContractState) -> (u256, u256, u256); // (pt_supply, yt_supply, sy_held)

    // ============ Admin Functions ============

    /// @notice Update yield accounting
    fn sync(ref self: TContractState);

    /// @notice Emergency pause
    fn pause(ref self: TContractState);

    /// @notice Unpause
    fn unpause(ref self: TContractState);
}
