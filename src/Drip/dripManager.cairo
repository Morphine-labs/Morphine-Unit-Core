%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from src.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

from src.Pool.IPoolFactory import IPoolFactory

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
func is_allowed_token(token: felt) -> (is_allowed : felt){
}

@storage_var
func id_to_allowed_token(token: felt) -> (is_allowed : felt){
}

@storage_var
func drip_accounts(address : felt) -> (dripAccounts: felt) {
}

@storage_var
func drip_facade() -> (dripFacade: felt) {
}

@storage_var
func acoount_factory() -> (address : felt) {
}

@storage_var
func pool_factory() -> (address : felt) {
}

@storage_var
func min_borrowed_amount() -> (min_borrowed_amount : Uint256) {
}

@storage_var
func max_borrowed_amount() -> (max_borrowed_amount : Uint256) {
}

@storage_var
func fee_liquidation() -> (liquidation_fees : Uint256) {
}

@storage_var
func liquidation_thresholds(address : felt) -> (liquidationThresholds : Uint256) {
}

@storage_var
func token_mask_map() -> (mask : Uint256) {
}

@storage_var
func forbiden_token_mask() -> (res: felt) {
}

@storage_var
func enabled_tokens_map() -> (res: felt) {
}

@storage_var
func fast_check_counter(address : felt) -> (liquidationThresholds : Uint256) {
}

@storage_var
func adapter_to_contract(address : felt) -> (contract : felt) {
}

@storage_var
func chi_threshold() -> (chi_threshold : Uint256) {
}

@storage_var
func hf_check_interval() -> (hf : Uint256) {
}

const ETH_ADDRESS = 0;

    // Address of WETH Gateway
    // address public immutable wethGateway;


// Protector

func adapter_or_facade_only{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_ : felt ) = get_caller_address();
    let (adapter : felt ) = adapter_to_contract.read(caller_);
    if (adapter == 0){
        let (facade : felt ) = drip_facade.read();
        with_attr error_message("Drip: only callable by adapter or facade") {
            assert caller_ = facade;
        }
        return();
    }
    return();
}

func drip_facade_only {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_ : felt ) = get_caller_address();
    let (facade : felt ) = drip_facade.read();
    with_attr error_message("Drip: only callable by facade") {
        assert caller_ = facade;
    }
    return();
}

func credit_configurator_only {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_ : felt ) = get_caller_address();
    let (configurator : felt ) = drip_configurator.read();
    with_attr error_message("Drip: only callable by configurator") {
        assert caller_ = configurator;
    }
    return();
}

// Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _pool_factory: felt,) {
    let (contract_address : felt ) = get_contract_address();
    pool_factory.write(_pool_factory); 
    let (underlying_asset : felt) = IPoolFactory.get_asset(contract_address,_pool_factory);
    return();
}

// External