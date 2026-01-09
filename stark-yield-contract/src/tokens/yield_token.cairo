// SPDX-License-Identifier: MIT
// StarkYield - Yield Token (YT)

use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20YT<TContractState> {
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

#[starknet::contract]
pub mod YieldToken {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        Map, StorageMapReadAccess, StorageMapWriteAccess
    };
    use core::num::traits::Zero;

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

        // YT specific storage
        sy_token: ContractAddress,
        pt_token: ContractAddress,
        underlying: ContractAddress,
        maturity: u64,
        tokenizer: ContractAddress,

        // Yield tracking
        yield_index: u256,                              // Global yield index
        user_yield_index: Map<ContractAddress, u256>,   // User's last synced yield index
        accrued_yield: Map<ContractAddress, u256>,      // Accrued but unclaimed yield
        total_claimed: Map<ContractAddress, u256>,      // Total claimed yield
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
        YieldClaimed: YieldClaimed,
        YieldIndexUpdated: YieldIndexUpdated,
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
    pub struct YieldClaimed {
        #[key]
        pub account: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct YieldIndexUpdated {
        pub old_index: u256,
        pub new_index: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        sy_token: ContractAddress,
        underlying: ContractAddress,
        maturity: u64,
        tokenizer: ContractAddress,
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(18);
        self.sy_token.write(sy_token);
        self.underlying.write(underlying);
        self.maturity.write(maturity);
        self.tokenizer.write(tokenizer);
        self.yield_index.write(SCALE); // Start at 1.0
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) {
            assert(!from.is_zero(), 'ERC20: transfer from 0');
            assert(!to.is_zero(), 'ERC20: transfer to 0');

            // Update yield for both parties before transfer
            self._update_user_yield(from);
            self._update_user_yield(to);

            let from_balance = self.balances.read(from);
            assert(from_balance >= amount, 'ERC20: insufficient balance');

            self.balances.write(from, from_balance - amount);
            self.balances.write(to, self.balances.read(to) + amount);

            self.emit(Transfer { from, to, value: amount });
        }

        fn _mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            assert(!to.is_zero(), 'ERC20: mint to 0');

            // Update yield before changing balance
            self._update_user_yield(to);

            self.total_supply.write(self.total_supply.read() + amount);
            self.balances.write(to, self.balances.read(to) + amount);
            self.emit(Transfer { from: Zero::zero(), to, value: amount });
        }

        fn _burn(ref self: ContractState, from: ContractAddress, amount: u256) {
            assert(!from.is_zero(), 'ERC20: burn from 0');

            // Update yield before changing balance
            self._update_user_yield(from);

            let from_balance = self.balances.read(from);
            assert(from_balance >= amount, 'ERC20: insufficient balance');
            self.balances.write(from, from_balance - amount);
            self.total_supply.write(self.total_supply.read() - amount);
            self.emit(Transfer { from, to: Zero::zero(), value: amount });
        }

        fn _update_user_yield(ref self: ContractState, account: ContractAddress) {
            if account.is_zero() {
                return;
            }

            let current_index = self.yield_index.read();
            let user_index = self.user_yield_index.read(account);
            let balance = self.balances.read(account);

            if user_index < current_index && balance > 0 {
                // Calculate accrued yield since last update
                // yield = balance * (current_index - user_index) / SCALE
                let yield_delta = balance * (current_index - user_index) / SCALE;
                let current_accrued = self.accrued_yield.read(account);
                self.accrued_yield.write(account, current_accrued + yield_delta);
            }

            // Update user's index to current
            self.user_yield_index.write(account, current_index);
        }
    }

    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20YT<ContractState> {
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

    // YT Specific Functions
    #[generate_trait]
    #[abi(per_item)]
    impl YTImpl of YTTrait {
        #[external(v0)]
        fn sy_token(self: @ContractState) -> ContractAddress {
            self.sy_token.read()
        }

        #[external(v0)]
        fn pt_token(self: @ContractState) -> ContractAddress {
            self.pt_token.read()
        }

        #[external(v0)]
        fn underlying(self: @ContractState) -> ContractAddress {
            self.underlying.read()
        }

        #[external(v0)]
        fn maturity(self: @ContractState) -> u64 {
            self.maturity.read()
        }

        #[external(v0)]
        fn is_matured(self: @ContractState) -> bool {
            get_block_timestamp() >= self.maturity.read()
        }

        #[external(v0)]
        fn mint(ref self: ContractState, account: ContractAddress, amount: u256) {
            assert(get_caller_address() == self.tokenizer.read(), 'Only tokenizer');
            self._mint(account, amount);
        }

        #[external(v0)]
        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            assert(
                caller == self.tokenizer.read() || caller == account,
                'Unauthorized burn'
            );
            self._burn(account, amount);
        }

        #[external(v0)]
        fn claim_yield(ref self: ContractState, account: ContractAddress) -> u256 {
            // Only the account owner or tokenizer can claim
            let caller = get_caller_address();
            assert(caller == account || caller == self.tokenizer.read(), 'Unauthorized claim');

            // Update yield first
            self._update_user_yield(account);

            let yield_to_claim = self.accrued_yield.read(account);
            if yield_to_claim > 0 {
                self.accrued_yield.write(account, 0);
                let prev_claimed = self.total_claimed.read(account);
                self.total_claimed.write(account, prev_claimed + yield_to_claim);

                // In production, this would transfer SY tokens to the user
                // For now, we just emit the event

                self.emit(YieldClaimed { account, amount: yield_to_claim });
            }

            yield_to_claim
        }

        #[external(v0)]
        fn get_accrued_yield(self: @ContractState, account: ContractAddress) -> u256 {
            let current_index = self.yield_index.read();
            let user_index = self.user_yield_index.read(account);
            let balance = self.balances.read(account);

            let mut total_accrued = self.accrued_yield.read(account);

            if user_index < current_index && balance > 0 {
                let pending = balance * (current_index - user_index) / SCALE;
                total_accrued += pending;
            }

            total_accrued
        }

        #[external(v0)]
        fn yield_index(self: @ContractState) -> u256 {
            self.yield_index.read()
        }

        #[external(v0)]
        fn user_yield_index(self: @ContractState, account: ContractAddress) -> u256 {
            self.user_yield_index.read(account)
        }

        #[external(v0)]
        fn total_claimed(self: @ContractState, account: ContractAddress) -> u256 {
            self.total_claimed.read(account)
        }

        #[external(v0)]
        fn update_yield_index(ref self: ContractState) {
            // This would typically be called by the tokenizer after syncing SY exchange rate
            // For now, we'll calculate based on a fixed APY
            let caller = get_caller_address();
            assert(caller == self.tokenizer.read(), 'Only tokenizer');

            let old_index = self.yield_index.read();
            // In production, this would calculate based on actual SY exchange rate change
            // For demonstration, we increase index by 0.01% per call
            let new_index = old_index + (old_index / 10000);

            self.yield_index.write(new_index);
            self.emit(YieldIndexUpdated { old_index, new_index });
        }
    }

    // Admin function to set PT token address after deployment
    #[generate_trait]
    #[abi(per_item)]
    impl AdminImpl of AdminTrait {
        #[external(v0)]
        fn set_pt_token(ref self: ContractState, pt_token: ContractAddress) {
            assert(get_caller_address() == self.tokenizer.read(), 'Only tokenizer');
            assert(self.pt_token.read().is_zero(), 'PT already set');
            self.pt_token.write(pt_token);
        }

        #[external(v0)]
        fn set_yield_index(ref self: ContractState, new_index: u256) {
            assert(get_caller_address() == self.tokenizer.read(), 'Only tokenizer');
            let old_index = self.yield_index.read();
            self.yield_index.write(new_index);
            self.emit(YieldIndexUpdated { old_index, new_index });
        }
    }
}
