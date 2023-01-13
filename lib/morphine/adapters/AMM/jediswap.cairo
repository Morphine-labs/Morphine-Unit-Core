%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.uint256 import Uint256, ALL_ONES, uint256_lt, uint256_eq
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from morphine.adapters.baseAdapter import BaseAdapter, drip_manager, drip_transit, target
from morphine.integrations.ERC4626.IERC4626 import IERC4626
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IJediSwapFactory import IFactory
from morphine.interfaces.IRouter import IRouter
from morphine.utils.various import SWAP_TOKENS_FOR_EXACT_TOKENS_SELECTOR, SWAP_EXACT_TOKENS_FOR_TOKENS_SELECTOR, MAX_PATH_LEN, ADD_LIQUIDITY_SELECTOR, REMOVE_LIQUIDITY_SELECTOR, PRECISION

/// @title: Jediswap adapter
/// @author: Graff Sacha (0xSacha)
/// @dev: Contract that contains all method to interact with Jediswap AMM
/// @custom: experimental This is an experimental contract.

//
// Storage
//


//
//  Constructor
//

// @notice: Constructor for the adapter will be called only once.
// @param: _drip_manager drip manager address
// @param: _target target address
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _drip_manager: felt,
        _target: felt) {
    alloc_locals;
    BaseAdapter.initializer(_drip_manager, _target);
    return();
}

//
//  Views
//

// @notice: Returns the drip manager address
// @return: drip manager address
@view
func dripManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (dripManager: felt){
    let (drip_manager_) = drip_manager.read();
    return (drip_manager_,);
}

// @notice: Returns the drip transit address
// @return: drip transit address
@view
func dripTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (dripTransit: felt){
    let (drip_transit_) = drip_transit.read();
    return (drip_transit_,);
}

// @notice: Returns the target address
// @return: target address
@view
func targetContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (target: felt){
    let (target_) = target.read();
    return (target_,);
}

//
//  Externals
//


// @notice: Swap exact tokens for tokens
// @return: amount of tokens deposited
@external 
func swap_exact_tokens_for_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount_in: Uint256, _amount_out_min: Uint256, path_len: felt, path: felt*, _to: felt, _deadline: felt) -> (amounts_len: felt, amounts: felt*) {
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (deadline_) = get_block_timestamp();

    let (token_in_, token_out_) = check_path_and_get_tokens(path_len, path);
    let (token_in) = alloc();
    assert token_in[0] = token_in_;
    let (token_out) = alloc();
    assert token_out[0] = token_out_;
    let (disable_token_in) = alloc();
    assert disable_token_in[0] = 0;

    let (calldata) = alloc();
    assert calldata[0] = _amount_in.low;
    assert calldata[1] = _amount_in.high;
    assert calldata[2] = _amount_out_min.low;
    assert calldata[3] = _amount_out_min.low;
    assert calldata[4] = path_len;
    memcpy(calldata + 5, path, path_len);
    assert calldata[4 + path_len] = drip_;
    assert calldata[4 + path_len + 1] = deadline_;

    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(drip_, 1, token_in, 1, token_out, 1, 1, disable_token_in, SWAP_EXACT_TOKENS_FOR_TOKENS_SELECTOR, 4 + path_len + 2, calldata);
    ReentrancyGuard.end();
    return (retdata_len, retdata,);
}

// @notice: Swap tokens for exact tokens
// @return: amount of tokens deposited
@external 
func swap_tokens_for_exact_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount_out: Uint256, _amount_in_min: Uint256, path_len: felt, path: felt*, _to: felt, _deadline: felt) -> (amounts_len: felt, amounts: felt*) {
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (deadline_) = get_block_timestamp();

    let (token_in_, token_out_) = check_path_and_get_tokens(path_len, path);
    let (token_in) = alloc();
    assert token_in[0] = token_in_;
    let (token_out) = alloc();
    assert token_out[0] = token_out_;
    let (disable_token_in) = alloc();
    assert disable_token_in[0] = 0;

    let (calldata) = alloc();
    assert calldata[0] = _amount_out.low;
    assert calldata[1] = _amount_out.high;
    assert calldata[2] = _amount_in_min.low;
    assert calldata[3] = _amount_in_min.low;
    assert calldata[4] = path_len;
    memcpy(calldata + 5, path, path_len);
    assert calldata[4 + path_len] = drip_;
    assert calldata[4 + path_len + 1] = deadline_;

    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(drip_, 1, token_in, 1, token_out, 1, 1, disable_token_in, SWAP_TOKENS_FOR_EXACT_TOKENS_SELECTOR, 4 + path_len + 2, calldata);
    ReentrancyGuard.end();
    return (retdata_len, retdata,);
}


// @notice: Swap all tokens for tokens
// @return: amount of tokens deposited
@external 
func swap_all_tokens_for_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(rate_min: Uint256, path_len: felt, path: felt*) -> (amounts_len: felt, amounts: felt*) {
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (deadline_) = get_block_timestamp();

    let (token_in_, token_out_) = check_path_and_get_tokens(path_len, path);
    let (token_in) = alloc();
    assert token_in[0] = token_in_;
    let (token_out) = alloc();
    assert token_out[0] = token_out_;
    let (disable_token_in) = alloc();
    assert disable_token_in[0] = 0;

    let (balance_) = IERC20.balanceOf(token_in_, drip_);
    let (step1_) = SafeUint256.mul(rate_min, balance_);
    let (amount_out_min_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
    let (calldata) = alloc();
    assert calldata[0] = balance_.low;
    assert calldata[1] = balance_.high;
    assert calldata[2] = amount_out_min_.low;
    assert calldata[3] = amount_out_min_.low;
    assert calldata[4] = path_len;
    memcpy(calldata + 5, path, path_len);
    assert calldata[4 + path_len] = drip_;
    assert calldata[4 + path_len + 1] = deadline_;

    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(drip_, 1, token_in, 1, token_out, 1, 1, disable_token_in, SWAP_EXACT_TOKENS_FOR_TOKENS_SELECTOR, 4 + path_len + 2, calldata);
    ReentrancyGuard.end();
    return (retdata_len, retdata,);
}


// @notice: Add  Liq for exact tokens
// @return: amount of tokens deposited
@external 
func add_liquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token_a: felt, _token_b: felt, _amount_a_desired: Uint256, _amount_b_desired: Uint256, _amount_a_min: Uint256, _amount_b_min: Uint256, to: felt, deadline: felt) -> (retdata_len: felt, retdata: felt*) {
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (deadline_) = get_block_timestamp();

    let (token_in) = alloc();
    assert token_in[0] = _token_a;
    assert token_in[1] = _token_b;

    let (rooter_) = target.read();
    let (factory_) = IRouter.factory(rooter_);

    let (token_out_) = IFactory.get_pair(factory_, _token_a, _token_b);
    let (token_out) = alloc();
    assert token_out[0] = token_out_;
    let (disable_token_in) = alloc();
    assert disable_token_in[0] = 0;
    assert disable_token_in[1] = 0;

    let (calldata) = alloc();
    assert calldata[0] = _token_a;
    assert calldata[1] = _token_b;
    assert calldata[2] = _amount_a_desired.low;
    assert calldata[3] = _amount_a_desired.high;
    assert calldata[4] = _amount_b_desired.low;
    assert calldata[5] = _amount_b_desired.high;
    assert calldata[6] = _amount_a_min.low;
    assert calldata[7] = _amount_a_min.high;
    assert calldata[8] = _amount_b_min.low;
    assert calldata[9] = _amount_b_min.high;
    assert calldata[10] = drip_;
    assert calldata[11] = deadline_;

    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(drip_, 2, token_in, 1, token_out, 1, 2, disable_token_in, ADD_LIQUIDITY_SELECTOR, 12, calldata);
    ReentrancyGuard.end();
    return (retdata_len, retdata,);
}

// @notice: Add  Liq for exact tokens
// @return: amount of tokens deposited
@external 
func add_liquidity_max_token_a{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token_a: felt, _token_b: felt, _rate_b: Uint256, _slippage: Uint256) -> (retdata_len: felt, retdata: felt*) {
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (deadline_) = get_block_timestamp();

    let (token_in) = alloc();
    assert token_in[0] = _token_a;
    assert token_in[1] = _token_b;

    let (rooter_) = target.read();
    let (factory_) = IRouter.factory(rooter_);
    let (token_out_) = IFactory.get_pair(factory_, _token_a, _token_b);
    let (token_out) = alloc();
    assert token_out[0] = token_out_;
    let (disable_token_in) = alloc();
    assert disable_token_in[0] = 0;
    assert disable_token_in[1] = 0;

    let (amount_a_desired_) = IERC20.balanceOf(_token_a, drip_);
    let (step1_) = SafeUint256.mul(amount_a_desired_, _rate_b);
    let (amount_b_desired_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION, 0));
    let (token_b_drip_balance_) = IERC20.balanceOf(_token_b, drip_);
    let (is_not_enough_) = uint256_lt(token_b_drip_balance_, amount_b_desired_);
    with_attr error_message("not_enough_b_token") {
            assert is_not_enough_ = 0;
        }

    let (step1_) = SafeUint256.mul(amount_a_desired_, _slippage);
    let (min_a_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION, 0));

    let (step1_) = SafeUint256.mul(amount_b_desired_, _slippage);
    let (min_b_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION, 0));


    let (calldata) = alloc();
    assert calldata[0] = _token_a;
    assert calldata[1] = _token_b;
    assert calldata[2] = amount_a_desired_.low;
    assert calldata[3] = amount_a_desired_.high;
    assert calldata[4] = amount_b_desired_.low;
    assert calldata[5] = amount_b_desired_.high;
    assert calldata[6] = min_a_.low;
    assert calldata[7] = min_a_.high;
    assert calldata[8] = min_b_.low;
    assert calldata[9] = min_b_.high;
    assert calldata[10] = drip_;
    assert calldata[11] = deadline_;
    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(drip_, 2, token_in, 1, token_out, 1, 2, disable_token_in, ADD_LIQUIDITY_SELECTOR, 12, calldata);
    ReentrancyGuard.end();
    return (retdata_len, retdata,);
}


// @notice: Add  Liq for exact tokens
// @return: amount of tokens deposited
@external 
func remove_liquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_a: felt, token_b: felt, _liquidity: Uint256, amount_a_min: Uint256, amount_b_min: Uint256, to: felt, deadline: felt) -> (retdata_len: felt, retdata: felt*) {
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (deadline_) = get_block_timestamp();

    let (rooter_) = target.read();
    let (factory_) = IRouter.factory(rooter_);
    let (token_in_) = IFactory.get_pair(factory_, _token_a, _token_b);

    let (token_in) = alloc();
    assert token_in[0] = token_in_;
    
    let (token_out) = alloc();
    assert token_out[0] = token_a;
    assert token_out[1] = token_b;

    let (disable_token_in) = alloc();
    assert disable_token_in[0] = 0;

    let (calldata) = alloc();
    assert calldata[0] = _token_a;
    assert calldata[1] = _token_b;
    assert calldata[2] = _liquidity.low;
    assert calldata[3] = _liquidity.high;
    assert calldata[4] = _amount_a_min.low;
    assert calldata[5] = _amount_a_min.high;
    assert calldata[6] = _amount_b_min.low;
    assert calldata[7] = _amount_b_min.high;
    assert calldata[8] = drip_;
    assert calldata[9] = deadline_;

    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(drip_, 2, token_in, 1, token_out, 1, 2, disable_token_in, REMOVE_LIQUIDITY_SELECTOR, 12, calldata);
    ReentrancyGuard.end();
    return (retdata_len, retdata,);
}


func check_path_and_get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(path_len: felt, path: felt*) -> (token_in: felt, token_out: felt) {
    alloc_locals;

    let (is_path_nul) = uint256_eq(Uint256(path_len,0), Uint256(0,0));
    with_attr error_message("path len nul") {
        assert is_path_nul = 0;
    }
    let (is_allowed_path_len_) = uint256_lt(Uint256(path_len,0), Uint256(MAX_PATH_LEN,0));
    with_attr error_message("path len to big") {
        assert is_allowed_path_len_ = 1;
    }
    return (path[0], path[path_len - 1]);
}

    
