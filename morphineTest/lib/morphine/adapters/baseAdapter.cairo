// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (access/ownable/library.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import ALL_ONES, Uint256
from openzeppelin.token.erc20.IERC20 import IERC20
from morphine.interfaces.IDripManager import IDripManager

//
// Storage
//

@storage_var
func drip_manager() -> (drip_manager: felt) {
}

@storage_var
func drip_transit() -> (drip_manager: felt) {
}

@storage_var
func target() -> (drip_manager: felt) {
}

namespace BaseAdapter {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_manager: felt, _target_contract: felt) {
        with_attr error_message("zero address") {
            assert_not_zero(_drip_manager * _target_contract);
        }
        drip_manager.write(_drip_manager);
        let (drip_transit_) = IDripManager.dripTransit(_drip_manager);
        drip_transit.write(drip_transit_);
        target.write(_target_contract);
        return ();
    }

    func approve_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt, _amount: Uint256) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (target_) = target.read();
        IDripManager.approveDrip(drip_manager_, caller_, target_, _amount);
        return ();
    }

    func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _amount: Uint256, _calldata_len: felt, _calldata: felt*) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (target_) = target.read();
        let (retdata_len: felt, retdata: felt*) = IDripManager.executeOrder(drip_manager_, caller_, target_, _selector, _calldata_len, _calldata);
        return ();
    }

    func execute_max_allowance_fast_check{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _token_in: felt,
            _token_out: felt, 
            _allow_token_in: felt,
            _disable_token_in: felt,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
        let (retdata_len: felt, retdata: felt*) = execute_max_allowance_fast_check_drip(drip_, _token_in, _token_out, _allow_token_in, _disable_token_in, _selector, _calldata_len, _calldata);
        return ();
    }

    func execute_max_allowance_fast_check_drip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt,
            _token_in: felt,
            _token_out: felt, 
            _allow_token_in: felt,
            _disable_token_in: felt,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) {
        alloc_locals;

        if(_allow_token_in == 1){
            approve_token(_token_in, Uint256(ALL_ONES, ALL_ONES));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (target_) = target.read();
        let (retdata_len: felt, retdata: felt*) = IDripManager.executeOrder(drip_manager_, caller_, target_, _selector, _calldata_len, _calldata);
        if(_allow_token_in == 1){
            approve_token(_token_in, Uint256(ALL_ONES, ALL_ONES));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        let (balance_in_before_) = IERC20.balanceOf(_token_in, _drip);
        let (balance_out_before_) = IERC20.balanceOf(_token_out, _drip);
        fast_check(_drip, _token_in, _token_out, balance_in_before_, balance_out_before_, _disable_token_in);
        return ();
    }

    func safe_execute_fast_check{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _token_in: felt,
            _token_out: felt, 
            _allow_token_in: felt,
            _disable_token_in: felt,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
        let (retdata_len: felt, retdata: felt*) = safe_execute_fast_check_drip(drip_, _token_in, _token_out, _allow_token_in, _disable_token_in, _selector, _calldata_len, _calldata);
        return ();
    }

    func safe_execute_fast_check_drip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt,
            _token_in: felt,
            _token_out: felt, 
            _allow_token_in: felt,
            _disable_token_in: felt,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) {
        alloc_locals;

        if(_allow_token_in == 1){
            approve_token(_token_in, Uint256(ALL_ONES, ALL_ONES));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (target_) = target.read();
        let (retdata_len: felt, retdata: felt*) = IDripManager.executeOrder(drip_manager_, caller_, target_, _selector, _calldata_len, _calldata);
        if(_allow_token_in == 1){
            approve_token(_token_in, Uint256(0, 0));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        let (balance_in_before_) = IERC20.balanceOf(_token_in, _drip);
        let (balance_out_before_) = IERC20.balanceOf(_token_out, _drip);
        fast_check(_drip, _token_in, _token_out, balance_in_before_, balance_out_before_, _disable_token_in);
        return ();
    }

    func fast_check{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt,
            _token_in: felt,
            _token_out: felt, 
            _balance_in_before: Uint256,
            _balance_out_before: Uint256,
            _disable_token_in: felt) {
        alloc_locals;
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_transit_) = drip_transit.read();
        if(caller_ == drip_transit_){
            if(_disable_token_in == 1){
                IDripManager.disableToken(drip_manager_, _token_in);
                return();
            } else {
                return();
            }
        } else {
            IDripManager.fastCollateralCheck(drip_manager_, _drip, _token_in, _token_out, _balance_in_before, _balance_out_before, _disable_token_in);
            return();
        }
    }

    func full_check{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt) {
        alloc_locals;
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_transit_) = drip_transit.read();
        if(caller_ == drip_transit_){
           return();
        } else {
            IDripManager.fullCollateralCheck(drip_manager_, _drip);
            return();
        }
    }

    func check_and_optimize_enabled_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt) {
        alloc_locals;
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_transit_) = drip_transit.read();
        if(caller_ == drip_transit_){
           return();
        } else {
            IDripManager.checkAndOptimizeEnabledTokens(drip_manager_, _drip);
            return();
        }
    }

}
