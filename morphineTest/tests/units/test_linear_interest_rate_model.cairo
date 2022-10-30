%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

// Project dependencies
from morphine.interfaces.IInterestRateModel import IInterestRateModel

// LinearRateModel

const SLOPE1_LO = 15000;
const SLOPE1_HI = 0;
const SLOPE2_LO = 1000000; 
const SLOPE2_HI = 0; 
const BASE_RATE_LO =  0;
const BASE_RATE_HI =  0;
const OPTIMAL_RATE_LO = 800000; 
const OPTIMAL_RATE_HI = 0; 

// Pool random param

// 1: 50% Liquidity utilization 
const EXPECTED_LIQUIDITY_1_LO = 1000000000000000000000;
const EXPECTED_LIQUIDITY_1_HI = 0;
const AVAILABLE_LIQUIDITY_1_LO= 500000000000000000000;
const AVAILABLE_LIQUIDITY_1_HI= 0;

// 2: 80% Liquidity utilization (optimal)
const EXPECTED_LIQUIDITY_2_LO = 1000000000000000000000;
const EXPECTED_LIQUIDITY_2_HI = 0;
const AVAILABLE_LIQUIDITY_2_LO= 200000000000000000000;
const AVAILABLE_LIQUIDITY_2_HI= 0;

// 3: 90% Liquidity utilization (1/2 * slop2)
const EXPECTED_LIQUIDITY_3_LO = 1000000000000000000000;
const EXPECTED_LIQUIDITY_3_HI = 0;
const AVAILABLE_LIQUIDITY_3_LO= 100000000000000000000;
const AVAILABLE_LIQUIDITY_3_HI= 0;

// 4: 100% Liquidity utilization (* slop2)
const EXPECTED_LIQUIDITY_4_LO = 1000000000000000000000;
const EXPECTED_LIQUIDITY_4_HI = 0;
const AVAILABLE_LIQUIDITY_4_LO= 0;
const AVAILABLE_LIQUIDITY_4_HI= 0;

@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar interest_rate_model_contract;
    %{
        ids.interest_rate_model_contract = deploy_contract(
            "./src/morphine/pool/linearInterestRateModel.cairo", 
            [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract
        print(ids.interest_rate_model_contract)
    %}
    return();
}


@view
func test_right_parameters{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (interest_rate_model_) = interest_rate_model_instance.deployed();
    let (optimal_liquidity_utilization_, base_rate_, slope1_, slope2_) = interest_rate_model_instance.modelParameters(interest_rate_model_);
    assert Uint256(OPTIMAL_RATE_LO, OPTIMAL_RATE_HI) = optimal_liquidity_utilization_;
    assert Uint256(BASE_RATE_LO, BASE_RATE_HI) = base_rate_;
    assert Uint256(SLOPE1_LO, SLOPE1_HI) = slope1_;
    assert Uint256(SLOPE2_LO, SLOPE2_HI) = slope2_;
    return ();
}

@view
func test_right_borrow_rate_calcul{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (interest_rate_model_) = interest_rate_model_instance.deployed();

    // nul
    let (borrow_rate_nul_values) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(0, 0), Uint256(0, 0));
    assert Uint256(0, 0) = borrow_rate_nul_values;

    // dummy
    let (borrow_rate_dummy_values) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(50, 0), Uint256(100, 0));
    assert Uint256(0, 0) = borrow_rate_dummy_values;

    // equals
    let (borrow_rate_equal_values) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(EXPECTED_LIQUIDITY_1_LO, EXPECTED_LIQUIDITY_1_HI), Uint256(EXPECTED_LIQUIDITY_1_LO, EXPECTED_LIQUIDITY_1_HI));
    assert Uint256(0, 0) = borrow_rate_equal_values;

    // Should increase linearly from 0 to 1.5% for LU 0 to optimalLU (80%)

    let (borrow_rate_1_) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(EXPECTED_LIQUIDITY_1_LO, EXPECTED_LIQUIDITY_1_HI), Uint256(AVAILABLE_LIQUIDITY_1_LO, AVAILABLE_LIQUIDITY_1_HI));
    // 0 + 15000*(5/8) = 9375
    assert Uint256(9375, 0) = borrow_rate_1_;

    let (borrow_rate_2_) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(EXPECTED_LIQUIDITY_2_LO, EXPECTED_LIQUIDITY_2_HI), Uint256(AVAILABLE_LIQUIDITY_2_LO, AVAILABLE_LIQUIDITY_2_HI));
    // 0 + 15000*(8/8) = 15000
    assert Uint256(15000, 0) = borrow_rate_2_;

     // Should increase linearly from 1.5% to 101.5% for LU 80 to 100 

    let (borrow_rate_3_) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(EXPECTED_LIQUIDITY_3_LO, EXPECTED_LIQUIDITY_3_HI), Uint256(AVAILABLE_LIQUIDITY_3_LO, AVAILABLE_LIQUIDITY_3_HI));
    // 0 + 15000 + 1000000/2 = 515000
    assert Uint256(515000, 0) = borrow_rate_3_;

    let (borrow_rate_4_) = interest_rate_model_instance.calcBorrowRate(interest_rate_model_, Uint256(EXPECTED_LIQUIDITY_4_LO, EXPECTED_LIQUIDITY_4_HI), Uint256(AVAILABLE_LIQUIDITY_4_LO, AVAILABLE_LIQUIDITY_4_HI));
    // 0 + 15000 + 1000000 = 1015000
    assert Uint256(1015000, 0) = borrow_rate_4_;

    return ();
}

namespace interest_rate_model_instance{
    func deployed() -> (interest_rate_model_contract : felt){
        tempvar interest_rate_model_contract_;
        %{ ids.interest_rate_model_contract_ = context.interest_rate_model_contract %}
        return (interest_rate_model_contract_,);
    }

    func calcBorrowRate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_interest_rate_model: felt, _expected_liqudity : Uint256, _available_liquidity: Uint256)
        -> (borrow_rate: Uint256){
        let (borrow_rate_) = IInterestRateModel.calcBorrowRate(_interest_rate_model, _expected_liqudity, _available_liquidity);
        return (borrow_rate_,);
    }

     func modelParameters{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_interest_rate_model: felt)
        -> (optimal_liquidity_utilization: Uint256, base_rate: Uint256, slop1: Uint256, slop2: Uint256){
        let (optimal_liquidity_utilization_, base_rate_, slop1_, slop2_) = IInterestRateModel.modelParameters(_interest_rate_model);
        return (optimal_liquidity_utilization_, base_rate_, slop1_, slop2_,);
    }
}