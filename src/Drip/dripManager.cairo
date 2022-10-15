%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.math_cmp import ( 
    is_le,
    is_nn,
    is_not_zero
)

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_lt,
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

from openzeppelin.security.safemath.library import SafeUint256

from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from src.interfaces.IPoolFactory import IPoolFactory

from src.interfaces.IPool import IPool

from src.interfaces.IRegistery import IRegistery

from src.interfaces.IAccountFactory import IAccountFactory

from src.interfaces.IDrip import IDrip

// Const

const TRUE = 1;
const FALSE = 0;
const PERCENTAGE_FACTOR = 10000;
const HALF_PERCENT = PERCENTAGE_FACTOR / 2;

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
func drip_account(address : felt) -> (dripAccounts: felt) {
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
func enabled_tokens_map(drip_account : felt) -> (res: felt) {
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

func get_drip_or_revert {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_account : felt){
    let is_not_null : felt = is_not_zero(drip_account);
    with_attr error_message("Drip account is null") {
        assert is_not_null = 1;
    }
    return();
}

func borrow_not_null_or_revert{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(caller : felt){
    let is_not_null : felt = is_not_zero(caller);
    with_attr error_message("Drip account is null") {
        assert is_not_null = 1;
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

@external
func openCreditAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    borrowed_amount: Uint256, behalfOf : felt) -> (address: felt){
    alloc_locals;
    Pausable.assert_not_paused();
    drip_facade_only();
    let (caller) = get_caller_address();
    let (contract_address : felt) = get_contract_address();
    let (account_factory : felt) = IRegistery.accountFactory(contract_address);

    let (min : Uint256) = min_borrowed_amount.read();
    let (max : Uint256) = max_borrowed_amount.read();
    let (check_lower_bound : felt) = uint256_lt(min ,borrowed_amount);
    let (check_upper_bound : felt) = uint256_lt(borrowed_amount, max);
    let check_borrow : felt = check_lower_bound - 0 * check_upper_bound - 0;
    with_attr error_message("Drip: borrowed amount is out of bounds") {
        assert check_borrow = 1;
    }
    let (cumulative_index : Uint256) = IPool.calculLinearCumulativeIndex(contract_address);
    let (drip : felt) = IAccountFactory.removeDripAccount(account_factory, borrowed_amount, cumulative_index);
    // TODO
    // IPool.lendDrip(borrowed_amount,drip);
    safe_drip_account_set(behalfOf, drip);
    enabled_tokens_map.write(drip,1);
    fast_check_counter.write(drip,Uint256(1,0));

    return(drip,);
}

@external
func closeCreditAccount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrower : felt, _is_liquidated : felt, _total_value : Uint256, _payer : felt, _to : felt, _skip_token_mask : Uint256) -> (remaining : Uint256) {
    get_drip_or_revert(_borrower);
    let drip : felt = _borrower;
    let (borrowed_amount, borrowed_amount_with_interest) = calcAccruedInterest(drip);



    let tmp_rtn : Uint256 = Uint256(1,0);
    return(tmp_rtn,);
}

@view
func calcAccruedInterest {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip : felt) -> 
(borrowed_amount : Uint256, borrowed_amount_with_interest : Uint256){
    alloc_locals;
    let (borrowed_amount, cumulative_index_open, cumulative_index_now) = get_drip_parameter(drip);
    let (tmp_borrow ) = SafeUint256.mul(borrowed_amount, cumulative_index_now);
    let (borrowed_amount_with_interest, _) = SafeUint256.div_rem(tmp_borrow, cumulative_index_open);
    return(borrowed_amount, borrowed_amount_with_interest);
}

@view
func calcClosePayments{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _total_value : Uint256, _is_liquidated : felt, _borrowed_amount_with_interest : Uint256, _borrowed_amount : Uint256) -> (
    amount_to_pool : Uint256, remaining_assets : Uint256, profit : Uint256, loss : Uint256){
}

func get_drip_parameter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip : felt) ->
    (borrowed_amount : Uint256, cumulative_index_open : Uint256, cumulative_index_now : Uint256){
    let (borrowed_amount : Uint256) = IDrip.total_borrowed_amount(drip);
    let (cumulative_open : Uint256) = IDrip.cumulative_index_open(drip);
    let (cumulative_now : Uint256) = IPool.calculLinearCumulativeIndex(drip);
    return(borrowed_amount, cumulative_open, cumulative_now);
}

 func safe_drip_account_set{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(borrower : felt, drip : felt)
{
    borrow_not_null_or_revert(borrower);
    get_drip_or_revert(drip);
    return();
}
