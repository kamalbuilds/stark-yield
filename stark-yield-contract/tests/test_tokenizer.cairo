// Comprehensive tests for Tokenizer Contract
use starknet::ContractAddress;

// Import the interface traits - get dispatcher from the interface location
use starkyield::interfaces::i_tokenizer::{ITokenizerDispatcher, ITokenizerDispatcherTrait};

// snforge imports
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
    start_cheat_block_timestamp, stop_cheat_block_timestamp
};

// Constants for testing
const MATURITY_TIMESTAMP: u64 = 1743465600; // March 31, 2025
const BEFORE_MATURITY: u64 = 1700000000; // Nov 2023
const AFTER_MATURITY: u64 = 1750000000; // After March 2025

// Helper function to deploy the tokenizer contract
fn deploy_tokenizer() -> (ContractAddress, ITokenizerDispatcher) {
    let contract = declare("Tokenizer").unwrap().contract_class();

    let name: ByteArray = "SY-xSTRK-MAR2025";
    let sy_token: ContractAddress = 0x1234.try_into().unwrap();
    let underlying: ContractAddress = 0x5678.try_into().unwrap();
    let owner: ContractAddress = 0x9999.try_into().unwrap();

    let mut calldata = array![];
    name.serialize(ref calldata);
    sy_token.serialize(ref calldata);
    underlying.serialize(ref calldata);
    MATURITY_TIMESTAMP.serialize(ref calldata);
    owner.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let dispatcher = ITokenizerDispatcher { contract_address };

    (contract_address, dispatcher)
}

fn get_owner() -> ContractAddress {
    0x9999.try_into().unwrap()
}

fn get_user() -> ContractAddress {
    0x1111.try_into().unwrap()
}

// ============ Deployment Tests ============

#[test]
fn test_tokenizer_deployment() {
    let (contract_address, dispatcher) = deploy_tokenizer();

    // Verify contract was deployed
    assert!(contract_address != 0.try_into().unwrap(), "Deploy failed");

    // Verify initial state
    let sy_token = dispatcher.sy_token();
    assert!(sy_token == 0x1234.try_into().unwrap(), "Wrong SY token");

    let underlying = dispatcher.underlying();
    assert!(underlying == 0x5678.try_into().unwrap(), "Wrong underlying");

    let maturity = dispatcher.maturity();
    assert!(maturity == MATURITY_TIMESTAMP, "Wrong maturity");
}

#[test]
fn test_initial_token_info() {
    let (_, dispatcher) = deploy_tokenizer();

    let (pt_supply, yt_supply, sy_held) = dispatcher.get_token_info();

    // Initially all should be zero
    assert!(pt_supply == 0, "PT supply should be 0");
    assert!(yt_supply == 0, "YT supply should be 0");
    assert!(sy_held == 0, "SY held should be 0");
}

// ============ Maturity Tests ============

#[test]
fn test_is_not_matured_before_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();

    // Set timestamp before maturity
    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);

    let is_matured = dispatcher.is_matured();
    assert!(!is_matured, "Should not be matured before maturity");

    stop_cheat_block_timestamp(contract_address);
}

#[test]
fn test_is_matured_after_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();

    // Set timestamp after maturity
    start_cheat_block_timestamp(contract_address, AFTER_MATURITY);

    let is_matured = dispatcher.is_matured();
    assert!(is_matured, "Should be matured after maturity");

    stop_cheat_block_timestamp(contract_address);
}

#[test]
fn test_is_matured_at_exact_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();

    // Set timestamp at exact maturity
    start_cheat_block_timestamp(contract_address, MATURITY_TIMESTAMP);

    let is_matured = dispatcher.is_matured();
    assert!(is_matured, "Should be matured at exact maturity");

    stop_cheat_block_timestamp(contract_address);
}

// ============ Tokenization Tests ============

#[test]
fn test_tokenize_returns_equal_pt_yt() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    // Set timestamp before maturity
    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);

    let sy_amount: u256 = 1000;
    let (pt_amount, yt_amount) = dispatcher.tokenize(sy_amount, user);

    // PT and YT should equal SY amount
    assert!(pt_amount == sy_amount, "PT amount should equal SY");
    assert!(yt_amount == sy_amount, "YT amount should equal SY");

    stop_cheat_caller_address(contract_address);
    stop_cheat_block_timestamp(contract_address);
}

#[test]
fn test_tokenize_updates_total_sy_locked() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);

    let sy_amount: u256 = 500;
    dispatcher.tokenize(sy_amount, user);

    let (_, _, sy_held) = dispatcher.get_token_info();
    assert!(sy_held == sy_amount, "SY held should be updated");

    stop_cheat_caller_address(contract_address);
    stop_cheat_block_timestamp(contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be > 0')]
fn test_tokenize_fails_with_zero_amount() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);

    dispatcher.tokenize(0, user);
}

#[test]
#[should_panic(expected: 'Already matured')]
fn test_tokenize_fails_after_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    // Set timestamp after maturity
    start_cheat_block_timestamp(contract_address, AFTER_MATURITY);
    start_cheat_caller_address(contract_address, user);

    dispatcher.tokenize(1000, user);
}

// ============ Redemption Tests (Before Maturity) ============

#[test]
fn test_redeem_before_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);

    // First tokenize
    let sy_amount: u256 = 1000;
    dispatcher.tokenize(sy_amount, user);

    // Then redeem
    let sy_returned = dispatcher.redeem(sy_amount, sy_amount, user);

    assert!(sy_returned == sy_amount, "Should return same SY amount");

    stop_cheat_caller_address(contract_address);
    stop_cheat_block_timestamp(contract_address);
}

#[test]
#[should_panic(expected: 'PT and YT must be equal')]
fn test_redeem_fails_with_unequal_amounts() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);

    dispatcher.tokenize(1000, user);
    dispatcher.redeem(500, 600, user); // Unequal amounts
}

#[test]
#[should_panic(expected: 'Use redeem_pt_after_maturity')]
fn test_redeem_fails_after_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    // Tokenize before maturity
    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);
    dispatcher.tokenize(1000, user);
    stop_cheat_block_timestamp(contract_address);

    // Try to redeem after maturity
    start_cheat_block_timestamp(contract_address, AFTER_MATURITY);
    dispatcher.redeem(1000, 1000, user);
}

// ============ PT Redemption After Maturity Tests ============

#[test]
fn test_redeem_pt_after_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    // Tokenize before maturity
    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);
    dispatcher.tokenize(1000, user);
    stop_cheat_block_timestamp(contract_address);

    // Redeem after maturity
    start_cheat_block_timestamp(contract_address, AFTER_MATURITY);
    let sy_returned = dispatcher.redeem_pt_after_maturity(1000, user);

    assert!(sy_returned == 1000, "Should return 1:1 for PT");

    stop_cheat_caller_address(contract_address);
    stop_cheat_block_timestamp(contract_address);
}

#[test]
#[should_panic(expected: 'Not yet matured')]
fn test_redeem_pt_after_maturity_fails_before_maturity() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let user = get_user();

    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);

    dispatcher.tokenize(1000, user);
    dispatcher.redeem_pt_after_maturity(1000, user);
}

// ============ Pause/Unpause Tests ============

#[test]
fn test_owner_can_pause() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let owner = get_owner();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.pause();
    stop_cheat_caller_address(contract_address);

    // Contract should now be paused - would need is_paused() view function
}

#[test]
fn test_owner_can_unpause() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let owner = get_owner();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.pause();
    dispatcher.unpause();
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Only owner')]
fn test_non_owner_cannot_pause() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let non_owner = get_user();

    start_cheat_caller_address(contract_address, non_owner);
    dispatcher.pause();
}

#[test]
#[should_panic(expected: 'Contract paused')]
fn test_tokenize_fails_when_paused() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let owner = get_owner();
    let user = get_user();

    // Owner pauses
    start_cheat_caller_address(contract_address, owner);
    dispatcher.pause();
    stop_cheat_caller_address(contract_address);

    // User tries to tokenize
    start_cheat_block_timestamp(contract_address, BEFORE_MATURITY);
    start_cheat_caller_address(contract_address, user);
    dispatcher.tokenize(1000, user);
}

// ============ View Function Tests ============

#[test]
fn test_implied_apy() {
    let (_, dispatcher) = deploy_tokenizer();

    let apy = dispatcher.implied_apy();
    // Default is 500 basis points (5%)
    assert!(apy == 500, "Default APY should be 500 bps");
}

#[test]
fn test_sync_does_not_fail() {
    let (contract_address, dispatcher) = deploy_tokenizer();
    let owner = get_owner();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.sync(); // Should not panic
    stop_cheat_caller_address(contract_address);
}
