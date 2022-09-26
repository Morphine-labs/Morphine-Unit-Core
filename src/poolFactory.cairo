%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
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

from src.addressRegistery import get_owner

//Storage 

@storage_var
func list(pool_len : felt) -> (pool_index: felt) {
}

@storage_var
func asset(address : felt) -> (asset : felt) {
}

@storage_var
func symbol(address : felt) -> (symbol : felt) {
}

@storage_var
func name(address : felt) -> (name : felt) {
}

@storage_var
func from_contract_class(contract_class_hash : felt) -> (address: felt) {
}

// Constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(contract_class_hash : felt, address_registery : felt){ 
    let (caller : felt) = get_caller_address();
    from_contract_class.write(contract_class_hash, address_registery);
    return();
}

// Protector 

func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (owner : felt) = addressRegistery.get_owner();
    let (caller) = get_caller_address();
    with_attr error_message("Ownable: caller is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("Ownable: caller is not the owner") {
        assert owner = caller;
    }
    return ();
}

// View

@view
func get_pool_len{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(compteur : felt) -> (pool_len : felt) {
    let (actual_pool : felt) = list.read(compteur);
    if(actual_pool == 0) {
        return(compteur,);
    }
    return get_pool_len(compteur=compteur + 1);
}

@view
func get_name {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) -> (name : felt) {
    let (actual_name : felt) = name.read(address);
    return (actual_name,);
}

@view 
func get_symbol {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) -> (symbol : felt) {
    let (actual_symbol : felt) = symbol.read(address);
    return (actual_symbol,);
}

@view 
func get_asset {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) -> (asset : felt) {
    let (actual_asset : felt) = asset.read(address);
    return (actual_asset,);
}

@view
func get_address_from_contract_class {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(contract_class_hash : felt) -> (address : felt) {
    let (actual_address : felt) = from_contract_class.read(contract_class_hash);
    return (actual_address,);
}

// External 

@external
func addPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _address_registery: felt,
        _asset : felt,
        _name : felt,
        _symbol : felt,
) {
    let (pool_len) = list.read(0);
    asset.write(_address_registery,_asset);
    symbol.write(_address_registery,_symbol);
    return();
}

@external
func removePool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _address_registery: felt,
    _asset : felt,
    _name : felt,
    _symbol : felt,
) {
    assert_only_owner();
    let (pool_len) = list.read(0);
    let (is_a_pool : felt) = already_exist(pool_len,_address_registery);
    with_attr error_message("Pool already exist") {
        assert is_a_pool = 0;
    }
    asset.write(_address_registery,0);
    symbol.write(_address_registery,0);
    return();
}