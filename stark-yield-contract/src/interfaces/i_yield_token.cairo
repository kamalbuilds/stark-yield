// SPDX-License-Identifier: MIT
// StarkYield - Yield Token (YT) Interface

use starknet::ContractAddress;

/// @notice Yield Token (YT) Interface
/// YT tokens represent the future yield entitlement from a yield-bearing asset
/// YT holders receive the yield generated until maturity
#[starknet::interface]
pub trait IYieldToken<TContractState> {
    // ============ ERC20 Functions ============
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState,
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    // ============ YT Specific Functions ============

    /// @notice Get associated SY token address
    fn sy_token(self: @TContractState) -> ContractAddress;

    /// @notice Get associated PT token address
    fn pt_token(self: @TContractState) -> ContractAddress;

    /// @notice Get the underlying asset address
    fn underlying(self: @TContractState) -> ContractAddress;

    /// @notice Get maturity timestamp
    fn maturity(self: @TContractState) -> u64;

    /// @notice Check if matured
    fn is_matured(self: @TContractState) -> bool;

    /// @notice Mint YT tokens (only callable by tokenizer)
    /// @param account Address to mint to
    /// @param amount Amount of YT tokens to mint
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256);

    /// @notice Burn YT tokens (only callable by tokenizer or owner)
    /// @param account Address to burn from
    /// @param amount Amount of YT tokens to burn
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256);

    /// @notice Claim accrued yield for user
    /// @param account Address to claim yield for
    /// @return yield_claimed Amount of yield claimed in underlying
    fn claim_yield(ref self: TContractState, account: ContractAddress) -> u256;

    /// @notice Get accrued but unclaimed yield for user
    /// @param account Address to check
    /// @return accrued_yield Amount of accrued yield
    fn accrued_yield(self: @TContractState, account: ContractAddress) -> u256;

    /// @notice Get current yield index (tracks total yield per YT)
    fn yield_index(self: @TContractState) -> u256;

    /// @notice Get user's last updated yield index
    fn user_yield_index(self: @TContractState, account: ContractAddress) -> u256;

    /// @notice Get total yield claimed by user
    fn total_claimed(self: @TContractState, account: ContractAddress) -> u256;

    /// @notice Update yield index based on SY exchange rate change
    fn update_yield_index(ref self: TContractState);
}
