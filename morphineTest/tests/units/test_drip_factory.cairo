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
from morphine.interfaces.IRegistery import IRegistery


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
    tempvar registery;

    %{

        ids.dai = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME, ids.TOKEN_SYMBOL, ids.TOKEN_DECIMALS, ids.TOKEN_INITIAL_SUPPLY_LO, ids.TOKEN_INITIAL_SUPPLY_HI, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dai = ids.dai

        ids.drip_hash = declare("./lib/morphine/drip/drip.cairo").class_hash
        context.drip_hash = ids.drip_hash

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.drip_hash]).contract_address 
        context.registery = ids.registery

        ids.drip_factory = deploy_contract("./lib/morphine/drip/dripFactory.cairo", [ids.registery]).contract_address 
        context.drip_factory = ids.drip_factory
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery] ] %}
    registery_instance.addDripManager(DRIP_MANAGER);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    
    return();
}

@view
func test_deploy{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "NewDrip"}) %}
    let (drip_length_) = drip_factory_instance.dripsLength();
    assert drip_length_ = 1;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 1;
    return ();
}

@view
func test_add_drip_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    drip_factory_instance.addDrip();
    let (drip_length_) = drip_factory_instance.dripsLength();
    assert drip_length_ = 2;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 2;
    return ();
}

@view
func test_take_drip_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="caller is not a drip manager") %}
    drip_factory_instance.takeDrip(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    return ();
}

@view
func test_take_drip_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DripTaken"}) %}
    drip_factory_instance.addDrip();
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip_factory] ] %}
    let (drip_) = drip_factory_instance.takeDrip(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (drip_length_) = drip_factory_instance.dripsLength();
    assert drip_length_ = 2;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 1;
    return ();
}

@view
func test_take_drip_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DripTaken"}) %}
    let (drip_) = drip_factory_instance.idToDrip(0);
    %{ stop_warp = warp(31536000, ids.drip_) %}
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip_factory] ] %}
    let (drip_) = drip_factory_instance.takeDrip(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ stop_warp() %}
    let (drip_length_) = drip_factory_instance.dripsLength();
    assert drip_length_ = 2;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 1;
    let (borrowed_amount_) = drip_instance.borrowedAmount(drip_);
    assert borrowed_amount_ = Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI);
    let (cumulative_index_) = drip_instance.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI);
    let (since_) = drip_instance.lastUpdate(drip_);
    assert since_ = 31536000;
    return ();
}


@view
func test_return_drip_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="caller is not a drip manager") %}
    drip_factory_instance.returnDrip(0);
    return ();
}

@view
func test_return_drip_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip_factory] ] %}
    %{ expect_revert(error_message="external drips forbidden") %}
    drip_factory_instance.returnDrip(0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_return_drip_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip_factory] ] %}
    %{ expect_revert(error_message="can not return drip in the same block") %}
    let (drip_) = drip_factory_instance.takeDrip(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    drip_factory_instance.returnDrip(drip_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_return_drip_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DripReturned"}) %}
    let (drip_) = drip_factory_instance.idToDrip(0);
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip_factory] ] %}
    %{ stop_warp = warp(31536000, ids.drip_) %}
    let (drip_) = drip_factory_instance.takeDrip(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    %{ stop_warp() %}
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 1;
    %{ stop_warp = warp(31536001, context.drip_factory) %}
    drip_factory_instance.returnDrip(drip_);
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 2;
    %{ stop_warp() %}
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_take_out_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    drip_factory_instance.takeOut(0,0,0);
    return ();
}

@view
func test_take_out_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_factory] ] %}
     %{ expect_revert(error_message="zero address") %}
    drip_factory_instance.takeOut(0,0,0);
    return ();
}

@view
func test_take_out_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    drip_factory_instance.addDrip();
    let (drip_) = drip_factory_instance.idToDrip(1);
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_factory] ] %}
    %{ expect_revert(error_message="account not in stock") %}
    drip_factory_instance.takeOut(drip_,drip_,0);
    return ();
}


//head 

@view
func test_take_out_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DripTakenForever"}) %}
    let (drip_) = drip_factory_instance.idToDrip(0);
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_factory] ] %}
    drip_factory_instance.takeOut(0,drip_,0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_drip_) = drip_factory_instance.isDrip(drip_);
    assert is_drip_ = 0;
    let (length_) =  drip_factory_instance.dripsLength();
    assert length_ = 1;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 1;
    return ();
}

//random not head not tail 
@view
func test_take_out_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DripTakenForever"}) %}
    drip_factory_instance.addDrip();
    drip_factory_instance.addDrip();
    let (drip_prev_) = drip_factory_instance.idToDrip(0);
    let (drip_) = drip_factory_instance.idToDrip(1);
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_factory] ] %}
    drip_factory_instance.takeOut(drip_prev_,drip_,0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_drip_) = drip_factory_instance.isDrip(drip_);
    assert is_drip_ = 0;
    let (length_) =  drip_factory_instance.dripsLength();
    assert length_ = 2;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 2;
    return ();
}

//tail
@view
func test_take_out_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DripTakenForever"}) %}
    drip_factory_instance.addDrip();
    drip_factory_instance.addDrip();
    let (drip_prev_) = drip_factory_instance.idToDrip(1);
    let (drip_) = drip_factory_instance.idToDrip(2);
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_factory] ] %}
    drip_factory_instance.takeOut(drip_prev_,drip_,0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_drip_) = drip_factory_instance.isDrip(drip_);
    assert is_drip_ = 0;
    let (length_) =  drip_factory_instance.dripsLength();
    assert length_ = 2;
    let (drip_stock_length_) = drip_factory_instance.dripStockLength();
    assert drip_stock_length_ = 2;
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
        let (drip_stock_length_) = IDripFactory.dripStockLength(drip_factory);
        return (drip_stock_length_,);
    }
}

namespace drip_instance{

    func lastUpdate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip: felt) -> (since: felt) {
        let (since_) = IDrip.lastUpdate(drip);
        return (since_,);
    }

    func cumulativeIndex{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip: felt) -> (cumulative_index: Uint256) {
    let (cumulative_index_) =  IDrip.cumulativeIndex(drip);
    return (cumulative_index_,);
    }

    func borrowedAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip: felt) -> (borrowed_amount: Uint256) {
    let (borrowed_amount_) = IDrip.borrowedAmount(drip);
    return (borrowed_amount_,);
    }

}

namespace registery_instance{
    func deployed() -> (registery : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        return (registery,);
    }

    func addDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_manager : felt) -> () {
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.addDripManager(registery, _drip_manager);
        return ();
    }
}



namespace dai_instance{
    func deployed() -> (dai : felt){
        tempvar dai;
        %{ ids.dai = context.dai %}
        return (dai,);
    }
}