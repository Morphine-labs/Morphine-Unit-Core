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
func test_registery_change_owner_zero {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{ expect_revert(error_message="Ownable: new owner is the zero address") %}
    registery_instance.setOwner(0);
    let (admin_registery) = registery_instance.owner();
    assert admin_registery = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
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
func test_registery_change_treasury_zero {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{ expect_revert(error_message="Treasury: address is zero") %}
    registery_instance.setTreasury(0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
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
func test_registery_change_drip_factory_zero {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{ expect_revert(error_message="Drip factory: address is zero") %}
    registery_instance.setDripFactory(0);
    let (trea_registery) = registery_instance.drip_factory();
    assert trea_registery = 0 ;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
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
func test_registery_change_oracle_transit_zero {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{ expect_revert(error_message="Oracle transit: address is zero") %}
    registery_instance.setOracleTransit(0);
    let (oracle_registery) = registery_instance.oracle_transit();
    assert oracle_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_change_drip_hash {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.setDripHash(123);
    let (drip_h_registery) = registery_instance.drip_hash();
    assert drip_h_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_change_drip_hash_fail {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    registery_instance.setDripHash(123);
    return ();
}

@external
func test_registery_change_drip_hash_zero {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{ expect_revert(error_message="Drip hash: address is zero") %}
    registery_instance.setDripHash(0);
    let (drip_h_registery) = registery_instance.drip_hash();
    assert drip_h_registery = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
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

@external
func test_registery_add_pool_2{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(123);
    let (state) = registery_instance.isPool(123);
    assert state = 1;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_multiple_pool{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(1);
    registery_instance.addPool(2);
    registery_instance.addPool(3);
    registery_instance.addPool(4);
    let (nb) = registery_instance.nbPool();
    assert nb = 4;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_multiple_pool_2{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(1);
    registery_instance.addPool(2);
    registery_instance.addPool(3);
    registery_instance.addPool(4);
    let (nb) = registery_instance.isPool(1);
    assert nb = 1;

    let (nb) = registery_instance.isPool(3);
    assert nb = 1;

    let (nb) = registery_instance.isPool(2);
    assert nb = 1;

    let (nb) = registery_instance.isPool(4);
    assert nb = 1;

    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_pool_fail_2{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(123);
    let (state) = registery_instance.isPool(100);
    assert state = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_multiple_pool_fail{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(1);
    %{expect_revert(error_message="Pool: already exist") %}
    registery_instance.addPool(1);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_pool_zero {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{expect_revert(error_message="Pool: address is zero") %}
    registery_instance.addPool(0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_multiple_pool_fail_2{syscall_ptr:felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(123);
    let (state) = registery_instance.isPool(100);
    assert state = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_id_to_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(123);
    let (pool) = registery_instance.idToPool(0);
    assert pool = 123;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@external
func test_registery_id_to_pool_fail{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addPool(123);
    let (pool) = registery_instance.idToPool(1);
    assert pool = 0 ;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@external
func test_registery_ctor_drip_manager {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    let (drip_m_registery) = registery_instance.drip_manager_length();
    assert drip_m_registery = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(123);
    let (len) = registery_instance.drip_manager_length();
    assert len = 1;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_2 {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(1);
    registery_instance.addDripManager(2);
    registery_instance.addDripManager(3);
    registery_instance.addDripManager(4);
    let (len) = registery_instance.drip_manager_length();
    assert len = 4;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_3 {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(1);
    registery_instance.addDripManager(2);
    registery_instance.addDripManager(3);
    registery_instance.addDripManager(4);
    let (state) = registery_instance.isDripManager(2);
    assert state = 1;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_4 {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(1);
    registery_instance.addDripManager(2);
    registery_instance.addDripManager(3);
    registery_instance.addDripManager(4);
    let (drip) = registery_instance.idToDripManager(2);
    assert drip = 3;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_fail {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    registery_instance.setDripHash(123);
    return ();
}

@external
func test_registery_add_drip_manager_fail_2 {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(123);
    %{ expect_revert(error_message="Drip manager: already exist") %}
    registery_instance.addDripManager(123);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_fail_3 {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(123);
    let (state) = registery_instance.isDripManager(124);
    assert state = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_fail_4 {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(123);
    let (state) = registery_instance.idToDripManager(1);
    assert state = 0;
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@external
func test_registery_add_drip_manager_zero {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    %{ expect_revert(error_message="Drip manager: address is zero") %}
    registery_instance.addDripManager(0);
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

    func isPool {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(pool : felt) -> (pool : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (state) = IRegistery.isPool(registery,pool);
        return(state,);
    }

    func idToPool {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_id : felt) -> (pool: felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (pool) = IRegistery.idToPool(registery,_id);
        return(pool,);
    }

    func drip_hash {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (hash: felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (drip_hash) = IRegistery.dripHash(registery);
        return(drip_hash,);
    }

    func setDripHash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(hash: felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.setDripHash(registery,hash);
        return();
    }

    func drip_manager_length{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}()-> (len : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (len) = IRegistery.dripManagerLength(registery);
        return(len,);
    }

    func addDripManager {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_manager : felt) {
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.addDripManager(registery,_drip_manager);
        return();
    }

    func isDripManager {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip : felt) -> (state : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (state) = IRegistery.isDripManager(registery,_drip);
        return(state,);
    }

    func idToDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_id : felt) -> (dripManager : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        let (drip) = IRegistery.idToDripManager(registery,_id);
        return(drip,);
    }

}