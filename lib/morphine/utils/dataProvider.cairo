// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from morphine.interfaces.IFaucet import IFaucet


/// @title: Data Provider
/// @author: Graff Sacha (0xSacha)
/// @dev: Helper conract to get useful data from Morphine
/// @custom:experimental This is an experimental contract. LP Pricing to think.

struct FaucetInfo {
    token_address: felt,  
    user_balance: Uint256,  
    remaining_time: felt,
}

//
// Getters
//

// @notice: Get the token address
// @return: Token address
@view
func getFaucetInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, faucet_array_len: felt, faucet_array: felt*) -> (
    faucetInfo_len: felt, faucetInfo: FaucetInfo*
) {
    alloc_locals;
    let (faucet_info: FaucetInfo*) = alloc();
    recursive_faucet_info(_user, faucet_array_len, faucet_array, faucet_info);
    return (faucet_array_len, faucet_info,);
}


func recursive_faucet_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, faucet_array_len: felt, faucet_array: felt*, faucet_info: FaucetInfo*) {
    alloc_locals;
    if(faucet_array_len == 0){
        return();
    }
    let (token_address_) = IFaucet.get_token_address(faucet_array[0]);
    assert faucet_info[0].token_address = token_address_;

    let (user_balance_) = IERC20.balanceOf(token_address_, _user);
    assert faucet_info[0].user_balance = user_balance_;

    let (state_) = IFaucet.isAllowedForTransaction(faucet_array[0], _user);

    if(state_ == 1){
        assert faucet_info[0].remaining_time = 0;
        return recursive_faucet_info(_user, faucet_array_len - 1, faucet_array + 1, faucet_info + FaucetInfo.SIZE);
    }   else {
        let (allowed_time_) = IFaucet.get_allowed_time(faucet_array[0], _user);
        let (block_timestamp_) = get_block_timestamp();
        let remaining_time_ = allowed_time_ - block_timestamp_;
        assert faucet_info[0].remaining_time = remaining_time_;
        return recursive_faucet_info(_user, faucet_array_len - 1, faucet_array + 1, faucet_info + FaucetInfo.SIZE);
    }
}
