// SPDX-License-Identifier: MIT
// StarkYield - Principal Token (PT)

use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20PT<TContractState> {
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
pub mod PrincipalToken {
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

        // PT specific storage
        sy_token: ContractAddress,
        yt_token: ContractAddress,
        underlying: ContractAddress,
        maturity: u64,
        tokenizer: ContractAddress, // Only tokenizer can mint/burn
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
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
    }

    #[abi(embed_v0)]
    impl ERC20Impl of super::IERC20PT<ContractState> {
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

    // PT Specific Functions
    #[generate_trait]
    #[abi(per_item)]
    impl PTImpl of PTTrait {
        #[external(v0)]
        fn sy_token(self: @ContractState) -> ContractAddress {
            self.sy_token.read()
        }

        #[external(v0)]
        fn yt_token(self: @ContractState) -> ContractAddress {
            self.yt_token.read()
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
            // Allow tokenizer or the account owner to burn
            assert(
                caller == self.tokenizer.read() || caller == account,
                'Unauthorized burn'
            );
            self._burn(account, amount);
        }

        #[external(v0)]
        fn pt_exchange_rate(self: @ContractState) -> u256 {
            // After maturity, PT is redeemable 1:1 for SY
            SCALE
        }

        #[external(v0)]
        fn discount_rate(self: @ContractState) -> u256 {
            // This would typically be calculated based on market price
            // For now, return a placeholder
            if get_block_timestamp() >= self.maturity.read() {
                0 // No discount after maturity
            } else {
                // Calculate based on time to maturity and implied yield
                let ttm = self.time_to_maturity();
                // Simplified: 5% annualized discount
                (500 * ttm.into() * SCALE) / (10000 * 31536000)
            }
        }

        #[external(v0)]
        fn time_to_maturity(self: @ContractState) -> u64 {
            let current_time = get_block_timestamp();
            let mat = self.maturity.read();
            if current_time >= mat {
                0
            } else {
                mat - current_time
            }
        }
    }

    // Admin function to set YT token address after deployment
    #[generate_trait]
    #[abi(per_item)]
    impl AdminImpl of AdminTrait {
        #[external(v0)]
        fn set_yt_token(ref self: ContractState, yt_token: ContractAddress) {
            assert(get_caller_address() == self.tokenizer.read(), 'Only tokenizer');
            assert(self.yt_token.read().is_zero(), 'YT already set');
            self.yt_token.write(yt_token);
        }
    }
}
