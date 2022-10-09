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

from src.IRegistery import IRegistery

from src.Pool.IPoolFactory import PoolFactory

//Storage 

@storage_var
func registery() -> (address: felt) {
}

@storage_var
func nb_pool() -> (len: felt) {
}

@storage_var
func asset(pool_id : felt) -> (asset : felt) {
}

@storage_var
func symbol(pool_id : felt) -> (symbol : felt) {
}

@storage_var
func name(pool_id: felt) -> (name : felt) {
}

@storage_var
func pool_by_id(pool_id : felt) -> (pool : PoolFactory)  {
}

@storage_var
func from_contract_class(contract_class_hash : felt) -> (address: felt) {
}

@storage_var
func is_available_asset(assetAddress: felt) -> (is_asset_available: felt) {
}

@storage_var
func id_to_available_asset(id: felt) -> (available_asset: felt) {
}

// Constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(contract_class_hash : felt, address_registery : felt,){ 
    let (caller : felt) = get_caller_address();
    from_contract_class.write(contract_class_hash, address_registery);
    return();
}

// Protector 

func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (registery_contract) = registery.read();
    let (owner : felt) = IRegistery.owner(registery_contract);
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
func get_nb_pool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (pool_len : felt) {
    let (nb : felt) = nb_pool.read();
    return(nb,);
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

@view
func get_pool_by_id {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pool_id : felt) -> (pool_name:felt, pool_symbol : felt, pool_asset : felt) {
    let (pool : PoolFactory) = pool_by_id.read(pool_id);
    return (pool.name, pool.symbol, pool.asset);
}

@view
func get_pool_factory_by_id {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pool_id : felt) -> (pool : PoolFactory) {
    let (actual_pool : PoolFactory) = pool_by_id.read(pool_id);
    return (actual_pool,);
}

@view
func availablePools{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    available_pools_len : felt, available_pools : felt*
) {
    alloc_locals;
    let (local available_pools_len : felt) = nb_pool.read();
    let (local available_pools: felt*) = alloc();
    complete_available_pools_tab(available_pools_len , available_pools);
    return (available_pools_len, available_pools);
}

@view
func isAvailableAsset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    asset: felt
) -> (is_available_asset: felt) {
    let (is_available_asset_) = is_available_asset.read(asset);
    return (is_available_asset_,);
}

// External 

@external
func addPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _address_registery: felt,
        _asset : felt,
        _name : felt,
        _symbol : felt,
) {

    assert_only_owner();
    let (actual_pool_number : felt) = nb_pool.read();
    name.write(actual_pool_number, _name);
    asset.write(actual_pool_number, _asset);
    symbol.write(actual_pool_number, _symbol);
    setAvailablePool(_asset);
    return();
}

// # Internal
func complete_available_pools_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    available_pools_len: felt, available_pools: felt*
) -> () {
    if (available_pools_len == 0) {
        return ();
    }
    let (asset_: felt) = get_asset(available_pools_len - 1);
    assert available_pools[0] = asset_;
    return complete_available_pools_tab(
        available_pools_len=available_pools_len - 1, available_pools=available_pools + 1
    );
}

func setAvailablePool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    asset: felt
) {
    let (is_available_asset_: felt) = is_available_asset.read(asset);
    if (is_available_asset_ == 1) {
        return ();
    } else {
        is_available_asset.write(asset, 1);
        let (available_assets_len : felt) = nb_pool.read();
        id_to_available_asset.write(available_assets_len, asset);
        nb_pool.write(available_assets_len + 1);
        return ();
    }
}
