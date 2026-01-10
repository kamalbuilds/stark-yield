// SPDX-License-Identifier: MIT
// StarkYield - Principal Token (PT) Interface

use starknet::ContractAddress;

/// @notice Principal Token (PT) Interface
/// PT tokens represent the principal portion of a yield-bearing asset
/// Can be redeemed 1:1 for underlying asset after maturity
#[starknet::interface]
pub trait IPrincipalToken<TContractState> {
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

    // ============ PT Specific Functions ============

    /// @notice Get associated SY token address
    fn sy_token(self: @TContractState) -> ContractAddress;

    /// @notice Get associated YT token address
    fn yt_token(self: @TContractState) -> ContractAddress;

    /// @notice Get the underlying asset address
    fn underlying(self: @TContractState) -> ContractAddress;

    /// @notice Get maturity timestamp
    fn maturity(self: @TContractState) -> u64;

    /// @notice Check if matured
    fn is_matured(self: @TContractState) -> bool;

    /// @notice Mint PT tokens (only callable by tokenizer)
    /// @param account Address to mint to
    /// @param amount Amount of PT tokens to mint
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256);

    /// @notice Burn PT tokens (only callable by tokenizer or owner)
    /// @param account Address to burn from
    /// @param amount Amount of PT tokens to burn
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256);

    /// @notice Get exchange rate for PT after maturity (always 1:1)
    fn exchange_rate(self: @TContractState) -> u256;

    /// @notice Get discount rate based on implied yield until maturity
    fn discount_rate(self: @TContractState) -> u256;

    /// @notice Get time remaining until maturity in seconds
    fn time_to_maturity(self: @TContractState) -> u64;
}
