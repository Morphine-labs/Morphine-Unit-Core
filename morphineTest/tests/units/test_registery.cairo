%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_block_number

const ADMIN = 'morphine-admin';
const TREASURY = 'morphine_treasyury';
const ORACLE_TRANSIT = 'oracle_transit';

from morphine.interfaces.IDrip import IDrip
from morphine.interfaces.IRegistery import IRegistery

@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar registery;
    tempvar drip_hash;

    %{

        ids.drip_hash = declare("./lib/morphine/drip/drip.cairo").class_hash
        context.drip_hash = ids.drip_hash

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY , ids.ORACLE_TRANSIT, ids.drip_hash]).contract_address 
        context.registery = ids.registery

        stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ]
        [stop_prank() for stop_prank in stop_pranks]
    %}
    
    return();
}

@external
func test_registery_ctor_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (admin_registery) = registery_instance.owner();
    assert admin_registery = ADMIN;
    return ();
}

@external
func test_registery_change_owner {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.setOwner(123);
    let (admin_registery) = registery_instance.owner();
    assert admin_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_change_owner_fail {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    registery_instance.setOwner(123);
    let (admin_registery) = registery_instance.owner();
    assert admin_registery = 123;
    return ();
}

@external
func test_registery_ctor_tresuary {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (tresuary_registery) = registery_instance.treasury();
    assert tresuary_registery = TREASURY;
    return ();
}

@external
func test_registery_change_treasury {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.setTreasury(123);
    let (tres_registery) = registery_instance.treasury();
    assert tres_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_change_treasury_fail {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    registery_instance.setTreasury(123);
    let (trea_registery) = registery_instance.treasury();
    assert trea_registery = 123;
    return ();
}

@external
func test_registery_ctor_drip_factory {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (drip_registery) = registery_instance.drip_factory();
    assert drip_registery = 0;
    return ();
}

@external
func test_registery_change_drip_factory {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.setDripFactory(123);
    let (drip_registery) = registery_instance.drip_factory();
    assert drip_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_change_drip_factory_fail {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    registery_instance.setDripFactory(123);
    let (trea_registery) = registery_instance.drip_factory();
    assert trea_registery = 123;
    return ();
}

@external
func test_registery_ctor_oracle_transit {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (drip_registery) = registery_instance.oracle_transit();
    assert drip_registery = ORACLE_TRANSIT;
    return ();
}

@external
func test_registery_change_oracle_transit {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.setOracleTransit(123);
    let (oracle_registery) = registery_instance.oracle_transit();
    assert oracle_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_change_oracle_transit_fail {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    registery_instance.setOracleTransit(123);
    let (oracle_registery) = registery_instance.oracle_transit();
    assert oracle_registery = 123;
    return ();
}

@external
func test_registery_ctor_pool{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    let (len) = registery_instance.nbPool();
    assert len = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_pool{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(123);
    let (len) = registery_instance.nbPool();
    assert len = 1;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

namespace registery_instance {

    func deployed() -> (registery : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        return (registery,);
    }

    func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner_ : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (owner) = IRegistery.owner(registery);
        return(owner,);
    }

    func setOwner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_owner : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.setOwner(registery,new_owner);
        return();
    }

    func treasury {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (tresuary : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (tres) = IRegistery.getTreasury(registery);
        return(tres,);
    }

    func setTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_tres : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.setTreasury(registery,new_tres);
        return();
    }

    func drip_factory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (tresuary : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (drip) = IRegistery.dripFactory(registery);
        return(drip,);
    }

    func setDripFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_drip : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.setDripFactory(registery,new_drip);
        return();
    }

    func oracle_transit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (tresuary : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (drip) = IRegistery.oracleTransit(registery);
        return(drip,);
    }

    func setOracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_oracle : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.setOracleTransit(registery,new_oracle);
        return();
    }

    func nbPool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (pool : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (nb) = IRegistery.poolsLength(registery);
        return (nb,);
    }

    func addPool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(pool : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.addPool(registery,pool);
        return ();
    }
}