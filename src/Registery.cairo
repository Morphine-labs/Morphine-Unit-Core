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
func treasury() -> (dao : felt) {
}

@storage_var
func pool_factory() -> (dao : felt) {
}

@storage_var
func oracle() -> (address : felt) {
}

@storage_var
func pool_hash_class() -> (res: felt) {
}

@storage_var
func morphine_pool_hash() -> (token_address : felt){
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
func getGovernance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (governance : felt) {
    let (governance_) = governance.read();
    return(governance_,);
}

@view
func getTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (treasury : felt) {
    let (treasury_) = treasury.read();
    return(treasury_,);
}

@view
func getPoolFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (pool_factory : felt) {
    let (pool_factory_) = pool_factory.read();
    return(pool_factory_,);
}



@view
func getOracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (oracle : felt) {
    let (oracle_) = oracle.read();
    return(oracle_,);
}

@view
func getPoolHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (pool_hash: felt) {
    let (pool_hash) = pool_hash_class.read();
    return(pool_hash,);
}

@view
func getMorphinePoolHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (pool_hash: felt) {
    let (pool_hash) = morphine_pool_hash.read();
    return(pool_hash,);
}

@external
func setGovernanceAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_governance : felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    Ownable.transfer_ownership(new_governance);
    governance.write(new_governance);
    return();
}

@external
func setTreasuryAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_treasury: felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    treasury.write(new_treasury);
    return();
}

@external
func setPoolFactory_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_treasury: felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    pool_factory.write(new_treasury);
    return();
}


@external
func setOracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_oracle : felt) -> () {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    oracle.write(new_oracle);
    return();
}

@external
func setPoolHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_pool_hash : felt) -> () {
    pool_hash_class.write(new_pool_hash);
    return();
}

@view
func setMorphinePoolHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_token_address : felt) -> () {
    morphine_pool_hash.write(new_token_address);
    return();
}