// SPDX-License-Identifier: MIT
// StarkYield - Standardized Yield (SY) Interface
// Based on ERC-5115/SNIP-22 for Starknet

use starknet::ContractAddress;

/// @notice Standardized Yield (SY) Token Interface
/// SY tokens wrap yield-bearing assets and provide a standardized interface
/// for yield tokenization protocols
#[starknet::interface]
pub trait IStandardizedYield<TContractState> {
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

    // ============ SY Core Functions ============

    /// @notice Deposit underlying asset to mint SY tokens
    /// @param receiver Address to receive SY tokens
    /// @param amount_underlying Amount of underlying asset to deposit
    /// @return sy_out Amount of SY tokens minted
    fn deposit(
        ref self: TContractState,
        receiver: ContractAddress,
        amount_underlying: u256
    ) -> u256;

    /// @notice Redeem SY tokens for underlying asset
    /// @param receiver Address to receive underlying asset
    /// @param amount_sy Amount of SY tokens to redeem
    /// @return underlying_out Amount of underlying asset received
    fn redeem(
        ref self: TContractState,
        receiver: ContractAddress,
        amount_sy: u256
    ) -> u256;

    /// @notice Get the underlying asset address
    fn underlying(self: @TContractState) -> ContractAddress;

    /// @notice Get exchange rate: 1 SY = X underlying
    /// @dev This should increase over time as yield accrues
    fn exchange_rate(self: @TContractState) -> u256;

    /// @notice Get current APY in basis points (e.g., 500 = 5%)
    fn get_apy(self: @TContractState) -> u256;

    /// @notice Preview deposit: how many SY tokens for given underlying amount
    fn preview_deposit(self: @TContractState, amount_underlying: u256) -> u256;

    /// @notice Preview redeem: how much underlying for given SY amount
    fn preview_redeem(self: @TContractState, amount_sy: u256) -> u256;

    /// @notice Get total underlying asset value held by this SY token
    fn total_underlying(self: @TContractState) -> u256;

    /// @notice Sync exchange rate from underlying yield source
    fn sync(ref self: TContractState);
}
