%lang starknet

from openzeppelin.access.ownable.library import Ownable

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
)

@storage_var
func governance() -> (owner : felt) {
}

@storage_var
func tresuary() -> (dao : felt) {
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