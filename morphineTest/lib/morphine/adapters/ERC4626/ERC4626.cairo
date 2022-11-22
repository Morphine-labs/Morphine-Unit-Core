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

const DEPOSIT_SELECTOR = 738373;
const REDEEM_SELECTOR = 738378393;

//
// Storage
//

@storage_var
func token() -> (address : felt) {
}

//
//  Constructor
//

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _drip_manager: felt,
        _target: felt) {
    alloc_locals;
    BaseAdapter.initializer(_drip_manager, _target);
    let (token_) = IERC4626.asset(_target);
    token.write(token_);  

    let (underlying_token_mask_) = IDripManager.tokenMask(_drip_manager, token_);
    let (is_zero_) = uint256_eq(underlying_token_mask_, Uint256(0,0));
    with_attr error_message("underlying token not allowed") {
        assert is_zero_ = 0;
    }

    let (vault_token_mask_) = IDripManager.tokenMask(_drip_manager, _target);
    let (is_zero_) = uint256_eq(vault_token_mask_, Uint256(0,0));
    with_attr error_message("vault token not allowed") {
        assert is_zero_ = 0;
    }

    return();
}

//
//  Views
//

@view
func dripManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (dripManager: felt){
    let (drip_manager_) = drip_manager.read();
    return (drip_manager_,);
}

@view
func dripTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (dripTransit: felt){
    let (drip_transit_) = drip_transit.read();
    return (drip_transit_,);
}

@view
func targetContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (target: felt){
    let (target_) = target.read();
    return (target_,);
}

//
//  Externals
//

@external 
func depositAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (shares: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (token_) = token.read();
    let (balance_) = IERC20.balanceOf(token_, drip_);
    let (is_lt_) = uint256_lt(Uint256(0,0), balance_);
    if(is_lt_ == 1){
        let (shares_) = _deposit(drip_, balance_, 1);
        ReentrancyGuard._end();
        return (shares_,);
    } else {
        ReentrancyGuard._end();
        return (Uint256(0,0),);
    }
}

@external 
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) -> (shares: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (shares_) = _deposit(drip_, _amount, 0);
    ReentrancyGuard._end();
    return (shares_,);
}

@external
func redeemAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (assets: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = dripManager();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (token_) = targetContract();
    let (balance_) = IERC20.balanceOf(token_, drip_);
    let (is_lt_) = uint256_lt(Uint256(0,0), balance_);
    if(is_lt_ == 1){
        let (assets_) = _redeem(drip_, balance_, 1);
        ReentrancyGuard._end();
        return (assets_,);
    } else {
        ReentrancyGuard._end();
        return (Uint256(0,0),);
    }
}

@external 
func redeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) -> (assets: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (assets_) = _redeem(drip_, _amount, 0);
    ReentrancyGuard._end();
    return (assets_,);
}

//
//  Internals 
//

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

    
