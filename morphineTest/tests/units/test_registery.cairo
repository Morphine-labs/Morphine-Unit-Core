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

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.drip_hash]).contract_address 
        context.registery = ids.registery

        stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ]
        [stop_prank() for stop_prank in stop_pranks]
    %}
    
    return();
}

@external
func test_registery_constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (admin_registery) = registery_instance.owner();
    assert admin_registery = ADMIN;
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
}