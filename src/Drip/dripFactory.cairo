%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.math_cmp import ( 
    is_le,
    is_nn,
    is_not_zero,
)

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
from src.utils.utils import (
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

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from src.interfaces.IDrip import IDrip

from src.interfaces.IRegistery import IRegistery


@event 
func NewDrip(drip: felt){
}

@event 
func DripTaken(drip: felt, caller: felt){
}

@event 
func DripReturned(drip: felt){
}

@event 
func DripTakenForever(drip: felt, caller: felt){
}

// Storage var

@storage_var
func next_drip(address : felt) -> (address : felt) {
}

@storage_var
func head() -> (address: felt) {
}

@storage_var
func tail() -> (address: felt) {
}

@storage_var
func drip_length() -> (len : felt) {
}

@storage_var
func is_drip(address : felt) -> (is_drip_account : felt) {
}

@storage_var
func id_to_drip(id : felt) -> (drip : felt) {
}

@storage_var
func drip_to_id(address : felt) -> (drip_id : felt) {
}

@storage_var
func registery() -> (res: felt) {
}


// Protector

func only_drip_configurator {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    let (contract_address : felt) = get_contract_address();
    let (caller_ : felt ) = get_caller_address();
    let (config : felt) = IRegistery.dripConfig(contract_address);
    with_attr error_message("account factory : Caller is not dripConfigurator") {
        assert config = caller_;
    }
    return();
}

func only_drip_manager {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    let (contract_address : felt) = get_contract_address();
    let (caller_ : felt ) = get_caller_address();
    let (manager : felt) = IRegistery.dripManager(contract_address);
    with_attr error_message("account factory : Caller is not dripManager") {
        assert manager = caller_;
    }
    return();
}



// Constructor

@constructor
func constructor {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery : felt) {
    with_attr error_message("zero address") {
        assert_not_zero(_registery);
    }
    registery.write(_registery);
    let (owner_) = IRegistery.owner(_registery);
    Ownable.initializer(owner_);
    addDrip();
    let (tail_) = tail.read();
    head.write(tail_);
    next_drip.write(0, 0);
    return();
}

// View

@view
func nextDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip : felt) -> (drip : felt) {
    let (next_) = next_drip.read(_drip);
    return(next_,);
}

@view
func dripLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (dripLength : felt) {
    let (drip_length_) = drip_length.read();
    return(drip_length_,);
}

@view
func idToDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_id: felt) -> (drip : felt) {
    let (drip_) = id_to_drip.read(_id);
    return(drip_,);
}

@view
func dripToId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (id : felt) {
    let (id_) = drip_to_id.read(_drip);
    return(id_,);
}

@view
func isDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (state : felt) {
    let (state_) = is_drip.read(_drip);
    return(state_,);
}

@view
func dripStockLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (length : felt) {
    let (head_) = head.read();
    let (tail_) = tail.read();
    let (length_) = recursive_stock_length(head_, tail_, 0);
    let (drip_) = id_to_drip.read(length_);
    let (state_) = is_drip.read(drip_);
    return(state_,);
}



@external
func addDrip {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () {
    alloc_locals;
    let (this_ : felt ) = get_contract_address();
    let (new_drip_ : felt) = deploy_drip_account();
    IDrip.initialize(new_drip_, this_);
    let (tail_ : felt) = tail.read();
    next_drip.write(tail_, new_drip_);
    tail.write(new_drip_);
    let (drip_length_ : felt) = drip_length.read();
    id_to_drip.write(drip_length_, new_drip_);
    drip_to_id.write(new_drip_, drip_length_);
    is_drip.write(new_drip_, 1);
    drip_length.write(drip_length_ + 1);
    NewDrip.emit(new_drip_);
    return();
}

@external
func takeDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_borrowed_amount: Uint256, _cumulative_index : Uint256) -> (address : felt) {
    alloc_locals;
    only_drip_manager();
    check_stock();
    let (caller_) = get_caller_address();
    let (drip_ : felt ) = head.read();
    let (next_) = next_drip.read(drip_);
    head.write(next_);
    next_drip.write(drip_, 0);
    IDrip.connectTo(drip_, caller_, _borrowed_amount, _cumulative_index);
    DripTaken.emit(drip_, caller_);
    return(drip_,);
}

@external
func returnDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_used_drip : felt) {
    alloc_locals;
    only_drip_manager();
    let (is_drip_) = is_drip.read(_used_drip);
    with_attr error_message("external drips forbidden") {
        assert is_drip_ = 1;
    }
    let (since_) = IDrip.since(_used_drip);
    let (block_timestamp_) = get_block_timestamp();
    with_attr error_message("external drips forbidden") {
        assert_not_zero(block_timestamp_ - since_);
    }
    let (tail_) = tail.read();
    next_drip.write(tail_, _used_drip);
    tail.write(_used_drip);
    DripReturned.emit(_used_drip);
    return();
}


@external
func takeOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_prev : felt, _drip : felt, _to : felt ) {
    alloc_locals;
    only_drip_configurator();
    check_stock();
    let (head_ : felt) = head.read();
    if (head_ == _drip){
        let (new_head_ : felt) = next_drip.read(head_);
        head.write(new_head_);
        next_drip.write(head_,0);
        return ();
    } 

    let (next_prev_) = next_drip.read(_prev);
    with_attr error_message("account not in stock") {
        assert next_prev_ =  _drip;
    }
    let (tail_) = tail.read();
    if(_drip == tail_){
        tail.write(_prev);
            
        IDrip.connectTo(_drip, _to, Uint256(0,0) , Uint256(0,0));
        let (length_) = drip_length.read();
        let (last_drip_) = id_to_drip.read(length_ - 1);
        let (drip_to_remove_id_) = drip_to_id.read(_drip);
        id_to_drip.write(drip_to_remove_id_, last_drip_);
        id_to_drip.write(length_ - 1, 0);
        drip_to_id.write(last_drip_, drip_to_remove_id_);
        drip_to_id.write(_drip, 0);
        is_drip.write(_drip, 0);
        drip_length.write(length_ - 1);
        DripTakenForever.emit(_drip, _to);
        return ();
    } else {
        let (next_drip_) = next_drip.read(_drip);
        next_drip.write(_prev, next_drip_);
        next_drip.write(_drip, 0);
        IDrip.connectTo(_drip, _to, Uint256(0,0) , Uint256(0,0));
        let (length_) = drip_length.read();
        let (last_drip_) = id_to_drip.read(length_ - 1);
        let (drip_to_remove_id_) = drip_to_id.read(_drip);
        id_to_drip.write(drip_to_remove_id_, last_drip_);
        id_to_drip.write(length_ - 1, 0);
        drip_to_id.write(last_drip_, drip_to_remove_id_);
        drip_to_id.write(_drip, 0);
        is_drip.write(_drip, 0);
        drip_length.write(length_ - 1);
        DripTakenForever.emit(_drip, _to);
        return ();
    }
}




// Internals 


func deploy_drip_account{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (contract_address : felt) {
    let (registery_) = registery.read();    
    let (class_hash_) = IRegistery.dripHash(registery_);
    let (call_data_ ) = alloc();
    let (contract_address_) = deploy(class_hash_, 0, 0, call_data_, 0);
    return (contract_address_,);
}

func check_stock {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    let (head_ : felt) = head.read();
    let (next_head_) = next_drip.read(head_);
    if(next_head_ == 0){
        addDrip();
        return();
    }
    return();
}

func recursive_stock_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_temp_head: felt, _tail: felt, _count: felt) -> (count : felt) {
    if (_temp_head == _tail){
        return(_count,);
    }
    let (next_head_) = next_drip.read(_temp_head);
    return recursive_stock_length(next_head_, _tail, _count);
}
