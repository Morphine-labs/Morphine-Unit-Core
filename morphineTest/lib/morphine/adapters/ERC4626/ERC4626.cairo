%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)

from starkware.cairo.common.uint256 
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from morphine.adapters.baseAdapter import baseAdapter, drip_manager, drip_transit, target
from morphine.integrations.ERC4626.IERC4626 import IERC4626
from morphine.interfaces.IDripManager import IDripManager

// Storage

@storage_var
func token() -> (address : felt) {
}

//Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _drip_manager: felt,
        _target: felt) {
    baseAdapter.initializer(_drip_manager, _target);
    let (token_) = IERC4626.asset(_target);
    token.write(token_);   
    let (token_mask_) = IDripManager.tokenMask(token_);
    let (y_token_mask_) = IDripManager.tokenMask(_target);
    with_attr error_message("token not allowed") {
        assert_not_zero(token_mask_ * y_token_mask_);
    }
    return();
}


@external 
func depositAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (token_) = token.read();
    let (balance_) = IERC20.balanceOf(token_, drip_);
    let (is_lt_) = uint256_lt(Uint256(0,0), balance_);
    if(is_lt_ == 1){
        _deposit(drip_, balance_, 1);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    ReentrancyGuard._end();
    return ();
}

@external 
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    _deposit(drip_, _amount, 0);
    ReentrancyGuard._end();
    return ();
}

@external 
func withdrawAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (token_) = target.read();
    let (balance_) = IERC20.balanceOf(token_, drip_);
    let (is_lt_) = uint256_lt(Uint256(0,0), balance_);
    if(is_lt_ == 1){
        _withdraw(drip_, balance_, 1);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    ReentrancyGuard._end();
    return ();
}

@external 
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    _withdraw(drip_, _amount, 0);
    ReentrancyGuard._end();
    return ();
}

func _deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256) {
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    _withdraw(drip_, _amount, 0);
    ReentrancyGuard._end();
    return ();
}


    
