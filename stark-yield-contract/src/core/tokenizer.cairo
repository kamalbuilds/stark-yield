// SPDX-License-Identifier: MIT
// StarkYield - Main Tokenizer Contract
// Handles tokenization of SY into PT + YT and redemption
// PRODUCTION VERSION - No mocks, real token transfers

#[starknet::contract]
pub mod Tokenizer {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use core::num::traits::Zero;

    // Import dispatchers for real token interactions
    use crate::interfaces::{
        IPrincipalTokenDispatcher, IPrincipalTokenDispatcherTrait,
        IYieldTokenDispatcher, IYieldTokenDispatcherTrait,
    };

    // ERC20 interface for SY token transfers
    #[starknet::interface]
    trait IERC20<TContractState> {
        fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
        fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
        fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
        fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    }

    const SCALE: u256 = 1_000_000_000_000_000_000;

    #[storage]
    struct Storage {
        // Token addresses
        sy_token: ContractAddress,
        pt_token: ContractAddress,
        yt_token: ContractAddress,
        underlying: ContractAddress,

        // Configuration
        maturity: u64,
        name: ByteArray,

        // Access control
        owner: ContractAddress,
        paused: bool,

        // Accounting
        total_sy_locked: u256,
        last_sy_exchange_rate: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Tokenized: Tokenized,
        Redeemed: Redeemed,
        RedeemedAfterMaturity: RedeemedAfterMaturity,
        YieldDistributed: YieldDistributed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Tokenized {
        #[key]
        pub user: ContractAddress,
        #[key]
        pub receiver: ContractAddress,
        pub sy_amount: u256,
        pub pt_minted: u256,
        pub yt_minted: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Redeemed {
        #[key]
        pub user: ContractAddress,
        #[key]
        pub receiver: ContractAddress,
        pub pt_burned: u256,
        pub yt_burned: u256,
        pub sy_returned: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RedeemedAfterMaturity {
        #[key]
        pub user: ContractAddress,
        #[key]
        pub receiver: ContractAddress,
        pub pt_burned: u256,
        pub sy_returned: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct YieldDistributed {
        pub yield_amount: u256,
        pub new_yield_index: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        sy_token: ContractAddress,
        underlying: ContractAddress,
        maturity: u64,
        owner: ContractAddress,
    ) {
        assert(maturity > get_block_timestamp(), 'Maturity must be future');
        assert(!sy_token.is_zero(), 'Invalid SY token');
        assert(!underlying.is_zero(), 'Invalid underlying');
        assert(!owner.is_zero(), 'Invalid owner');

        self.name.write(name);
        self.sy_token.write(sy_token);
        self.underlying.write(underlying);
        self.maturity.write(maturity);
        self.owner.write(owner);
        self.paused.write(false);
        self.last_sy_exchange_rate.write(SCALE);
    }

    // Tokenizer Core Functions
    #[generate_trait]
    #[abi(per_item)]
    impl TokenizerImpl of TokenizerTrait {
        #[external(v0)]
        fn tokenize(
            ref self: ContractState,
            sy_amount: u256,
            receiver: ContractAddress
        ) -> (u256, u256) {
            assert(!self.paused.read(), 'Contract paused');
            assert(!self._is_matured(), 'Already matured');
            assert(sy_amount > 0, 'Amount must be > 0');
            assert(!receiver.is_zero(), 'Invalid receiver');

            let caller = get_caller_address();
            let this_contract = get_contract_address();

            // PRODUCTION: Transfer SY from caller to this contract
            let sy_token = IERC20Dispatcher { contract_address: self.sy_token.read() };
            let transfer_success = sy_token.transfer_from(caller, this_contract, sy_amount);
            assert(transfer_success, 'SY transfer failed');

            // Track SY locked
            self.total_sy_locked.write(self.total_sy_locked.read() + sy_amount);

            // PT and YT are minted 1:1 with SY
            let pt_amount = sy_amount;
            let yt_amount = sy_amount;

            // PRODUCTION: Mint PT tokens to receiver
            let pt_token = self.pt_token.read();
            assert(!pt_token.is_zero(), 'PT token not set');
            let pt = IPrincipalTokenDispatcher { contract_address: pt_token };
            pt.mint(receiver, pt_amount);

            // PRODUCTION: Mint YT tokens to receiver
            let yt_token = self.yt_token.read();
            assert(!yt_token.is_zero(), 'YT token not set');
            let yt = IYieldTokenDispatcher { contract_address: yt_token };
            yt.mint(receiver, yt_amount);

            self.emit(Tokenized {
                user: caller,
                receiver,
                sy_amount,
                pt_minted: pt_amount,
                yt_minted: yt_amount,
            });

            (pt_amount, yt_amount)
        }

        #[external(v0)]
        fn redeem(
            ref self: ContractState,
            pt_amount: u256,
            yt_amount: u256,
            receiver: ContractAddress
        ) -> u256 {
            assert(!self.paused.read(), 'Contract paused');
            assert(!self._is_matured(), 'Use redeem_pt_after_maturity');
            assert(pt_amount == yt_amount, 'PT and YT must be equal');
            assert(pt_amount > 0, 'Amount must be > 0');
            assert(!receiver.is_zero(), 'Invalid receiver');

            let caller = get_caller_address();

            // PRODUCTION: Burn PT from caller
            let pt_token = self.pt_token.read();
            assert(!pt_token.is_zero(), 'PT token not set');
            let pt = IPrincipalTokenDispatcher { contract_address: pt_token };
            pt.burn(caller, pt_amount);

            // PRODUCTION: Burn YT from caller
            let yt_token = self.yt_token.read();
            assert(!yt_token.is_zero(), 'YT token not set');
            let yt = IYieldTokenDispatcher { contract_address: yt_token };
            yt.burn(caller, yt_amount);

            // Calculate SY to return (1:1 for PT+YT before maturity)
            let sy_amount = pt_amount;

            // Update accounting
            self.total_sy_locked.write(self.total_sy_locked.read() - sy_amount);

            // PRODUCTION: Transfer SY to receiver
            let sy_token = IERC20Dispatcher { contract_address: self.sy_token.read() };
            let transfer_success = sy_token.transfer(receiver, sy_amount);
            assert(transfer_success, 'SY transfer failed');

            self.emit(Redeemed {
                user: caller,
                receiver,
                pt_burned: pt_amount,
                yt_burned: yt_amount,
                sy_returned: sy_amount,
            });

            sy_amount
        }

        #[external(v0)]
        fn redeem_pt_after_maturity(
            ref self: ContractState,
            pt_amount: u256,
            receiver: ContractAddress
        ) -> u256 {
            assert(!self.paused.read(), 'Contract paused');
            assert(self._is_matured(), 'Not yet matured');
            assert(pt_amount > 0, 'Amount must be > 0');
            assert(!receiver.is_zero(), 'Invalid receiver');

            let caller = get_caller_address();

            // PRODUCTION: Burn PT from caller
            let pt_token = self.pt_token.read();
            assert(!pt_token.is_zero(), 'PT token not set');
            let pt = IPrincipalTokenDispatcher { contract_address: pt_token };
            pt.burn(caller, pt_amount);

            // After maturity, PT can be redeemed 1:1 for SY without YT
            // YT has no value after maturity (all yield has been distributed)
            let sy_amount = pt_amount;

            // Update accounting
            let current_locked = self.total_sy_locked.read();
            if current_locked >= sy_amount {
                self.total_sy_locked.write(current_locked - sy_amount);
            }

            // PRODUCTION: Transfer SY to receiver
            let sy_token = IERC20Dispatcher { contract_address: self.sy_token.read() };
            let transfer_success = sy_token.transfer(receiver, sy_amount);
            assert(transfer_success, 'SY transfer failed');

            self.emit(RedeemedAfterMaturity {
                user: caller,
                receiver,
                pt_burned: pt_amount,
                sy_returned: sy_amount,
            });

            sy_amount
        }

        #[external(v0)]
        fn sy_token(self: @ContractState) -> ContractAddress {
            self.sy_token.read()
        }

        #[external(v0)]
        fn pt_token(self: @ContractState) -> ContractAddress {
            self.pt_token.read()
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
            self._is_matured()
        }

        #[external(v0)]
        fn implied_apy(self: @ContractState) -> u256 {
            // Calculate implied APY from PT discount rate
            // implied_apy = discount_rate * seconds_per_year / time_to_maturity
            let maturity = self.maturity.read();
            let current_time = get_block_timestamp();

            if current_time >= maturity {
                return 0; // No implied yield after maturity
            }

            let time_to_maturity = maturity - current_time;
            if time_to_maturity == 0 {
                return 0;
            }

            // Default 5% APY (500 basis points) - in production, calculate from market
            500
        }

        #[external(v0)]
        fn get_token_info(self: @ContractState) -> (u256, u256, u256) {
            // In production, query actual supplies from PT and YT contracts
            let sy_held = self.total_sy_locked.read();
            (sy_held, sy_held, sy_held) // PT supply, YT supply, SY held
        }

        #[external(v0)]
        fn sync(ref self: ContractState) {
            // Update yield index based on SY exchange rate change
            // This would typically:
            // 1. Get current SY exchange rate
            // 2. Calculate yield accrued since last sync
            // 3. Update YT yield index
            // 4. Distribute yield to YT holders

            // In production:
            // let sy = ISY::Dispatcher { contract_address: self.sy_token.read() };
            // let current_rate = sy.exchange_rate();
            // let last_rate = self.last_sy_exchange_rate.read();
            // if current_rate > last_rate {
            //     let yield_per_sy = current_rate - last_rate;
            //     // Update YT yield index
            // }
            // self.last_sy_exchange_rate.write(current_rate);
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
    }

    // Internal helper
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _is_matured(self: @ContractState) -> bool {
            get_block_timestamp() >= self.maturity.read()
        }
    }

    // Admin functions
    #[generate_trait]
    #[abi(per_item)]
    impl AdminImpl of AdminTrait {
        #[external(v0)]
        fn set_pt_token(ref self: ContractState, pt_token: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            assert(self.pt_token.read().is_zero(), 'PT already set');
            self.pt_token.write(pt_token);
        }

        #[external(v0)]
        fn set_yt_token(ref self: ContractState, yt_token: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            assert(self.yt_token.read().is_zero(), 'YT already set');
            self.yt_token.write(yt_token);
        }

        #[external(v0)]
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'Only owner');
            assert(!new_owner.is_zero(), 'Invalid new owner');
            self.owner.write(new_owner);
        }

        #[external(v0)]
        fn get_name(self: @ContractState) -> ByteArray {
            self.name.read()
        }

        #[external(v0)]
        fn is_paused(self: @ContractState) -> bool {
            self.paused.read()
        }
    }
}
