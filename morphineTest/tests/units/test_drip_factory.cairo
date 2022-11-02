%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, ALL_ONES
from starkware.starknet.common.syscalls import get_block_timestamp, get_block_number
from starkware.cairo.common.alloc import alloc


// OpenZeppelin dependencies
from openzeppelin.token.erc20.IERC20 import IERC20

// Project dependencies
from morphine.interfaces.IDripFactory import IDripFactory
from morphine.interfaces.IDrip import IDrip

const ADMIN = 'morphine-admin';
const DRIP_MANAGER = 'drip-manager';
const DRIP_FACTORY = 'drip-factory';


// Token 
const TOKEN_NAME = 'dai';
const TOKEN_SYMBOL = 'DAI';
const TOKEN_DECIMALS = 6;
const TOKEN_INITIAL_SUPPLY_LO = 1000000000000;
const TOKEN_INITIAL_SUPPLY_HI = 0;

// Registery
const TREASURY = 'morphine_treasyury';
const ORACLE_TRANSIT = 'oracle_transit';


//drip
const BORROWED_AMOUNT_LO = 10000000000;
const BORROWED_AMOUNT_HI = 0;
const CUMULATIVE_INDEX_LO = 1000000;
const CUMULATIVE_INDEX_HI = 0;

@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar dai;
    tempvar drip_hash;
    tempvar drip_factory;
    tempvar drip;
    tempvar registery;

    %{
        ids.drip = deploy_contract("./lib/morphine/drip/drip.cairo", []).contract_address 
        context.drip = ids.drip    

        ids.dai = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME, ids.TOKEN_SYMBOL, ids.TOKEN_DECIMALS, ids.TOKEN_INITIAL_SUPPLY_LO, ids.TOKEN_INITIAL_SUPPLY_HI, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dai = ids.dai

        ids.drip_hash = declare("./lib/morphine/drip/drip.cairo").class_hash
        context.drip_hash = ids.drip_hash

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.drip_hash]).contract_address 
        context.registery = ids.registery

        ids.drip_factory = deploy_contract("./lib/morphine/drip/dripFactory.cairo", [ids.registery]).contract_address 
        context.drip_factory = ids.drip_factory
    %}
    return();
}

@view
func test_deploy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "NewDrip"}) %}
    let (drip_length_) = drip_factory_instance.dripsLength();
    assert drip_length_ = 1;
    return ();
}

namespace drip_factory_instance{

    func deployed() -> (pool : felt){
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        return (drip_factory,);
    }

    func addDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        IDripFactory.addDrip(drip_factory);
        return ();
    }

    func takeDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrowed_amount: Uint256, _cumulative_index: Uint256) -> (address: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (drip_) = IDripFactory.takeDrip(drip_factory, _borrowed_amount, _cumulative_index);
        return (drip_,);
    }

    func returnDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_used_drip: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        IDripFactory.returnDrip(drip_factory, _used_drip);
        return ();
    }

    func takeOut{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_prev: felt, _drip: felt, _to: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        IDripFactory.takeOut(drip_factory, _prev, _drip, _to);
        return ();
    }
    
    func nextDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (drip: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (next_drip_) = IDripFactory.nextDrip(drip_factory, _drip);
        return (next_drip_,);
    }

    func dripsLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (dripLength: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (drip_length_) = IDripFactory.dripsLength(drip_factory);
        return (drip_length_,);
    }

    func idToDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_id: felt) -> (drip: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (drip_) = IDripFactory.idToDrip(drip_factory, _id);
        return (drip_,);
    }

    func dripToId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (id: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (id_) = IDripFactory.dripToId(drip_factory, _drip);
        return (id_,);
    }

    func isDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (state: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (state_) = IDripFactory.isDrip(drip_factory, _drip);
        return (state_,);
    }

    func dripStockLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (length: felt) {
        tempvar drip_factory;
        %{ ids.drip_factory = context.drip_factory %}
        let (drip_stock_length_) = IDripFactory.isDrip(drip_factory);
        return (drip_stock_length_,);
    }
}

namespace drip_instance{
    func deployed() -> (pool : felt){
        tempvar drip;
        %{ ids.drip = context.drip %}
        return (drip,);
    }

    func connectTo{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_manager: felt, _borrowed_amount: Uint256, _cumulative_index: Uint256) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.connectTo(drip, _drip_manager, _borrowed_amount, _cumulative_index);
        return ();
    }

    func since{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (since: felt) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        let (since_) = IDrip.since(drip);
        return (since_,);
    }
}



namespace dai_instance{
    func deployed() -> (dai : felt){
        tempvar dai;
        %{ ids.dai = context.dai %}
        return (dai,);
    }
}