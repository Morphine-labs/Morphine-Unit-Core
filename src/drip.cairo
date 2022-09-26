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

from openzeppelin.access.ownable.library import Ownable

@storage_var
func total_borrow(drip_id : felt) -> (total_borrow : felt) {
}

@storage_var
func collateral(drip_id: felt) -> (collateral : felt) {
}

@storage_var
func is_locked(drip_id : felt) -> (bool: felt) {
}


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_collateral : felt) {
    let (caller : felt ) = get_caller_address();
    collateral.write(0,_collateral);
    total_borrow.write(0,0);
    Ownable.initializer(caller);
    return();
}

@view
func get_collateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_id : felt) -> (collateral : felt) {
    let (collateral_ : felt) = collateral.read(drip_id); 
    return(collateral_,);
}

@view
func get_total_borrow_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_id : felt) -> (total_borrow: felt) {
    let (total_borrow_ : felt) = total_borrow.read(drip_id); 
    return(total_borrow_,);
}

@view
func get_drip_is_locked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(drip_id : felt) -> ( locked : felt){
    let (is_locked_ : felt) = is_locked.read(drip_id); 
    return(is_locked_,);
}