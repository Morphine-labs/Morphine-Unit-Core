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
func pool_factory() -> (pool_factory : felt) {
}

@storage_var
func drip_factory() -> (drip_factory : felt) {
}

@storage_var
func drip_config() -> (res: felt) {
}

@storage_var
func oracle_transit() -> (address : felt) {
}

@storage_var
func pool_hash_class() -> (pool_hash_class: felt) {
}

@storage_var
func drip_hash() -> (address : felt) {
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
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (governance : felt) {
    let (owner_) = Ownable.assert_only_owner();
    return(governance_,);
}

@view
func getTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (treasury : felt) {
    let (treasury_) = treasury.read();
    return(treasury_,);
}

@view
func poolFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (pool_factory : felt) {
    let (pool_factory_) = pool_factory.read();
    return(pool_factory_,);
}

@view
func dripFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (drip_factory : felt) {
    let (drip_factory_) = drip_factory.read();
    return(drip_factory_,);
}

@view
func dripConfigurator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (drip_factory : felt) {
    let (drip_config_) = drip_config.read();
    return(drip_config_,);
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
    let (oracle_) = oracle.read();
    return(oracle_,);
}

@view
func poolHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (pool_hash: felt) {
    let (pool_hash) = pool_hash_class.read();
    return(pool_hash,);
}

@view
func integrationManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (integrationManager: felt) {
    let (integration_manager_) = integration_manager.read();
    return(integration_manager_,);
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
func setPoolFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_treasury: felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    pool_factory.write(new_treasury);
    return();
}

@external
func setDripFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_factory: felt) {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    drip_factory.write(_drip_factory);
    return();
}


@external
func setOracle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_oracle : felt) -> () {
    with_attr error_message("Ownable: only owner can call this function") {
        assert_only_owner();
    }
    oracle.write(_new_oracle);
    return();
}

@external
func setPoolHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_pool_hash : felt) -> () {
    with_attr error_message("Ownable: only owner can call this function") { 
        assert_only_owner();
    }
    pool_hash_class.write(_new_pool_hash);
    return();
}

@external
func setIntegrationManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_integration_manager : felt) -> () {
    with_attr error_message("Ownable: only owner can call this function"){ 
        assert_only_owner();
    }
    integration_manager.write(_integration_manager);
    return();
}