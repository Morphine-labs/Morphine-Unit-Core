%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.utils.safeerc20 import SafeERC20
from src.utils.various import ALL_ONES

// Structs
struct CreditManagerOpts {
    min_borrowed_amount : Uint256,
    max_borrowed_amount : Uint256,
    allowed_tokens: felt*,
}

// Storage

@storage_var
func owner_to_drip(owner: felt) -> (drip : felt){
}

@storage_var
func drip_factory() -> (drip_factory : felt){
}

@storage_var
func underlying() -> (underlying : felt){
}

@storage_var
func pool() -> (pool : felt){
}

@storage_var
func minimum_borrowed_amount() -> (minimum_borrowed_amount : Uint256){
}

@storage_var
func maximum_borrowed_amount() -> (maximum_borrowed_amount : Uint256){
}

@storage_var
func maximum_borrowed_amount() -> (maximum_borrowed_amount : Uint256){
}

// Interest fee protocol charges: fee = interest accrues * feeInterest
@storage_var
func fee_interest() -> (fee_interest : Uint256){
}

// Liquidation fee protocol charges: fee = totalValue * feeLiquidation
@storage_var
func fee_liqudidation() -> (fee_liqudidation : Uint256){
}

// Multiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
@storage_var
func liquidation_discount() -> (liquidation_discount : Uint256){
}

@storage_var
func drip_junction() -> (drip_junction : felt){
}

@storage_var
func drip_configurator() -> (drip_configurator : felt){
}

@storage_var
func drip_configurator() -> (drip_configurator : felt){
}

@storage_var
func is_allowed_token(token: felt) -> (is_allowed : felt){
}

@storage_var
func id_to_allowed_token(token: felt) -> (is_allowed : felt){
}

@storage_var
func allowed_tokens() -> (allowed_tokens : felt*) {
}

@storage_var
func creditAccounts(address : felt) -> (creditAccounts: felt) {
}

@storage_var
func acoountFactory() -> (res: felt) {
}

    // Underlying token address
    address public immutable override underlying;

    // Address of connected pool
    address public immutable override poolService;

    // Address of WETH token
    address public immutable override wethAddress;

    // Address of WETH Gateway
    address public immutable wethGateway;

    // Minimal borrowed amount per credit account
    uint256 public override minBorrowedAmount;

    // Maximum aborrowed amount per credit account
    uint256 public override maxBorrowedAmount;

    // Interest fee protocol charges: fee = interest accrues * feeInterest
    uint256 public override feeInterest;

    // Liquidation fee protocol charges: fee = totalValue * feeLiquidation
    uint256 public override feeLiquidation;

    // Miltiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
    uint256 public override liquidationDiscount;

    // Address of creditFacade
    address public override creditFacade;

    // Adress of creditConfigurator
    address public creditConfigurator;

    // Allowed tokens array
    address[] public override allowedTokens;

    // Allowed contracts list
    mapping(address => uint256) public override liquidationThresholds;

    // map token address to its mask
    mapping(address => uint256) public override tokenMasksMap;

    // Mask for forbidden tokens
    uint256 public override forbidenTokenMask;

    // credit account token enables mask. each bit (in order as tokens stored in allowedTokens array) set 1 if token was enable
    mapping(address => uint256) public override enabledTokensMap;

    // keeps last block we use fast check. Fast check is not allowed to use more than one time in block
    mapping(address => uint256) public fastCheckCounter;

    // Allowed adapters list
    mapping(address => address) public override adapterToContract;

    // Price oracle - uses in evaluation credit account
    IPriceOracle public override priceOracle;

    // Minimum chi threshold allowed for fast check
    uint256 public chiThreshold;

    // Maxmimum allowed fast check operations between full health factor checks
    uint256 public hfCheckInterval;


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _drip_manager: felt,
        _borrowed_amount: Uint256,
        _cumulative_index: Uint256) {
    let (block_timestamp_) = get_block_timestamp();
    since.write(block_timestamp_);
    drip_manager.write(_drip_manager);
    borrowed_amount.write(_borrow_amount);
    cumulative_index.write(_cumulative_index);
    return();
}

@external
func updateParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _borrowed_amount: Uint256,
        _cumulative_index: Uint256) {
    assert_only_drip_manager();
    borrowed_amount.write(_borrow_amount);
    cumulative_index.write(_cumulative_index);
    return();
}

@external
func approveToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _token: felt,
        _contract: felt) {
    assert_only_drip_manager();
    IERC20.approve(_token, _contract, Uint256(ALL_ONES,ALL_ONES));
    return();
}

@external
func cancelAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _token: felt,
        _contract: felt) {
    assert_only_drip_manager();
    IERC20.approve(_token, _contract, Uint256(0,0));
    return();
}

@external
func safeTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _token: felt,
        _to: felt,
        _amount: Uint256) {
    assert_only_drip_manager();
    SafeERC20.transfer(_token, _to, _amount);
    return();
}

@external
func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _to: felt,
        _selector: felt,
        _calldata_len: felt,
        _calldata: felt*) -> (retdata_size: felt, retdata: felt*) {
    assert_only_drip_manager();
    let (retdata_size: felt, retdata: felt*) = call_contract(_to,_selector, _calldata_len, _calldata);
    return(retdata_size, retdata);
}

func assert_only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_) = get_caller_address();
    let (drip_manager_) = drip_manager.read();
    with_attr error_message("Drip: only callable by drip manger") {
        assert caller_ = drip_manager_;
    }
}