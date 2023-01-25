%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_block_number,
    call_contract,
)
from starkware.cairo.common.uint256 import ALL_ONES, Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from morphine.utils.safeerc20 import SafeERC20

/// @title Drip
/// @author 0xSacha
/// @dev Contract Isolated Smart contract holding funds and borrow parameters
/// @custom:experimental This is an experimental contract.


// Storage

@storage_var
func factory() -> (address: felt) {
}

@storage_var
func drip_manager() -> (drip_manager: felt) {
}

@storage_var
func borrowed_amount() -> (borrowed_amount: Uint256) {
}

@storage_var
func cumulative_index() -> (borrow_info: Uint256) {
}

@storage_var
func since() -> (time: felt) {
}

// @notice: Only drip manager can call this function
func assert_only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller_) = get_caller_address();
    let (drip_manager_) = drip_manager.read();
    with_attr error_message("Only drip manager can call this function") {
        assert caller_ = drip_manager_;
    }
    return ();
}

// @notice: Constructor will be called when the contract is deployed
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller_) = get_caller_address();
    factory.write(caller_);
    return ();
}

// @notice: Cumulative index 
// @return: Cumulative index
@view
func cumulativeIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    cumulativeIndex: Uint256
) {
    let (cumulative_index_: Uint256) = cumulative_index.read();
    return (cumulative_index_,);
}

// @notice: Borrowed amount
// @return: Borrowed amount
@view
func borrowedAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalBorrowed: Uint256
) {
    let (borrowed_amount_: Uint256) = borrowed_amount.read();
    return (borrowed_amount_,);
}

// @notice: Last update time
// @return: Last update time
@view
func lastUpdate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    since: felt
) {
    let (since_: felt) = since.read();
    return (since_,);
}


// External

// @notice: Drip initialize
// @param: _drip_manager_ Drip manager address
// @param: _borrowed_amount_ Borrowed amount(Uint256)
// @param: _cumulative_index_ Cumulative index(Uint256)
@external
func connectTo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip_manager: felt, _borrowed_amount: Uint256, _cumulative_index: Uint256
) {
    let (caller_) = get_caller_address();
    let (factory_) = factory.read();
    with_attr error_message("Only drip factory can call this function") {
        assert caller_ = factory_;
    }
    let (block_timestamp_: felt) = get_block_timestamp();
    since.write(block_timestamp_);
    drip_manager.write(_drip_manager);
    borrowed_amount.write(_borrowed_amount);
    cumulative_index.write(_cumulative_index);
    return ();
}

// @notice: Update paramaters
// @param: _borrowed_amount_ Borrowed amount(Uint256)
// @param: _cumulative_index_ Cumulative index(Uint256)
@external
func updateParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrowed_amount: Uint256, _cumulative_index: Uint256
) {
    assert_only_drip_manager();
    borrowed_amount.write(_borrowed_amount);
    cumulative_index.write(_cumulative_index);
    return ();
}

// @notice: Approve token
// @param: _token_ Token address
// @param: _contract Address of the contract to approve
// @param: _amount_ Amount (Uint256)
@external
func approveToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt, _contract: felt, _amount: Uint256
) {
    assert_only_drip_manager();
    IERC20.approve(_token, _contract, _amount);
    return ();
}

// @notice: Cancel Allowance
// @param: _token_ Token address
// @param: _contract Address of the contract to approve
@external
func cancelAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt, _contract: felt
) {
    assert_only_drip_manager();
    IERC20.approve(_token, _contract, Uint256(0, 0));
    return ();
}

// @notice: Safe transfer
// @param: _token Token address
// @param: _to Address to transfer to
// @param: _amount Amount (Uint256)
@external
func safeTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt, _to: felt, _amount: Uint256
) {
    assert_only_drip_manager();
    SafeERC20.transfer(_token, _to, _amount);
    return ();
}

// @notice: Execute function
// @param: _to Address to transfer to
// @param: _selector Selector
// @param: _calldata Data
// @param: _calldata_len Length of data
// @return: retdata Return data
// @return: retdata_len Length of return data
@external
func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _to: felt, _selector: felt, _calldata_len: felt, _calldata: felt*
) -> (retdata_len: felt, retdata: felt*) {
    assert_only_drip_manager();
    let (retdata_len: felt, retdata: felt*) = call_contract(
        _to, _selector, _calldata_len, _calldata
    );
    return (retdata_len, retdata);
}
