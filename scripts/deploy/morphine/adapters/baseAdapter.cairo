// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (access/ownable/library.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import ALL_ONES, Uint256
from openzeppelin.token.erc20.IERC20 import IERC20
from morphine.interfaces.IDripManager import IDripManager


/// @title: BaseAdapter
/// @author: Graff Sacha (0xSacha)
/// @dev: Contract that contains all method needed for future protocol integraton
/// @custom: experimental This is an experimental contract.

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

// @title: BaseAdapter namespace
namespace BaseAdapter {

    //
    // Initializer
    //

    // @notice: Initializes the contract.
    // @param: _drip_manager The address of the drip manager.
    // @param: _target_contract The address of the target.
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

    // @notice: Approve tokens to the drip manager.
    // @param: _token The address of the token.
    // @param: _amount The amount of tokens to approve.
    func approve_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt, _amount: Uint256) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (target_) = target.read();
        IDripManager.approveDrip(drip_manager_, caller_, target_, _token ,_amount);
        return ();
    }

    // @notice: Execute order on the target contract.
    // @param: _selector The selector of the function to call.
    // @param: _calldata The data to pass to the function.
    // @param: _calladata_len The length of the data.
    // @return: retdata The return data of the function call.
    // @return: retdata_len The length of the return data.
    func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_selector: felt, _calldata_len: felt, _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
        alloc_locals;
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (target_) = target.read();
        let (retdata_len: felt, retdata: felt*) = IDripManager.executeOrder(drip_manager_, caller_, target_, _selector, _calldata_len, _calldata);
        return (retdata_len, retdata,);
    }

    // @notice: Execute maximum allowance
    // @param: _token_in 
    // @param: _token_out
    // @param: _allow_token_in Check if the token_in is allowed
    // @param: _disable_token_in 
    // @param: _selector The selector of the function to call.
    // @param: _calldata The data to pass to the function.
    // @param: _calladata_len The length of the data.
    // @return: retdata The return data of the function call.
    // @return: retdata_len The length of the return data.
    func execute_max_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_in_len: felt,
            token_in: felt*, 
            token_out_len: felt,
            token_out: felt*, 
            _allow_token_in: felt,
            disable_token_in_len: felt,
            disable_token_in: felt*,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
        let (retdata_len: felt, retdata: felt*) = execute_max_allowance_drip(drip_, token_in_len, token_in, token_out_len, token_out, _allow_token_in, disable_token_in_len, disable_token_in, _selector, _calldata_len, _calldata);
        return (retdata_len, retdata,);
    }

    // @notice: Execute maximum allowance drip
    // @param: _drip The drip to execute
    // @param: _token_in
    // @param: _token_out
    // @param: _allow_token_in Check if the token_in is allowed
    // @param: _disable_token_in 
    // @param: _selector The selector of the function to call.
    // @param: _calldata The data to pass to the function.
    // @param: _calladata_len The length of the data.
    // @return: retdata The return data of the function call.
    // @return: retdata_len The length of the return data.
    func execute_max_allowance_drip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt,
            token_in_len: felt,
            token_in: felt*, 
            token_out_len: felt,
            token_out: felt*, 
            _allow_token_in: felt,
            disable_token_in_len: felt,
            disable_token_in: felt*,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
        alloc_locals;
        if(_allow_token_in == 1){
            approve_token_list(token_in_len, token_in, Uint256(ALL_ONES, ALL_ONES));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        let (retdata_len: felt, retdata: felt*) = execute(_selector, _calldata_len, _calldata);
        if(_allow_token_in == 1){
            approve_token_list(token_in_len, token_in, Uint256(ALL_ONES, ALL_ONES));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        full_check(_drip, token_in_len, token_in, token_out_len, token_out, disable_token_in_len, disable_token_in);
        return (retdata_len, retdata,);
    }

    // @notice: Safe execute
    // @param: _token_in
    // @param: _token_out
    // @param: _allow_token_in Check if the token_in is allowed
    // @param: _disable_token_in
    // @param: _selector The selector of the function to call.
    // @param: _calldata The data to pass to the function.
    // @param: _calladata_len The length of the data.
    // @return: retdata The return data of the function call.
    // @return: retdata_len The length of the return data.
    func safe_execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            token_in_len: felt,
            token_in: felt*, 
            token_out_len: felt,
            token_out: felt*, 
            _allow_token_in: felt,
            disable_token_in_len: felt,
            disable_token_in: felt*,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
        let (retdata_len: felt, retdata: felt*) = safe_execute_drip(drip_, token_in_len, token_in, token_out_len, token_out, _allow_token_in, disable_token_in_len, disable_token_in, _selector, _calldata_len, _calldata);
        return (retdata_len, retdata,);
    }

    // @notice: Safe execute
    // @param: _token_in
    // @param: _token_out
    // @param: _allow_token_in Check if the token_in is allowed
    // @param: _disable_token_in
    // @param: _selector The selector of the function to call.
    // @param: _calldata The data to pass to the function.
    // @param: _calladata_len The length of the data.
    // @return: retdata The return data of the function call.
    // @return: retdata_len The length of the return data.
    func safe_execute_drip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt,
            token_in_len: felt,
            token_in: felt*, 
            token_out_len: felt,
            token_out: felt*, 
            _allow_token_in: felt,
            disable_token_in_len: felt,
            disable_token_in: felt*,
            _selector: felt,
            _calldata_len: felt, 
            _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
        alloc_locals;
        if(_allow_token_in == 1){
            approve_token_list(token_in_len, token_in, Uint256(ALL_ONES, ALL_ONES));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        let (retdata_len: felt, retdata: felt*) = execute(_selector, _calldata_len, _calldata);

        if(_allow_token_in == 1){
            approve_token_list(token_in_len, token_in, Uint256(0, 0));
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        full_check(_drip, token_in_len, token_in, token_out_len, token_out, disable_token_in_len, disable_token_in);
        return (retdata_len, retdata,);
    }

    // @notice: Full check
    // @param: _drip The drip 
    // @param: _token_in
    // @param: _token_out
    // @param: _disable_token_in
    func full_check{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            _drip: felt, 
            token_in_len: felt,
            token_in: felt*, 
            token_out_len: felt,
            token_out: felt*, 
            disable_token_in_len: felt,
            disable_token_in: felt*) {
        alloc_locals;
        let (drip_manager_) = drip_manager.read();
        let (caller_) = get_caller_address();
        let (drip_transit_) = drip_transit.read();
        check_and_enable_token_list(token_out_len, token_out, drip_manager_, _drip);
        disable_token_list(token_in_len, token_in, disable_token_in_len, disable_token_in, drip_manager_, _drip);

        // If caller is drip transit, it is a multicall 
        if(caller_ == drip_transit_){
           return();
        } else {
            IDripManager.fullCollateralCheck(drip_manager_, _drip);
            return();
        }
    }

    // @notice: Check and optimize enable token
    // @param: _drip The drip
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

    func approve_token_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            tokens_len: felt, tokens: felt*, amount: Uint256) {
        alloc_locals;
        if(tokens_len == 0){
            return();
        }
        approve_token(tokens[0], amount);
        return approve_token_list(tokens_len - 1, tokens + 1, amount,);
    }

    func check_and_enable_token_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            tokens_len: felt, tokens: felt*, _drip_manager: felt, _drip: felt) {
        alloc_locals;
        if(tokens_len == 0){
            return();
        }
        IDripManager.checkAndEnableToken(_drip_manager, _drip, tokens[0]);
        return check_and_enable_token_list(tokens_len - 1, tokens + 1, _drip_manager, _drip,);
    }

    func disable_token_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            tokens_len: felt, tokens: felt*, is_disable_len: felt, is_disable: felt*, _drip_manager: felt, _drip: felt) {
        alloc_locals;
        if(tokens_len == 0){
            return();
        }
        if(is_disable[0] == 0){
            return disable_token_list(tokens_len - 1, tokens + 1, is_disable_len - 1, is_disable + 1, _drip_manager, _drip,);
        } else {
            IDripManager.disableToken(_drip_manager, _drip, tokens[0]);
            return disable_token_list(tokens_len - 1, tokens + 1, is_disable_len - 1, is_disable + 1, _drip_manager, _drip,);
        }
    }

}
