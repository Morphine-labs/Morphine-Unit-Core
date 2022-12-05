%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.math_cmp import is_le, is_nn, is_not_zero

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
from morphine.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import deploy
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero


from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from morphine.utils.RegisteryAccess import RegisteryAccess
from morphine.interfaces.IDrip import IDrip
from morphine.interfaces.IRegistery import IRegistery



@event
func NewDrip(drip: felt) {
}

@event
func DripTaken(drip: felt, caller: felt) {
}

@event
func DripReturned(drip: felt) {
}

@event
func DripTakenForever(drip: felt, caller: felt) {
}

// Storage var

@storage_var
func next_drip(address: felt) -> (address: felt) {
}

@storage_var
func head() -> (address: felt) {
}

@storage_var
func tail() -> (address: felt) {
}

@storage_var
func drips_length() -> (len: felt) {
}

@storage_var
func is_drip(address: felt) -> (is_drip_account: felt) {
}

@storage_var
func id_to_drip(id: felt) -> (drip: felt) {
}

@storage_var
func drip_to_id(address: felt) -> (drip_id: felt) {
}


@storage_var
func salt() -> (res: felt) {
}


// Protector

// @notice: only_drip_manager
// @dev: check if caller is drip manager
func only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (registery_) = RegisteryAccess.registery();
    let (caller_: felt) = get_caller_address();
    let (state_: felt) = IRegistery.isDripManager(registery_, caller_);
    with_attr error_message("caller is not a drip manager") {
        assert state_ = 1;
    }
    return ();
}

// Constructor

// @notice: Drip Factory Constructor
// @param: _registery Registery (felt)
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _registery: felt
) {
    with_attr error_message("zero address") {
        assert_not_zero(_registery);
    }
    RegisteryAccess.initializer(_registery);
    addDrip();
    let (tail_) = tail.read();
    head.write(tail_);
    next_drip.write(0, 0);
    return ();
}

// View

// @notice: Next Drip
// @param: _drip Drip (felt)
// @return: drip Next Drip (felt)
@view
func nextDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (
    drip: felt
) {
    let (next_) = next_drip.read(_drip);
    return (next_,);
}

// @notice: Drip Length
// @return: dripLength Total Drip Length  (felt)
@view
func dripsLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    dripLength: felt
) {
    let (drip_length_) = drips_length.read();
    return (drip_length_,);
}

// @notice: ID To Drip
// @param: _id Drip ID (felt)
// @return: drip Drip (felt)
@view
func idToDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_id: felt) -> (
    drip: felt
) {
    let (drip_) = id_to_drip.read(_id);
    return (drip_,);
}

// @notice: Drip To ID
// @param: _drip Drip (felt)
// @return: id Drip ID (felt)
@view
func dripToId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (
    id: felt
) {
    let (id_) = drip_to_id.read(_drip);
    return (id_,);
}

// @notice: Is Drip
// @param: _drip Drip (felt)
// @return: state 1 if is Drip, 0 else (felt)
@view
func isDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (
    state: felt
) {
    let (state_) = is_drip.read(_drip);
    return (state_,);
}

// @notice: Drip Stock Length
// @dev: Unused drip are stored to save gas for new Drip
// @return: length Drip Stock Length (felt)
@view
func dripStockLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    length: felt
) {
    let (head_) = head.read();
    let (tail_) = tail.read();
    let (length_) = recursive_stock_length(head_, tail_, 0);
    return (length_,);
}

// @notice: add Drip
// @dev: Deploy a new Drip
@external
func addDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (new_drip_: felt) = deploy_drip_account();
    let (tail_: felt) = tail.read();
    next_drip.write(tail_, new_drip_);
    tail.write(new_drip_);
    let (drip_length_: felt) = drips_length.read();
    id_to_drip.write(drip_length_, new_drip_);
    drip_to_id.write(new_drip_, drip_length_);
    is_drip.write(new_drip_, 1);
    drips_length.write(drip_length_ + 1);
    NewDrip.emit(new_drip_);
    return ();
}

// @notice: Take Drip
// @dev: Function Used by Drip Manager for new borrower
// @param: _borrowed_amount Borrowed Amount (Uint256)
// @param: _cumulative_index Cumulative Index (Uint256)
// @return: address Drip Address (felt)
@external
func takeDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrowed_amount: Uint256, _cumulative_index: Uint256
) -> (address: felt) {
    alloc_locals;
    only_drip_manager();
    check_stock();
    let (caller_) = get_caller_address();
    let (drip_: felt) = head.read();
    let (next_) = next_drip.read(drip_);
    head.write(next_);
    next_drip.write(drip_, 0);
    IDrip.connectTo(drip_, caller_, _borrowed_amount, _cumulative_index);
    DripTaken.emit(drip_, caller_);
    return (drip_,);
}

// @notice: Return Drip
// @dev: Function Used by Drip Manager when closing Drip
// @param: _used_drip Used Drip (felt)
@external
func returnDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_used_drip: felt) {
    alloc_locals;
    only_drip_manager();
    let (is_drip_) = is_drip.read(_used_drip);
    with_attr error_message("external drips forbidden") {
        assert is_drip_ = 1;
    }
    let (since_) = IDrip.lastUpdate(_used_drip);
    let (block_timestamp_) = get_block_timestamp();
    with_attr error_message("can not return drip in the same block") {
        assert_not_zero(block_timestamp_ - since_);
    }
    let (tail_) = tail.read();
    next_drip.write(tail_, _used_drip);
    tail.write(_used_drip);
    DripReturned.emit(_used_drip);
    return ();
}

// @notice: Take Out
// @dev: Function Used by the Admin to Remove a bad Drip
// @param: _prev Previous Drip (felt)
// @param: _drip Drip to remove (felt)
// @param: _to Address to connect Drip (felt)
@external
func takeOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _prev: felt, _drip: felt, _to: felt
) {
    alloc_locals;
    RegisteryAccess.assert_only_owner();
    check_stock();
    let (head_: felt) = head.read();
    if (head_ == _drip) {
        let (new_head_: felt) = next_drip.read(head_);
        head.write(new_head_);
        next_drip.write(head_, 0);
        IDrip.connectTo(_drip, _to, Uint256(0, 0), Uint256(0, 0));
        let (length_) = drips_length.read();
        let (last_drip_) = id_to_drip.read(length_ - 1);
        let (drip_to_remove_id_) = drip_to_id.read(_drip);
        id_to_drip.write(drip_to_remove_id_, last_drip_);
        id_to_drip.write(length_ - 1, 0);
        drip_to_id.write(last_drip_, drip_to_remove_id_);
        drip_to_id.write(_drip, 0);
        is_drip.write(_drip, 0);
        drips_length.write(length_ - 1);
        DripTakenForever.emit(_drip, _to);
        return ();
    }

    with_attr error_message("zero address") {
        assert_not_zero(_drip);
    }

    let (next_prev_) = next_drip.read(_prev);
    with_attr error_message("account not in stock") {
        assert next_prev_ = _drip;
    }
    let (tail_) = tail.read();
    if (_drip == tail_) {
        tail.write(_prev);
        next_drip.write(_prev, 0);
        IDrip.connectTo(_drip, _to, Uint256(0, 0), Uint256(0, 0));
        let (length_) = drips_length.read();
        let (last_drip_) = id_to_drip.read(length_ - 1);
        let (drip_to_remove_id_) = drip_to_id.read(_drip);
        id_to_drip.write(drip_to_remove_id_, last_drip_);
        id_to_drip.write(length_ - 1, 0);
        drip_to_id.write(last_drip_, drip_to_remove_id_);
        drip_to_id.write(_drip, 0);
        is_drip.write(_drip, 0);
        drips_length.write(length_ - 1);
        DripTakenForever.emit(_drip, _to);
        return ();
    } else {
        let (next_drip_) = next_drip.read(_drip);
        next_drip.write(_prev, next_drip_);
        next_drip.write(_drip, 0);
        IDrip.connectTo(_drip, _to, Uint256(0, 0), Uint256(0, 0));
        let (length_) = drips_length.read();
        let (last_drip_) = id_to_drip.read(length_ - 1);
        let (drip_to_remove_id_) = drip_to_id.read(_drip);
        id_to_drip.write(drip_to_remove_id_, last_drip_);
        id_to_drip.write(length_ - 1, 0);
        drip_to_id.write(last_drip_, drip_to_remove_id_);
        drip_to_id.write(_drip, 0);
        is_drip.write(_drip, 0);
        drips_length.write(length_ - 1);
        DripTakenForever.emit(_drip, _to);
        return ();
    }
}

// Internals

// @notice: deploy_drip_account 
// @return: contract_address Drip Deployed Address (felt)
func deploy_drip_account{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    contract_address: felt
) {
    let (registery_) = RegisteryAccess.registery();
    let (class_hash_) = IRegistery.dripHash(registery_);
    let (call_data_) = alloc();
    let (salt_) = salt.read();
    let (contract_address_) = deploy(class_hash_, salt_, 0, call_data_, 0);
    salt.write(salt_ + 1);
    return (contract_address_,);
}


// @notice: check_stock
// @dev: Check for eventuals Drips in Stock and deploy if nothing is stock
func check_stock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (head_: felt) = head.read();
    let (next_head_) = next_drip.read(head_);
    if (next_head_ == 0) {
        addDrip();
        return ();
    }
    return ();
}

// @notice: recursive_stock_length 
// @dev: Calculate Drip Stock Length
// @param: _temp_head Temp Head (felt)
// @param: _tail Drip Tail (felt)
// @param: _count Drip Cumulative Count (felt)
// @return: count Drip Stock Length (felt)
func recursive_stock_length{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _temp_head: felt, _tail: felt, _count: felt
) -> (count: felt) {
    if (_temp_head == 0) {
        return (_count,);
    }
    let (next_head_) = next_drip.read(_temp_head);
    return recursive_stock_length(next_head_, _tail, _count + 1);
}
