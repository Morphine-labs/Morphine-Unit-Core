%lang starknet

from openzeppelin.access.ownable.library import Ownable

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
)

from starkware.cairo.common.math_cmp import is_le

/// @title: Registery
/// @author: Morphine team
/// @dev: this contract is like our registery where you can find all useful contract address
/// @custom: experimental This is an experimental contract.

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
func is_pool(address: felt) -> (is_drip_account: felt) {
}

@storage_var
func id_to_pool(id: felt) -> (drip: felt) {
}

@storage_var
func drip_managers_length() -> (len: felt) {
}

@storage_var
func is_drip_manager(address: felt) -> (is_drip_account: felt) {
}

@storage_var
func id_to_drip_manager(id: felt) -> (drip: felt) {
}

// @notice: Constructor call only once when contract is deployed
// @param: _owner: Owner of the contract
// @param: _treasury: Address of the treasury contract
// @param: _oracle_transit: Address of the oracle transit contract
// @param: _drip_hash : drip hash 
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_owner : felt, _treasuary: felt, _oracle_transit: felt, _drip_hash: felt) {
    Ownable.initializer(_owner);
    treasury.write(_treasuary);
    oracle_transit.write(_oracle_transit);
    drip_hash.write(_drip_hash);
    return();
}

// @notice: get treasury address
// @return: treasury address
@view
func getTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (treasury : felt) {
    let (treasury_) = treasury.read();
    return(treasury_,);
}

// @notice: get drip factory address
// @return: drip factory address
@view
func dripFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (drip_factory : felt) {
    let (drip_factory_) = drip_factory.read();
    return(drip_factory_,);
}

// @notice: get drip hash address
// @return: drip hash address
@view
func dripHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (drip_hash : felt) {
    let (drip_hash_) = drip_hash.read();
    return(drip_hash_,);
}

// @notice: get owner address
// @return: owner address
@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt) {
    let (owner_) = Ownable.owner();
    return(owner_,);
}

// @notice: get oracle transit address
// @return: oracle transit address
@view
func oracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (oracle : felt) {
    let (oracle_) = oracle_transit.read();
    return(oracle_,);
}

// @notice: check if address is a pool
// @param: _pool: address to check
// @return: is_pool: true if address is a pool
@view
func isPool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_pool: felt) -> (state : felt) {
    let (state_) = is_pool.read(_pool);
    return(state_,);
}

// @notice: check if address is a drip manager
// @param: _drip_manager: address to check
// @return: is_drip_manager: true if address is a drip manager
@view
func isDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_manager: felt) -> (state : felt) {
    let (state_) = is_drip_manager.read(_drip_manager);
    return(state_,);
}

// @notice: get pool address by id
// @param: _id: id of the pool
// @return: pool address
@view
func idToPool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_id: felt) -> (pool : felt) {
    let (len) = pools_length.read();
    let (pool_) = id_to_pool.read(_id);
    return(pool_,);
}

// @notice: get drip manager address by id
// @param: _id: id of the drip manager
// @return: drip manager address
@view
func idToDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_id: felt) -> (dripManager : felt) {
    let (drip_manager_) = id_to_drip_manager.read(_id);
    return(drip_manager_,);
}

// @notice: get pools length
// @return: pools length
@view
func poolsLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (poolsLength : felt) {
    let (pools_length_) = pools_length.read();
    return(pools_length_,);
}

// @notice: get drip managers length
// @return: drip managers length
@view
func dripManagerLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (dripManagerLength : felt) {
    let (drip_managers_length_) = drip_managers_length.read();
    return(drip_managers_length_,);
}

// @notice: set new owner
// @param: _newOwner: new owner address
@external
func setOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_owner : felt) {
    Ownable.assert_only_owner();
    Ownable.transfer_ownership(_new_owner);
    return();
}

// @notice: set new treasury address
// @param: _newTreasury: new treasury address
@external
func setTreasury{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_new_treasury: felt) {
    Ownable.assert_only_owner();
    with_attr error_message("Treasury: address is zero") {
        assert_not_zero(_new_treasury);
    }
    treasury.write(_new_treasury);
    return();
}

// @notice: set new drip factory address
// @param: _newDripFactory: new drip factory address
@external
func setDripFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_factory: felt) {
    Ownable.assert_only_owner();
    with_attr error_message("Drip factory: address is zero") {
        assert_not_zero(_drip_factory);
    }
    drip_factory.write(_drip_factory);
    return();
}

// @notice: set new oracle transit address
// @param: _newOracleTransit: new oracle transit address
@external
func setOracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_oracle_transit : felt) {
    Ownable.assert_only_owner();
    with_attr error_message("Oracle transit: address is zero") {
        assert_not_zero(_new_oracle_transit);
    }
    oracle_transit.write(_new_oracle_transit);
    return();
}

// @notice: set new drip hash address
// @param: _newDripHash: new drip hash address
@external
func setDripHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_drip_hash : felt) {
    Ownable.assert_only_owner();
    with_attr error_message("Drip hash: address is zero") {
        assert_not_zero(_new_drip_hash);
    }
    drip_hash.write(_new_drip_hash);
    return();
}

// @notice: add new pool
// @param: _pool: new pool address
@external
func addPool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_pool : felt)  {
    Ownable.assert_only_owner();
    let (pool_exists_) = is_pool.read(_pool);
    with_attr error_message("Pool: already exist"){
        assert pool_exists_ = 0;
    }
    with_attr error_message("Pool: address is zero"){
        assert_not_zero(_pool);
    }
    is_pool.write(_pool, 1);
    let (pools_length_) = pools_length.read();
    id_to_pool.write(pools_length_, _pool);
    pools_length.write(pools_length_ + 1);
    return();
}

// @notice: add new drip manager
// @param: _drip_manager: new drip manager address
@external
func addDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_manager : felt) {
    Ownable.assert_only_owner();
    let (drip_manager_exists_) = is_drip_manager.read(_drip_manager);
    
    with_attr error_message("already exist"){
        assert drip_manager_exists_ = 0;
    }

    with_attr error_message("address is zero"){
        assert_not_zero(_drip_manager);
    }

    is_drip_manager.write(_drip_manager, 1);
    let (drip_managers_length_) = drip_managers_length.read();
    id_to_drip_manager.write(drip_managers_length_, _drip_manager);
    drip_managers_length.write(drip_managers_length_ + 1);
    return();
}

