%lang starknet

from openzeppelin.access.ownable.library import Ownable

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
)

const EMPIRIC_ORACLE_ADDRESS = 0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4;

@storage_var
func governance() -> (owner : felt) {
}

@storage_var
func tresuary() -> (dao : felt) {
}

@storage_var
func oracle() -> (address : felt) {
}

@storage_var
func pool_hash_class(pool_name : felt) -> (res: felt) {
}

@storage_var
func morphine_pool_hash(pool_hash_class : felt) -> (token_address : felt){
}

func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (owner) = Ownable.owner();
    let (caller) = get_caller_address();
    with_attr error_message("Ownable: caller is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("Ownable: caller is not the owner") {
        assert owner = caller;
    }
    return ();
}

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(governance : felt) {
    Ownable.initializer(governance);
    oracle.write(EMPIRIC_ORACLE_ADDRESS);
    return();
}

@view
func get_governance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (governance : felt) {
    let (governance_) = governance.read();
    return(governance_,);
}

@view
func get_tresuary{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (tresuary : felt) {
    let (tresuary_) = tresuary.read();
    return(tresuary_,);
}

@view
func get_oracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (oracle : felt) {
    let (oracle_) = oracle.read();
    return(oracle_,);
}

@view
func get_pool_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(pool_name : felt) -> (pool_hash: felt) {
    let (pool_hash) = pool_hash_class.read(pool_name);
    return(pool_hash,);
}

@view
func get_morphine_pool_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(pool_hash_class : felt) -> (pool_hash: felt) {
    let (pool_hash) = morphine_pool_hash.read(pool_hash_class);
    return(pool_hash,);
}

@external
func set_new_governance_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_governance : felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    Ownable.transfer_ownership(new_governance);
    governance.write(new_governance);
    return();
}

@external
func set_new_tresuary_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_tresuary: felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    tresuary.write(new_tresuary);
    return();
}

@external
func set_oracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_oracle : felt) -> () {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    oracle.write(new_oracle);
    return();
}

@external
func set_pool_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(pool_name : felt, new_pool_hash : felt) -> () {
    pool_hash_class.write(pool_name,new_pool_hash);
    return();
}

@view
func set_morphine_pool_hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(pool_hash_class : felt, new_token_address : felt) -> () {
    morphine_pool_hash.write(pool_hash_class,new_token_address);
    return();
}