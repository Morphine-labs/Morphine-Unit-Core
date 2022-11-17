%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_block_number
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc


// OpenZeppelin dependencies
from openzeppelin.token.erc20.IERC20 import IERC20

// Project dependencies
from morphine.interfaces.IDripConfigurator import AllowedToken

from morphine.interfaces.IPool import IPool
from morphine.interfaces.IEmpiricOracle import IEmpiricOracle
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IDripInfraFactory import IDripInfraFactory
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IERC4626 import IERC4626
from morphine.utils.utils import pow



@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    tempvar drip_infra_factory;
    tempvar drip_manager_hash;
    tempvar drip_transit_hash;
    tempvar drip_configurator_hash;
    


    %{
        ids.drip_manager_hash = declare("./lib/morphine/drip/dripManager.cairo").class_hash
        context.drip_manager_hash = ids.drip_manager_hash

        ids.drip_transit_hash = declare("./lib/morphine/drip/dripTransit.cairo").class_hash
        context.drip_transit_hash = ids.drip_transit_hash

        ids.drip_configurator_hash = declare("./lib/morphine/drip/dripConfigurator.cairo").class_hash
        context.drip_configurator_hash = ids.drip_configurator_hash

        ids.drip_infra_factory = deploy_contract("./lib/morphine/deployment/dripInfraFactory.cairo", [ids.drip_manager_hash, ids.drip_transit_hash, ids.drip_configurator_hash]).contract_address
        context.drip_infra_factory = ids.drip_infra_factory
    %}

    return();
}



@view
func test_drip_infra_factory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dif_) = drip_infra_factory_instance.deployed();
    let (array1_: felt*) = alloc();
    let (allowed_tokens: AllowedToken*) = alloc();
    assert allowed_tokens[0] = AllowedToken(93, Uint256(1000,0));
    drip_infra_factory_instance.deployDripInfra(1, 2, 0, Uint256(0,0), Uint256(10000,0), 1, allowed_tokens, 0);
    let (a1_, a2_, a3_) = drip_infra_factory_instance.getDripInfraAddresses();


    %{
        print(ids.a1_)
        print(ids.a2_)
        print(ids.a3_)

    %}
    return ();
}



namespace drip_infra_factory_instance{
    func deployed() -> (drip_configurator : felt){
        tempvar drip_infra_factory;
        %{ ids.drip_infra_factory = context.drip_infra_factory %}
        return (drip_infra_factory,);
    }

    func deployDripInfra{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _pool: felt, 
        _nft: felt,
        _expirable: felt,
        _minimum_borrowed_amount: Uint256,
        _maximum_borrowed_amount: Uint256,
        _allowed_tokens_len: felt,
        _allowed_tokens: AllowedToken*,
        _salt: felt) {
    tempvar drip_infra_factory;
    %{ ids.drip_infra_factory = context.drip_infra_factory %}
    IDripInfraFactory.deployDripInfra(drip_infra_factory, drip_infra_factory, _pool, _nft, _expirable, _minimum_borrowed_amount, _maximum_borrowed_amount, _allowed_tokens_len, _allowed_tokens, _salt);
    return();
    }

    func getDripInfraAddresses{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (contract_address1: felt, contract_address2: felt, contract_address3: felt) {
    tempvar drip_infra_factory;
    %{ ids.drip_infra_factory = context.drip_infra_factory %}
    let (ad1_, ad2_, ad3_) = IDripInfraFactory.getDripInfraAddresses(drip_infra_factory);
    return(ad1_, ad2_, ad3_,);
    }

}

