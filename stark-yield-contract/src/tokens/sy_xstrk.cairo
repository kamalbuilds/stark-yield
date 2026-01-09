// SPDX-License-Identifier: MIT
// StarkYield - Standardized Yield Token for xSTRK (staked STRK)
// PRODUCTION VERSION - Real token transfers using dispatchers
// xSTRK mainnet address: 0x028d709c875C0CEAc3dCE7065beC5328186Dc89FE254527084D1689910954B0a

use starknet::ContractAddress;

// Interface for the SY token itself
#[starknet::interface]
pub trait IERC20<TContractState> {
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
}

// Interface for interacting with external ERC20 tokens (xSTRK)
#[starknet::interface]
pub trait IExternalERC20<TContractState> {
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
}

#[starknet::contract]
pub mod SYxSTRK {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        Map, StorageMapReadAccess, StorageMapWriteAccess
    };
    use core::num::traits::Zero;
    use super::{IExternalERC20Dispatcher, IExternalERC20DispatcherTrait};

    // Scale factor for calculations (18 decimals)
    const SCALE: u256 = 1_000_000_000_000_000_000;

    #[storage]
    struct Storage {
        // ERC20 storage
        name: ByteArray,
        symbol: ByteArray,
        decimals: u8,
        total_supply: u256,
        balances: Map<ContractAddress, u256>,
        allowances: Map<(ContractAddress, ContractAddress), u256>,

        // SY specific storage
        underlying_token: ContractAddress,  // xSTRK token address
        exchange_rate: u256,                // Current exchange rate (scaled by SCALE)
        last_sync_time: u64,                // Last time exchange rate was synced
        apy_basis_points: u256,             // Current APY in basis points (500 = 5%)

        // Access control
        owner: ContractAddress,
        paused: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
        Deposit: Deposit,
        Redeem: Redeem,
        ExchangeRateUpdated: ExchangeRateUpdated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Transfer {
        #[key]
        pub from: ContractAddress,
        #[key]
        pub to: ContractAddress,
        pub value: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Approval {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub spender: ContractAddress,
        pub value: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Deposit {
        #[key]
        pub depositor: ContractAddress,
        #[key]
        pub receiver: ContractAddress,
        pub underlying_amount: u256,
        pub sy_minted: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Redeem {
        #[key]
        pub redeemer: ContractAddress,
        #[key]
        pub receiver: ContractAddress,
        pub sy_burned: u256,
        pub underlying_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ExchangeRateUpdated {
        pub old_rate: u256,
        pub new_rate: u256,
        pub timestamp: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        underlying_token: ContractAddress,
        owner: ContractAddress,
        initial_apy_bps: u256,
    ) {
        self.name.write("SY-xSTRK");
        self.symbol.write("SY-xSTRK");
        self.decimals.write(18);
        self.underlying_token.write(underlying_token);
        self.exchange_rate.write(SCALE); // Start at 1:1
        self.last_sync_time.write(get_block_timestamp());
        self.apy_basis_points.write(initial_apy_bps);
        self.owner.write(owner);
        self.paused.write(false);
    }

    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> ByteArray {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            let current_allowance = self.allowances.read((sender, caller));
            assert(current_allowance >= amount, 'ERC20: insufficient allowance');
            self.allowances.write((sender, caller), current_allowance - amount);
            self._transfer(sender, recipient, amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let owner = get_caller_address();
            self.allowances.write((owner, spender), amount);
            self.emit(Approval { owner, spender, value: amount });
            true
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) {
            assert(!from.is_zero(), 'ERC20: transfer from 0');
            assert(!to.is_zero(), 'ERC20: transfer to 0');

            let from_balance = self.balances.read(from);
            assert(from_balance >= amount, 'ERC20: insufficient balance');

            self.balances.write(from, from_balance - amount);
            self.balances.write(to, self.balances.read(to) + amount);

            self.emit(Transfer { from, to, value: amount });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            assert(!to.is_zero(), 'ERC20: mint to 0');
            self.total_supply.write(self.total_supply.read() + amount);
            self.balances.write(to, self.balances.read(to) + amount);
            self.emit(Transfer { from: Zero::zero(), to, value: amount });
        }

        fn _burn(ref self: ContractState, from: ContractAddress, amount: u256) {
            assert(!from.is_zero(), 'ERC20: burn from 0');
            let from_balance = self.balances.read(from);
            assert(from_balance >= amount, 'ERC20: insufficient balance');
            self.balances.write(from, from_balance - amount);
            self.total_supply.write(self.total_supply.read() - amount);
            self.emit(Transfer { from, to: Zero::zero(), value: amount });
        }

        fn _update_exchange_rate(ref self: ContractState) {
            let current_time = get_block_timestamp();
            let last_time = self.last_sync_time.read();

            if current_time > last_time {
                let time_elapsed = current_time - last_time;
                let old_rate = self.exchange_rate.read();
                let apy_bps = self.apy_basis_points.read();

                // Calculate yield accrued: rate * (1 + APY * time_elapsed / seconds_per_year)
                // APY is in basis points, so divide by 10000
                // Seconds per year ~= 31536000
                let yield_factor = (apy_bps * time_elapsed.into() * SCALE) / (10000 * 31536000);
                let new_rate = old_rate + (old_rate * yield_factor / SCALE);

                self.exchange_rate.write(new_rate);
                self.last_sync_time.write(current_time);

                self.emit(ExchangeRateUpdated { old_rate, new_rate, timestamp: current_time });
            }
        }
    }

    // SY-specific implementations
    #[generate_trait]
    #[abi(per_item)]
    impl SYImpl of SYTrait {
        #[external(v0)]
        fn deposit(
            ref self: ContractState,
            receiver: ContractAddress,
            amount_underlying: u256
        ) -> u256 {
            assert(!self.paused.read(), 'Contract paused');
            assert(amount_underlying > 0, 'Amount must be > 0');
            assert(!receiver.is_zero(), 'Invalid receiver');
            let caller = get_caller_address();
            let this_contract = get_contract_address();

            // Update exchange rate first
            self._update_exchange_rate();

            // Calculate SY to mint based on exchange rate
            let exchange_rate = self.exchange_rate.read();
            let sy_amount = (amount_underlying * SCALE) / exchange_rate;

            // PRODUCTION: Transfer xSTRK from caller to this contract
            let underlying = IExternalERC20Dispatcher { contract_address: self.underlying_token.read() };
            let transfer_success = underlying.transfer_from(caller, this_contract, amount_underlying);
            assert(transfer_success, 'xSTRK transfer failed');

            // Mint SY tokens to receiver
            self._mint(receiver, sy_amount);

            self.emit(Deposit {
                depositor: caller,
                receiver,
                underlying_amount: amount_underlying,
                sy_minted: sy_amount,
            });

            sy_amount
        }

        #[external(v0)]
        fn redeem(
            ref self: ContractState,
            receiver: ContractAddress,
            amount_sy: u256
        ) -> u256 {
            assert(!self.paused.read(), 'Contract paused');
            assert(amount_sy > 0, 'Amount must be > 0');
            assert(!receiver.is_zero(), 'Invalid receiver');
            let caller = get_caller_address();

            // Update exchange rate first
            self._update_exchange_rate();

            // Calculate underlying to return based on exchange rate
            let exchange_rate = self.exchange_rate.read();
            let underlying_amount = (amount_sy * exchange_rate) / SCALE;

            // Burn SY tokens from caller
            self._burn(caller, amount_sy);

            // PRODUCTION: Transfer xSTRK to receiver
            let underlying = IExternalERC20Dispatcher { contract_address: self.underlying_token.read() };
            let transfer_success = underlying.transfer(receiver, underlying_amount);
            assert(transfer_success, 'xSTRK transfer failed');

            self.emit(Redeem {
                redeemer: caller,
                receiver,
                sy_burned: amount_sy,
                underlying_amount,
            });

            underlying_amount
        }

        #[external(v0)]
        fn underlying(self: @ContractState) -> ContractAddress {
            self.underlying_token.read()
        }

        #[external(v0)]
        fn exchange_rate(self: @ContractState) -> u256 {
            self.exchange_rate.read()
        }

        #[external(v0)]
        fn get_apy(self: @ContractState) -> u256 {
            self.apy_basis_points.read()
        }

        #[external(v0)]
        fn preview_deposit(self: @ContractState, amount_underlying: u256) -> u256 {
            let ex_rate = self.exchange_rate.read();
            (amount_underlying * SCALE) / ex_rate
        }

        #[external(v0)]
        fn preview_redeem(self: @ContractState, amount_sy: u256) -> u256 {
            let ex_rate = self.exchange_rate.read();
            (amount_sy * ex_rate) / SCALE
        }

        #[external(v0)]
        fn total_underlying(self: @ContractState) -> u256 {
            let total_sy = self.total_supply.read();
            let ex_rate = self.exchange_rate.read();
            (total_sy * ex_rate) / SCALE
        }

        #[external(v0)]
        fn sync(ref self: ContractState) {
            self._update_exchange_rate();
        }
    }

    // Admin functions
    #[generate_trait]
    #[abi(per_item)]
    impl AdminImpl of AdminTrait {
        #[external(v0)]
        fn set_apy(ref self: ContractState, new_apy_bps: u256) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            self._update_exchange_rate();
            self.apy_basis_points.write(new_apy_bps);
        }

        #[external(v0)]
        fn pause(ref self: ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            self.paused.write(true);
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            self.paused.write(false);
        }

        #[external(v0)]
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            assert(!new_owner.is_zero(), 'Invalid new owner');
            self.owner.write(new_owner);
        }
    }
}
