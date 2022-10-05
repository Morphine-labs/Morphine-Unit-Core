%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.IERC20 import IERC20
from src.utils.safeerc20 import SafeERC20
from src.utils.various import ALL_ONES


// Storage

@storage_var
func drip_manager() -> (drip_manager : felt){
}

@storage_var
func borrowed_amount() -> (borrowed_amount: Uint256) {
}

@storage_var
func cumulative_index() -> (borrow_info: Uint256) {
}

@storage_var
func since(asset: felt) -> (amount: Uint256) {
}

// TODO : WTF
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _drip_manager: felt,
        _borrowed_amount: Uint256,
        _cumulative_index: Uint256) {
    let (block_timestamp_) = get_block_timestamp();
    since.write(block_timestamp_);
    drip_manager.write(_drip_manager);
    borrowed_amount.write(_borrowed_amount);
    cumulative_index.write(_cumulative_index);
    return();
}

@external
func updateParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _borrowed_amount: Uint256,
        _cumulative_index: Uint256) {
    assert_only_drip_manager();
    borrowed_amount.write(_borrowed_amount);
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
        _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
    assert_only_drip_manager();
    let (retdata_len: felt, retdata: felt*) = call_contract(_to,_selector, _calldata_len, _calldata);
    return(retdata_len, retdata);
}

func assert_only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_) = get_caller_address();
    let (drip_manager_) = drip_manager.read();
    with_attr error_message("Drip: only callable by drip manger") {
        assert caller_ = drip_manager_;
    }
}