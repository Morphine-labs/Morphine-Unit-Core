%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)

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
from morphine.utils.various import DEPOSIT_SELECTOR, REDEEM_SELECTOR, MAX_PATH_LEN

/// @title: Jediswap adapter
/// @author: Graff Sacha (0xSacha)
/// @dev: Contract that contains all method to interact with Jediswap AMM
/// @custom: experimental This is an experimental contract.

//
// Storage
//

@storage_var
func rooter() -> (address : felt) {
}

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
    rooter.write(_target);  
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

// @notice: Deposits all tokens 
// @return: amount of tokens deposited
@external 
func swapExactTokensForTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount_in: Uint256, _amount_out_min: Uint256, path_len: felt, path: felt*, _to: felt, _deadline: felt) -> (amounts_len: felt, amounts: Uint256*) -> (amounts_len: felt, amounts: Uint256*) {
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (rooter_) = rooter.read();
    let (deadline_) = get_block_timestamp()
    let (token_in_, token_out_) = check_path_and_get_tokens(path_len, path);
    IRouter.swap_exact_tokens_for_tokens(rooter_, _amount_in, _amount_out_min, path_len, path, drip_, deadline_);
path_len: felt, path: felt*

    ReentrancyGuard.end();
}

func check_path_and_get_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(path_len: felt, path: felt*) -> (token_in: felt, token_out: felt) {
    alloc_locals;

    let (is_path_nul) = uint256_eq(Uint256(path_len,0), Uint256(0,0));
    with_attr error_message("path len nul") {
        assert is_path_nul = 0;
    }
    let (is_allowed_path_len_) = uint256_lt(Uint256(path_len,0), Uint256(MAX_PATH_LEN,0));
    with_attr error_message("path len nul") {
        assert is_allowed_path_len_ = 1;
    }

    let (token_in_mask_) = IDripManager.tokenMask(_drip_manager, path[0]);
    let (is_zero_) = uint256_eq(token_in_mask_, Uint256(0,0));
    with_attr error_message("input token not allowed") {
        assert is_zero_ = 0;
    }

    let (token_out_mask_) = IDripManager.tokenMask(_drip_manager, path[path_len - 1]);
    let (is_zero_) = uint256_eq(token_out_mask_, Uint256(0,0));
    with_attr error_message("vault token not allowed") {
        assert is_zero_ = 0;
    }
    return (path[0], path[path_len - 1]);
}


check_path_and_get_tokens
// @notice: Deposits tokens
// @param: _amount amount of tokens to deposit
// @return: shares amount of shares
@external 
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) -> (shares: Uint256) {
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (shares_) = _deposit(drip_, _amount, 0);
    ReentrancyGuard.end();
    return (shares_,);
}

// @notice: Redeem all tokens
// @return: amount of tokens redeemed
@external
func redeemAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (assets: Uint256) {
    ReentrancyGuard.start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (token_) = targetContract();
    let (balance_) = IERC20.balanceOf(token_, drip_);
    let (is_lt_) = uint256_lt(Uint256(0,0), balance_);
    if(is_lt_ == 1){
        let (assets_) = _redeem(drip_, balance_, 1);
        ReentrancyGuard.end();
        return (assets_,);
    } else {
        ReentrancyGuard.end();
        return (Uint256(0,0),);
    }
}

// @notice: Redeem tokens
// @param: _amount  amount of shares to redeem
// @return: amount of assets redeemed
@external 
func redeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) -> (assets: Uint256) {
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (assets_) = _redeem(drip_, _amount, 0);
    ReentrancyGuard.end();
    return (assets_,);
}

//
//  Internals 
//

// @notice: Deposits tokens
// @custom: internal function
// @param: _drip drip address
// @param: _amount amount of tokens to deposit
// @param: _disable_token_in boolean to disable token in
// @return: shares amount of shares
func _deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt, _amount: Uint256, _disable_token_in: felt) -> (shares: Uint256) {
    alloc_locals;
    let (token_in_) = token.read();
    let (token_out_) = targetContract();
    let (calldata) = alloc();
    assert calldata[0] = _amount.low;
    assert calldata[1] = _amount.high;
    assert calldata[2] = _drip;
    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(_drip, token_in_, token_out_, 1, _disable_token_in, DEPOSIT_SELECTOR, 3, calldata);
    return (Uint256(retdata[0], retdata[1]),);
}

// @notice: Redeem tokens
// @custom: internal function
// @param: _drip drip address
// @param: _amount amount of shares to redeem
// @param: _disable_token_out boolean to disable token out
// @return: amount of assets redeemed
func _redeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt, _amount: Uint256, _disable_token_in: felt) -> (assets: Uint256) {
    alloc_locals;
    let (token_out_) = token.read();
    let (token_in_) = targetContract();
    let (calldata) = alloc();
    assert calldata[0] = _amount.low;
    assert calldata[1] = _amount.high;
    assert calldata[2] = _drip;
    assert calldata[3] = _drip;
    let (retdata_len: felt, retdata: felt*) = BaseAdapter.safe_execute_drip(_drip, token_in_, token_out_, 1, _disable_token_in, REDEEM_SELECTOR, 4, calldata);
    return (Uint256(retdata[0], retdata[1]),);
}

    
