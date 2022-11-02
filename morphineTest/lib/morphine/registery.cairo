%lang starknet

from openzeppelin.access.ownable.library import Ownable

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
)

@storage_var
func treasury() -> (treasury : felt) {
}

@storage_var
func drip_factory() -> (drip_factory : felt) {
}

@storage_var
func oracle_transit() -> (address : felt) {
}

@storage_var
func drip_hash() -> (address : felt) {
}

@storage_var
func pools_length() -> (len: felt) {
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
func drip_length() -> (len: felt) {
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
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_owner : felt, _treasuary: felt, _oracle_transit: felt, _drip_hash: felt) {
    Ownable.initializer(_owner);
    treasury.write(_treasuary);
    oracle_transit.write(_oracle_transit);
    drip_hash.write(_drip_hash);
    return();
}


@view
func getTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (treasury : felt) {
    let (treasury_) = treasury.read();
    return(treasury_,);
}

@view
func dripFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (drip_factory : felt) {
    let (drip_factory_) = drip_factory.read();
    return(drip_factory_,);
}

@view
func dripHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (drip_hash : felt) {
    let (drip_hash_) = drip_hash.read();
    return(drip_hash_,);
}

@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt) {
    let (owner_) = Ownable.owner();
    return(owner_,);
}

@view
func oracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (oracle : felt) {
    let (oracle_) = oracle_transit.read();
    return(oracle_,);
}



@external
func setOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_owner : felt) {
    Ownable.assert_only_owner();
    Ownable.transfer_ownership(_new_owner);
    return();
}

@external
func setTreasury{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_treasury: felt) {
    Ownable.assert_only_owner();
    treasury.write(_new_treasury);
    return();
}


@external
func setDripFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_factory: felt) {
    Ownable.assert_only_owner();
    drip_factory.write(_drip_factory);
    return();
}


@external
func setOracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_oracle_transit : felt) -> () {
    Ownable.assert_only_owner();
    oracle_transit.write(_new_oracle_transit);
    return();
}

@external
func setDripHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_drip_hash : felt) -> () {
    Ownable.assert_only_owner();
    drip_hash.write(_new_drip_hash);
    return();
}