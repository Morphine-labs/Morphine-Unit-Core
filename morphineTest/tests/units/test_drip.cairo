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
from morphine.interfaces.IDrip import IDrip

const ADMIN = 'morphine-admin';
const DRIP_MANAGER = 'drip-manager';
const DRIP_FACTORY = 'drip-manager';


// Token 
const TOKEN_NAME = 'dai';
const TOKEN_SYMBOL = 'DAI';
const TOKEN_DECIMALS = 6;
const TOKEN_INITIAL_SUPPLY_LO = 1000000000000;
const TOKEN_INITIAL_SUPPLY_HI = 0;


//drip
const BORROWED_AMOUNT_LO = 10000000000;
const BORROWED_AMOUNT_HI = 0;
const CUMULATIVE_INDEX_LO = 1000000;
const CUMULATIVE_INDEX_HI = 0;
const APPROVED_CONTRACT = 'approved_contract';
const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820;


@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar dai;
    tempvar drip;

    %{
        ids.drip = deploy_contract("./lib/morphine/drip/drip.cairo", []).contract_address 
        context.drip = ids.drip    

        ids.dai = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME, ids.TOKEN_SYMBOL, ids.TOKEN_DECIMALS, ids.TOKEN_INITIAL_SUPPLY_LO, ids.TOKEN_INITIAL_SUPPLY_HI, ids.drip, ids.drip]).contract_address 
        context.dai = ids.dai
    %}
    
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [ids.drip] ] %}
    drip_instance.initialize();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}


@view
func test_connect_to_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="Only drip factory can call this function") %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    return ();
}

@view
func test_connect_to_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [context.drip] ] %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (borrowed_amount_) = drip_instance.borrowedAmount();
    assert borrowed_amount_ = Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI);
    let (cumulative_index_) = drip_instance.cumulativeIndex();
    assert cumulative_index_ = Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI);
    return ();
}

@view
func test_update_parameters_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="Only drip manager can call this function") %}
    drip_instance.updateParameters(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    return ();
}

@view
func test_update_parameters_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [context.drip] ] %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(0,0), Uint256(0, 0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip] ] %}
    drip_instance.updateParameters(Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI), Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (borrowed_amount_) = drip_instance.borrowedAmount();
    assert borrowed_amount_ = Uint256(BORROWED_AMOUNT_LO, BORROWED_AMOUNT_HI);
    let (cumulative_index_) = drip_instance.cumulativeIndex();
    assert cumulative_index_ = Uint256(CUMULATIVE_INDEX_LO, CUMULATIVE_INDEX_HI);
    return ();
}

@view
func test_approve_token_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="Only drip manager can call this function") %}
    drip_instance.approveToken(83, APPROVED_CONTRACT);
    return ();
}

@view
func test_approve_token_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [context.drip] ] %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(0,0), Uint256(0, 0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip] ] %}
    drip_instance.approveToken(dai_, APPROVED_CONTRACT);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (drip_) = drip_instance.deployed();
    let (allowance_) = IERC20.allowance(dai_, drip_, APPROVED_CONTRACT);
    assert allowance_ = Uint256(ALL_ONES, ALL_ONES);
    return ();
}

@view
func test_cancel_allowance_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="Only drip manager can call this function") %}
    drip_instance.cancelAllowance(83, APPROVED_CONTRACT);
    return ();
}

@view
func test_cancel_allowance_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [context.drip] ] %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(0,0), Uint256(0, 0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip] ] %}
    drip_instance.approveToken(dai_, APPROVED_CONTRACT);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (drip_) = drip_instance.deployed();
    let (allowance_) = IERC20.allowance(dai_, drip_, APPROVED_CONTRACT);
    assert allowance_ = Uint256(ALL_ONES, ALL_ONES);
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip] ] %}
    drip_instance.cancelAllowance(dai_, APPROVED_CONTRACT);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (allowance_) = IERC20.allowance(dai_, drip_, APPROVED_CONTRACT);
    assert allowance_ = Uint256(0, 0);
    return ();
}

@view
func test_safe_transfer_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="Only drip manager can call this function") %}
    drip_instance.safeTransfer(83, APPROVED_CONTRACT, Uint256(TOKEN_INITIAL_SUPPLY_LO, TOKEN_INITIAL_SUPPLY_HI));
    return ();
}

@view
func test_safe_transfer_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [context.drip] ] %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(0,0), Uint256(0, 0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip] ] %}
    drip_instance.safeTransfer(dai_, APPROVED_CONTRACT, Uint256(TOKEN_INITIAL_SUPPLY_LO, TOKEN_INITIAL_SUPPLY_HI));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (contract_balance_) = IERC20.balanceOf(dai_, APPROVED_CONTRACT);
    assert contract_balance_ = Uint256(TOKEN_INITIAL_SUPPLY_LO, TOKEN_INITIAL_SUPPLY_HI);
    return ();
}

@view
func test_execute_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_) = drip_instance.deployed();
    let (dai_) = dai_instance.deployed();
    let (local calldata : felt*) = alloc();
    assert calldata[0] = APPROVED_CONTRACT;
    assert calldata[1] = TOKEN_INITIAL_SUPPLY_LO;
    assert calldata[2] = TOKEN_INITIAL_SUPPLY_HI;
    %{ expect_revert(error_message="Only drip manager can call this function") %}
    let (retdata_len: felt, retdata: felt*) =  drip_instance.execute(dai_, APPROVE_SELECTOR, 3, calldata);
    return ();
}

@view
func test_execute_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dai_) = dai_instance.deployed();
    let (drip_) = drip_instance.deployed();
    %{ stop_pranks = [start_prank(ids.DRIP_FACTORY, contract) for contract in [context.drip] ] %}
    drip_instance.connectTo(DRIP_MANAGER, Uint256(0,0), Uint256(0, 0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (local calldata : felt*) = alloc();
    assert calldata[0] = APPROVED_CONTRACT;
    assert calldata[1] = TOKEN_INITIAL_SUPPLY_LO;
    assert calldata[2] = TOKEN_INITIAL_SUPPLY_HI;
    // func approve(spender: felt, amount: Uint256) -> (success: felt) {
    // }
    %{ stop_pranks = [start_prank(ids.DRIP_MANAGER, contract) for contract in [context.drip] ] %}
    let (retdata_len: felt, retdata: felt*) =  drip_instance.execute(dai_, APPROVE_SELECTOR, 3, calldata);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    assert retdata_len = 1;
    assert retdata[0] = 1;
    let (allowance_) = IERC20.allowance(dai_, drip_, APPROVED_CONTRACT);
    assert allowance_ = Uint256(TOKEN_INITIAL_SUPPLY_LO, TOKEN_INITIAL_SUPPLY_HI);
    return ();
}

namespace drip_instance{
    func deployed() -> (pool : felt){
        tempvar drip;
        %{ ids.drip = context.drip %}
        return (drip,);
    }

    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.initialize(drip);
        return ();
    }

    func connectTo{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_manager: felt, _borrowed_amount: Uint256, _cumulative_index: Uint256) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.connectTo(drip, _drip_manager, _borrowed_amount, _cumulative_index);
        return ();
    }

    func updateParameters{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrowed_amount: Uint256, _cumulative_index: Uint256) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.updateParameters(drip, _borrowed_amount, _cumulative_index);
        return ();
    }

    func approveToken{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt, _contract: felt) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.approveToken(drip, _token, _contract);
        return ();
    }

    func cancelAllowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt, _contract: felt) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.cancelAllowance(drip, _token, _contract);
        return ();
    }

    func safeTransfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt, _to: felt, _amount: Uint256) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        IDrip.safeTransfer(drip, _token, _to, _amount);
        return ();
    }

    func execute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt, _selector: felt, _calldata_len: felt, _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
        tempvar drip;
        %{ ids.drip = context.drip %}
        let (retdata_len: felt, retdata: felt*) = IDrip.execute(drip, _to, _selector, _calldata_len, _calldata);
        return (retdata_len, retdata);
    }

    func cumulativeIndex{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (cumulative_index: Uint256) {
    tempvar drip;
    %{ ids.drip = context.drip %}
    let (cumulative_index_) =  IDrip.cumulativeIndex(drip);
    return (cumulative_index_,);
    }

    func borrowedAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (borrowed_amount: Uint256) {
    tempvar drip;
    %{ ids.drip = context.drip %}
    let (borrow_amount_) = IDrip.borrowedAmount(drip);
    return (borrow_amount_,);
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