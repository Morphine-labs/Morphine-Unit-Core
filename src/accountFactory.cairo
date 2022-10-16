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

// Constants
const FALSE = 0;
const TRUE = 1;

// Storage var

@storage_var
func next_drip_account(address : felt) -> (address : felt) {
}

@storage_var
func head() -> (address: felt) {
}

@storage_var
func tail() -> (address: felt) {
}

@storage_var
func stock_len() -> (len : felt) {
}

@storage_var
func is_drip_account(address : felt) -> (is_drip_account : felt) {
}

@storage_var
func drip_from_id(address : felt) -> (drip_id : felt) {
}

@storage_var
func id_to_drip(id : felt) -> (drip : felt) {
}


@storage_var
func class_hash() -> (res: felt) {
}


@storage_var
func minning() -> (res: felt) {
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

// Constructor

@constructor
func constructor {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_class_hash : felt) {
    class_hash.write(_class_hash);
    let (drip_account : felt ) = addDripAccount();
    head.write(drip_account);
    tail.write(drip_account);
    stock_len.write(1);
    next_drip_account.write(drip_account,0);
    drip_from_id.write(1,drip_account);
    return();
}

// View


@view
func get_stock_len {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (len : felt) {
    let (stock : felt) = stock_len.read();
    return(stock,);
}

@view
func get_next_drip_account{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address : felt) -> (next_drip_account : felt) {
    let (next : felt) = next_drip_account.read(address);
    return(next,);
}

@view
func get_drip_from_address {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) -> (drip : felt) {
    let (drip_account : felt) = next_drip_account.read(address);
    return(drip_account,);
}

@view
func get_drip_from_id {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_id : felt) -> (drip : felt) {
    let (drip_account : felt) = id_to_drip.read(drip_id);
    return(drip_account,);
}

@view
func get_drip_id_from_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address : felt) -> (drip_id : felt) {
    let (drip_id : felt) = drip_from_id.read(address);
    return(drip_id,);
}

@view
func availableDripAccounts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    drip_accounts_len : felt, drip_accounts : felt*
) {
    alloc_locals;
    let (available_drip_accounts_len : felt) = stock_len.read();
    let (local available_drip_accounts: felt*) = alloc();
    complete_available_drip_accounts_tab(available_drip_accounts_len, available_drip_accounts);
    return (available_drip_accounts_len, available_drip_accounts);
}

// External

@external
func deploy_drip_account{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}() -> (contract_address : felt) {
    let current_salt = 0;
    let (class_hash_) = class_hash.read();
    let (contract_address) = deploy(
        class_hash=class_hash_,
        contract_address_salt=current_salt,
        constructor_calldata_size=1,
        constructor_calldata=cast(new (class_hash_,), felt*),
        deploy_from_zero=FALSE,
    );

    return (contract_address,);
}

@external
func addDripAccount {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (address : felt) {
    alloc_locals;
    let (stock_before : felt) = stock_len.read();
    let (old_tail : felt) = tail.read();
    let (contract_address : felt ) = get_contract_address();
    let (factory : felt ) = IRegistery.dripFactory(contract_address);
    let (new_drip : felt) = deploy_drip_account();
    IDrip.initialize(new_drip, contract_address);
    stock_len.write(stock_before + 1);
    drip_from_id.write(stock_before + 1, new_drip);
    setAvailableDripAccount(new_drip);
    next_drip_account.write(old_tail, new_drip);
    next_drip_account.write(new_drip, 0);

    tail.write(contract_address);
    is_drip_account.write(contract_address, 1);
    return(contract_address,);
}

@external
func takeDripAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_borrowed_amount: Uint256, _cumulative_index : Uint256) -> (address : felt) {
    check_stock();
    let (head_ : felt ) = head.read();
    let (tail_ : felt ) = tail.read();
    let (len_stock_ : felt) = stock_len.read();
    let (contract_address : felt ) = get_contract_address();
    let (drip_id_ : felt) = get_drip_from_id(head_);
    let (new_head : felt) = next_drip_account.read(head_);
    is_drip_account.write(head_, 0); 
    head.write(new_head);
    next_drip_account.write(head_,0);
    let (factory_ : felt) = IRegistery.dripFactory(contract_address);
    let (credit_manager : felt) = IRegistery.dripManager(contract_address);
    IDrip.connectTo(factory_, credit_manager, _borrowed_amount, _cumulative_index);
    drip_from_id.write(tail_,drip_id_);
    stock_len.write(len_stock_ - 1);
    return(head_,);
}

@external
func setAvailableDripAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) {

    let (is_drip_account_: felt) = is_drip_account.read(address);
    if (is_drip_account_ == 1) {
        return ();
    } else {
        is_drip_account.write(address, 1);
        let (drip_length : felt) = stock_len.read();
        drip_from_id.write(drip_length, address);
        stock_len.write(drip_length + 1);
        return ();
    }
}

@external
func removeAvailableDripAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_address : felt) {
    let (is_drip_account_: felt) = is_drip_account.read(_address);
    let (tail_ : felt) = tail.read();
    let (nb_drip_ : felt) = stock_len.read();
    let (old_drip_id_ : felt) = get_drip_from_address(_address);
    let (prev_tail_ : felt) = get_drip_from_id(nb_drip_ - 1);
    if (is_drip_account_ == 0) {
        return ();
    }
    if (_address == tail_) {
        stock_len.write(nb_drip_ - 1);
        is_drip_account.write(_address, 0);
        return();
    }

    id_to_drip.write(tail_, old_drip_id_);
    tail.write(prev_tail_);

    stock_len.write(nb_drip_ - 1);
    is_drip_account.write(_address, 0);
    return();

}

@external
func takeOut{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_prev : felt, _drip_account : felt, _to : felt ) {
    alloc_locals;
    only_drip_configurator();
    let (head_ : felt) = head.read();
    let (tail_ : felt ) = tail.read();
    if (head_ == _drip_account) {
        let (new_head_ : felt) = next_drip_account.read(head_);
        head.write(new_head_);
        next_drip_account.write(head_,0);
        IDrip.connectTo(_drip_account, _to, Uint256(0,0) , Uint256(0,0));
        return ();
    } 
    let (next_prev_ : felt) = next_drip_account.read(_prev);
    with_attr error_message("account not in list") {
        assert next_prev_ =  _drip_account;
    }
    if(_drip_account == tail_){
        tail.write(_prev);
        let (next_drip_account_ : felt) = next_drip_account.read(_drip_account);
        next_drip_account.write(_prev, next_drip_account_);
        next_drip_account.write(_drip_account, 0);
        IDrip.connectTo(_drip_account, _to, Uint256(0,0) , Uint256(0,0));
        removeAvailableDripAccount(_drip_account);
        return();
    } else {
        let (next_drip_account_ : felt) = next_drip_account.read(_drip_account);
        next_drip_account.write(_prev, next_drip_account_);
        next_drip_account.write(_drip_account, 0);
        IDrip.connectTo(_drip_account, _to, Uint256(0,0) , Uint256(0,0));
        removeAvailableDripAccount(_drip_account);
        return();
    }
}

@external
func returnDripAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_account : felt) {
    alloc_locals;
    let (get_block : felt) = get_block_number();
    let (is_in_drip : felt) = is_drip_account.read(drip_account); 
    with_attr error_message("account Factory: Drip account is not in the stock") {
        assert is_in_drip = 1;
    }
    let (since_ : felt) = IDrip.since(drip_account);
    let timestamp : felt = is_le(since_ , get_block);
    tempvar since_status : felt;
    if( timestamp == 1 ) {
        if ( since_ != get_block){
            since_status = 1;
        } else {
            since_status = 0;
        }
    } else {
        since_status = 0;
    }
    with_attr error_message("account Factory: Can't close in the same block") {
        assert since_status = 0;
    }

    let (tail_ : felt) = tail.read();
    next_drip_account.write(tail_, drip_account);
    tail.write(drip_account);
    next_drip_account.write(drip_account, 0);
    return();
}

@external
func get_next{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}( _address : felt) -> (next_drip : felt) {
    let (is_in_drip : felt) = is_drip_account.read(_address); 
    with_attr error_message("account Factory: Drip account is not in the stock") {
        assert is_in_drip = 1;
    }
    let (next_drip_account_ : felt) = next_drip_account.read(_address);
    return(next_drip_account_,);
}

func check_stock {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    let (head_ : felt) = head.read();
    if(head_ == 0){
        let (drip_account : felt ) = addDripAccount();
        head.write(drip_account);
        tail.write(drip_account);
        stock_len.write(1);
        return();
    }
    return();
}

func complete_available_drip_accounts_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    available_drip_accounts_len: felt, available_drip_accounts: felt*
) -> () {
    if (available_drip_accounts_len == 0) {
        return ();
    }
    let (drip_account_ : felt) = drip_from_id.read(available_drip_accounts_len - 1);
    assert available_drip_accounts[0] = drip_account_;
    return complete_available_drip_accounts_tab(
        available_drip_accounts_len=available_drip_accounts_len- 1, available_drip_accounts=available_drip_accounts + 1
    );
}