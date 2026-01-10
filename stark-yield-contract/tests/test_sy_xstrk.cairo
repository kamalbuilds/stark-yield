// Comprehensive tests for SYxSTRK (Standardized Yield Token)
use starknet::ContractAddress;

// Import the interface traits
use starkyield::interfaces::i_standardized_yield::{
    IStandardizedYieldDispatcher, IStandardizedYieldDispatcherTrait
};

// snforge imports
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address
};

// Constants
const INITIAL_APY: u256 = 500; // 5% APY in basis points
const SCALE: u256 = 1_000_000_000_000_000_000; // 1e18

// Helper function to deploy SYxSTRK
fn deploy_sy_xstrk() -> (ContractAddress, IStandardizedYieldDispatcher) {
    let contract = declare("SYxSTRK").unwrap().contract_class();

    let underlying: ContractAddress = 0x1111.try_into().unwrap(); // xSTRK address
    let owner: ContractAddress = 0x9999.try_into().unwrap();

    let mut calldata = array![];
    underlying.serialize(ref calldata);
    owner.serialize(ref calldata);
    INITIAL_APY.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = IStandardizedYieldDispatcher { contract_address };

    (contract_address, dispatcher)
}

fn get_owner() -> ContractAddress {
    0x9999.try_into().unwrap()
}

fn get_user() -> ContractAddress {
    0x2222.try_into().unwrap()
}

// ============ Deployment Tests ============

#[test]
fn test_sy_deployment() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();

    // Verify deployment
    assert!(contract_address != 0.try_into().unwrap(), "Deploy failed");

    // Verify underlying
    let underlying = dispatcher.underlying();
    assert!(underlying == 0x1111.try_into().unwrap(), "Wrong underlying");
}

#[test]
fn test_sy_name_and_symbol() {
    let (_, dispatcher) = deploy_sy_xstrk();

    let _name = dispatcher.name();
    let _symbol = dispatcher.symbol();
    let decimals = dispatcher.decimals();

    assert!(decimals == 18, "Decimals should be 18");
}

#[test]
fn test_initial_exchange_rate() {
    let (_, dispatcher) = deploy_sy_xstrk();

    let exchange_rate = dispatcher.exchange_rate();

    // Initial exchange rate should be 1:1 (1e18)
    assert!(exchange_rate == SCALE, "Initial rate should be 1:1");
}

#[test]
fn test_initial_apy() {
    let (_, dispatcher) = deploy_sy_xstrk();

    let apy = dispatcher.get_apy();
    assert!(apy == INITIAL_APY, "APY should be 500 bps");
}

// ============ Preview Functions Tests ============

#[test]
fn test_preview_deposit_at_initial_rate() {
    let (_, dispatcher) = deploy_sy_xstrk();

    let amount: u256 = 1000 * SCALE; // 1000 tokens
    let sy_preview = dispatcher.preview_deposit(amount);

    // At 1:1 rate, should get same amount
    assert!(sy_preview == amount, "Preview should be 1:1 at start");
}

#[test]
fn test_preview_redeem_at_initial_rate() {
    let (_, dispatcher) = deploy_sy_xstrk();

    let amount: u256 = 500 * SCALE; // 500 SY tokens
    let underlying_preview = dispatcher.preview_redeem(amount);

    // At 1:1 rate, should get same amount
    assert!(underlying_preview == amount, "Preview should be 1:1 at start");
}

// ============ Deposit Tests ============

#[test]
fn test_deposit_mints_sy_tokens() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();

    start_cheat_caller_address(contract_address, user);

    let deposit_amount: u256 = 100 * SCALE;
    let sy_received = dispatcher.deposit(user, deposit_amount);

    // Should receive 1:1 at initial rate
    assert!(sy_received == deposit_amount, "Should receive 1:1");

    // Check balance
    let balance = dispatcher.balance_of(user);
    assert!(balance == sy_received, "Balance should match");

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_deposit_updates_total_supply() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();

    start_cheat_caller_address(contract_address, user);

    let initial_supply = dispatcher.total_supply();
    assert!(initial_supply == 0, "Initial supply should be 0");

    let deposit_amount: u256 = 250 * SCALE;
    dispatcher.deposit(user, deposit_amount);

    let new_supply = dispatcher.total_supply();
    assert!(new_supply == deposit_amount, "Supply should increase");

    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be > 0')]
fn test_deposit_fails_with_zero() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();

    start_cheat_caller_address(contract_address, user);
    dispatcher.deposit(user, 0);
}

// ============ Redeem Tests ============

#[test]
fn test_redeem_returns_underlying() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();

    start_cheat_caller_address(contract_address, user);

    // First deposit
    let deposit_amount: u256 = 500 * SCALE;
    dispatcher.deposit(user, deposit_amount);

    // Then redeem
    let redeem_amount: u256 = 200 * SCALE;
    let underlying_received = dispatcher.redeem(user, redeem_amount);

    // At 1:1 rate
    assert!(underlying_received == redeem_amount, "Should get 1:1");

    // Check remaining balance
    let balance = dispatcher.balance_of(user);
    assert!(balance == deposit_amount - redeem_amount, "Wrong balance");

    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be > 0')]
fn test_redeem_fails_with_zero() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();

    start_cheat_caller_address(contract_address, user);
    dispatcher.deposit(user, 100 * SCALE);
    dispatcher.redeem(user, 0);
}

// ============ ERC20 Transfer Tests ============

#[test]
fn test_transfer() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();
    let recipient: ContractAddress = 0x3333.try_into().unwrap();

    start_cheat_caller_address(contract_address, user);

    // Deposit first
    let amount: u256 = 1000 * SCALE;
    dispatcher.deposit(user, amount);

    // Transfer
    let transfer_amount: u256 = 300 * SCALE;
    let success = dispatcher.transfer(recipient, transfer_amount);

    assert!(success, "Transfer should succeed");

    // Check balances
    let user_balance = dispatcher.balance_of(user);
    let recipient_balance = dispatcher.balance_of(recipient);

    assert!(user_balance == amount - transfer_amount, "Wrong sender balance");
    assert!(recipient_balance == transfer_amount, "Wrong recipient balance");

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_approve_and_transfer_from() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();
    let spender: ContractAddress = 0x4444.try_into().unwrap();
    let recipient: ContractAddress = 0x5555.try_into().unwrap();

    // User deposits
    start_cheat_caller_address(contract_address, user);
    let amount: u256 = 500 * SCALE;
    dispatcher.deposit(user, amount);

    // User approves spender
    let approve_amount: u256 = 200 * SCALE;
    dispatcher.approve(spender, approve_amount);

    // Check allowance
    let allowance = dispatcher.allowance(user, spender);
    assert!(allowance == approve_amount, "Wrong allowance");

    stop_cheat_caller_address(contract_address);

    // Spender transfers from user
    start_cheat_caller_address(contract_address, spender);

    let success = dispatcher.transfer_from(user, recipient, approve_amount);
    assert!(success, "Transfer from should succeed");

    // Check balances
    let user_balance = dispatcher.balance_of(user);
    let recipient_balance = dispatcher.balance_of(recipient);

    assert!(user_balance == amount - approve_amount, "Wrong user balance");
    assert!(recipient_balance == approve_amount, "Wrong recipient balance");

    stop_cheat_caller_address(contract_address);
}

// ============ Sync and Exchange Rate Tests ============

#[test]
fn test_sync_does_not_fail() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let owner = get_owner();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.sync(); // Should not panic
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_total_underlying() {
    let (contract_address, dispatcher) = deploy_sy_xstrk();
    let user = get_user();

    start_cheat_caller_address(contract_address, user);

    // Initially zero
    let initial = dispatcher.total_underlying();
    assert!(initial == 0, "Should start at 0");

    // After deposit
    let deposit: u256 = 750 * SCALE;
    dispatcher.deposit(user, deposit);

    let after_deposit = dispatcher.total_underlying();
    assert!(after_deposit == deposit, "Should equal deposit at 1:1 rate");

    stop_cheat_caller_address(contract_address);
}
