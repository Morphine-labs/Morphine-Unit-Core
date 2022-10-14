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
    is_not_zero
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
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from src.interfaces.IDrip import IDrip

from src.interfaces.IRegistery import IRegistery

// Storage var

@storage_var
func next_drip_account(address : felt) -> (address : felt) {
}

@storage_var
func prev_drip_account(address : felt) -> (address : felt) {
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

// Constructor

@constructor
func constructor {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) {
    with_attr error_message("account Factory: Address should be different than 0") {
        assert_not_zero(address);
    }
    let (drip_account : felt ) = addDripAccount();
    head.write(drip_account);
    tail.write(drip_account);
    stock_len.write(1);
    prev_drip_account.write(drip_account,0);
    next_drip_account.write(drip_account,0);
    drip_from_id.write(0,drip_account);
    return();
}

@view
func get_stock_len {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (len : felt) {
    let (stock : felt) = stock_len.read();
    return(stock,);
}

@view
func get_drip_from_address {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) -> (drip : felt) {
    let (drip_account : felt) = next_drip_account.read(address);
    return(drip_account,);
}

@view
func get_drip_from_id {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_id : felt) -> (drip : felt) {
    let (drip_account : felt) = drip_from_id.read(drip_id);
    return(drip_account,);
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

@external
func addDripAccount {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (address : felt) {
    alloc_locals;
    let (stock_before : felt) = stock_len.read();
    let (old_tail : felt) = tail.read();
    let (contract_address : felt ) = get_contract_address();
    let (factory : felt ) = IRegistery.dripFactory(contract_address);
    IDrip.initialize(contract_address, factory);
    stock_len.write(stock_before + 1);
    setAvailableDripAccount(contract_address);
    next_drip_account.write(old_tail, contract_address);
    prev_drip_account.write(contract_address, old_tail);
    next_drip_account.write(contract_address, 0);
    is_drip_account.write(contract_address, 1);
    return(contract_address,);
}


@external
func removeDripAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) {
    let (head_ : felt ) = head.read();
    let (tail_ : felt ) = tail.read();

    if(head_ == address) {
        let (new_head : felt) = next_drip_account.read(address);
        head.write(new_head);
        prev_drip_account.write(new_head, 0);
        next_drip_account.write(head_,0);
        return();
    }

    if(tail_ == address) {
        let (new_tail : felt) = next_drip_account.read(address);
        head.write(new_tail);
        prev_drip_account.write(new_tail, 0);
        next_drip_account.write(tail_,0);
        return();
    }

    let (prev_address : felt) = prev_drip_account.read(address);
    let (next_address : felt) = next_drip_account.read(address);
    next_drip_account.write(address, 0);
    prev_drip_account.write(address,0);

    next_drip_account.write(prev_address, next_address);
    prev_drip_account.write(next_address,prev_address);
    return();
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
func removeAvailableDripAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) {
    
    let (is_drip_account_: felt) = is_drip_account.read(address);
    if (is_drip_account_ == 0) {
        return ();
    } else {
        is_drip_account.write(address, 0);
        let (drip_length : felt) = stock_len.read();
        drip_from_id.write(drip_length, 0);
        stock_len.write(drip_length - 1);
        return ();
    }
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