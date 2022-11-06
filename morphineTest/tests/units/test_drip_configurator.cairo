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
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IEmpiricOracle import IEmpiricOracle
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IDripConfigurator import IDripConfigurator, AllowedToken
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IERC4626 import IERC4626
from morphine.utils.utils import pow
from morphine.utils.various import DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, PRECISION, DEFAULT_FEE_LIQUIDATION



const ADMIN = 'morphine-admin';
const USER_1 = 'user-1';

// Token 1 ETH
const TOKEN_NAME_1 = 'ethereum';
const TOKEN_SYMBOL_1 = 'ETH';
const TOKEN_DECIMALS_1 = 18;
const TOKEN_INITIAL_SUPPLY_LO_1 = 10000000000000000000;
const TOKEN_INITIAL_SUPPLY_HI_1 = 0;
const ETH_LT_LOW = 800000;
const ETH_LT_HIGH = 0;


// Token 2 BTC
const TOKEN_NAME_2 = 'bitcoin';
const TOKEN_SYMBOL_2 = 'BTC';
const TOKEN_DECIMALS_2 = 18;
const TOKEN_INITIAL_SUPPLY_LO_2 = 5*10**18;
const TOKEN_INITIAL_SUPPLY_HI_2 = 0;
const BTC_LT_LOW = 850000;
const BTC_LT_HIGH = 0;

// Token 3 DAI
const TOKEN_NAME_3 = 'dai';
const TOKEN_SYMBOL_3 = 'DAI';
const TOKEN_DECIMALS_3 = 6;
const TOKEN_INITIAL_SUPPLY_LO_3 = 20000*10**6;
const TOKEN_INITIAL_SUPPLY_HI_3 = 0;

// Token 4 ERC4626 VETH
const TOKEN_NAME_4 = 'vethereum';
const TOKEN_SYMBOL_4 = 'VETH';
const VETH_LT_LOW = 700000;
const VETH_LT_HIGH = 0;

// Oracle 
const ETH_USD = 19514442401534788;
const BTC_USD = 18669995996566340;
const DAI_USD = 28254602066752356;
const DECIMALS_FEED = 8;
const ETH_PRICE = 200000000000;
const BTC_PRICE = 2500000000000;
const DAI_PRICE = 100000000;
const LUT = 0;
const NSA = 0;

// LinearRateModel
const SLOPE1_LO = 15000;
const SLOPE1_HI = 0;
const SLOPE2_LO = 1000000; 
const SLOPE2_HI = 0; 
const BASE_RATE_LO =  0;
const BASE_RATE_HI =  0;
const OPTIMAL_RATE_LO = 800000; 
const OPTIMAL_RATE_HI = 0; 

// Pool
const ERC4626_NAME = 'Mdai';
const ERC4626_SYMBOL = 'MDAI';
const EXPECTED_LIQUIDITY_LIMIT_LO = 1000000*10**6;
const EXPECTED_LIQUIDITY_LIMIT_HI = 0;


// Registery
const TREASURY = 'morphine_treasyury';
const ORACLE_TRANSIT = 'oracle_transit';
const DRIP_HASH = 'drip_hash';
const DRIP_FACTORY= 'drip_factory';


//drip configurator 
const DRIP_TRANSIT= 'drip_transit';
const MINIMUM_BORROWED_AMOUNT_LO = 10000*10**6;
const MINIMUM_BORROWED_AMOUNT_HI = 0;
const MAXIMUM_BORROWED_AMOUNT_LO = 1000000*10**6;
const MAXIMUM_BORROWED_AMOUNT_HI = 0;


@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();
    tempvar eth;
    tempvar btc;
    tempvar dai;
    tempvar veth;
    tempvar empiric_oracle;
    tempvar registery;
    tempvar erc4626_pricefeed;
    tempvar oracle_transit;

    %{
        #Deploying 3 tokens + ERC4626

        ids.eth = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME_1, ids.TOKEN_SYMBOL_1, ids.TOKEN_DECIMALS_1, ids.TOKEN_INITIAL_SUPPLY_LO_1, ids.TOKEN_INITIAL_SUPPLY_HI_1, ids.ADMIN, ids.ADMIN]).contract_address 
        context.eth = ids.eth

        ids.btc = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME_2, ids.TOKEN_SYMBOL_2, ids.TOKEN_DECIMALS_2, ids.TOKEN_INITIAL_SUPPLY_LO_2, ids.TOKEN_INITIAL_SUPPLY_HI_2, ids.ADMIN, ids.ADMIN]).contract_address 
        context.btc = ids.btc

        ids.dai = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME_3, ids.TOKEN_SYMBOL_3, ids.TOKEN_DECIMALS_3, ids.TOKEN_INITIAL_SUPPLY_LO_3, ids.TOKEN_INITIAL_SUPPLY_HI_3, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dai = ids.dai

        ids.veth = deploy_contract("./tests/mocks/erc4626.cairo", [ids.eth, ids.TOKEN_NAME_4, ids.TOKEN_SYMBOL_4]).contract_address 
        context.veth = ids.veth

        # Deploying empiric oracle 

        ids.empiric_oracle = deploy_contract("./tests/mocks/empiricOracle.cairo",[]).contract_address 
        context.empiric_oracle = ids.empiric_oracle
    %}
    

    // Set assets value
    IEmpiricOracle.set_spot_median(empiric_oracle, ETH_USD, ETH_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, BTC_USD, BTC_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, DAI_USD, DAI_PRICE, DECIMALS_FEED, LUT, NSA);


    %{

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.DRIP_HASH]).contract_address 
        context.registery = ids.registery

        ids.erc4626_pricefeed = deploy_contract("./lib/morphine/oracle/derivativePriceFeed/erc4626.cairo", []).contract_address 
        context.erc4626_pricefeed = ids.erc4626_pricefeed

        ids.oracle_transit = deploy_contract("./lib/morphine/oracle/oracleTransit.cairo",[ids.empiric_oracle, ids.registery]).contract_address 
        context.oracle_transit = ids.oracle_transit

    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.oracle_transit, ids.eth, ids.registery] ] %}
    IRegistery.setOracleTransit(registery, oracle_transit);
    IOracleTransit.addPrimitive(oracle_transit, eth, ETH_USD);
    IOracleTransit.addPrimitive(oracle_transit, btc, BTC_USD);
    IOracleTransit.addPrimitive(oracle_transit, dai, DAI_USD);
    IOracleTransit.addDerivative(oracle_transit, veth, erc4626_pricefeed);
    IERC20.approve(eth, veth, Uint256(1000000000000000000000,77));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.veth] ] %}
    IERC4626.deposit(veth, Uint256(1000000000000000000,0), 7383);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.eth] ] %}
    IERC20.transfer(eth, veth, Uint256(1000000000000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{
        stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery]] 
    %}
        registery_instance.setDripFactory(DRIP_FACTORY);
    %{
        [stop_prank() for stop_prank in stop_pranks] 
    %}

    tempvar drip_manager;
    tempvar interest_rate_model_contract;
    tempvar pool;
    tempvar drip_configurator_address;
  
    %{
        ids.interest_rate_model_contract = deploy_contract("./lib/morphine/pool/linearInterestRateModel.cairo", [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract

        ids.pool = deploy_contract("./lib/morphine/pool/pool.cairo", [context.registery, context.dai, ids.ERC4626_NAME, ids.ERC4626_SYMBOL, ids.EXPECTED_LIQUIDITY_LIMIT_LO, ids.EXPECTED_LIQUIDITY_LIMIT_HI, ids.interest_rate_model_contract]).contract_address 
        context.pool = ids.pool    

        declared = declare("./lib/morphine/drip/dripManager.cairo")
        prepared = prepare(declared, [ids.pool])
        stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [prepared.contract_address]]

        ids.drip_manager = deploy(prepared).contract_address
        context.drip_manager = ids.drip_manager    

        declared = declare("./lib/morphine/drip/dripConfigurator.cairo")
        drip_configurator_prepared = prepare(declared, [context.drip_manager, ids.DRIP_TRANSIT, ids.MINIMUM_BORROWED_AMOUNT_LO, ids.MINIMUM_BORROWED_AMOUNT_HI, ids.MAXIMUM_BORROWED_AMOUNT_LO, ids.MAXIMUM_BORROWED_AMOUNT_HI, 2, context.btc, ids.BTC_LT_LOW, ids.BTC_LT_HIGH, context.eth, ids.ETH_LT_LOW, ids.ETH_LT_HIGH])

        ids.drip_configurator_address = drip_configurator_prepared.contract_address
    %}

        drip_manager_instance.setDripConfigurator(drip_configurator_address);

        tempvar drip_configurator;
    %{
        [stop_prank() for stop_prank in stop_pranks]
        ids.drip_configurator = deploy(drip_configurator_prepared).contract_address 
        context.drip_configurator = ids.drip_configurator  
    %}
  


    return();
}



@view
func test_drip_configurator_deployement{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (minimum_borrowed_amount_) = drip_manager_instance.minBorrowedAmount();
    let (maximum_borrowed_amount_) = drip_manager_instance.maxBorrowedAmount();
    let (fee_interest_) = drip_manager_instance.feeInterest();
    let (fee_liqudidation_) = drip_manager_instance.feeLiquidation();
    let (liquidation_discount_) = drip_manager_instance.liquidationDiscount();
    let (chi_threshold_) = drip_manager_instance.chiThreshold();
    let (hf_check_interval_) = drip_manager_instance.hfCheckInterval();
    assert minimum_borrowed_amount_ = Uint256(MINIMUM_BORROWED_AMOUNT_LO, MINIMUM_BORROWED_AMOUNT_HI);
    assert maximum_borrowed_amount_ = Uint256(MAXIMUM_BORROWED_AMOUNT_LO, MAXIMUM_BORROWED_AMOUNT_HI);
    assert fee_interest_ = Uint256(DEFAULT_FEE_INTEREST,0);
    assert fee_liqudidation_ = Uint256(DEFAULT_FEE_LIQUIDATION, 0);
    assert liquidation_discount_ = Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM, 0);
    assert chi_threshold_ = Uint256(DEFAULT_CHI_THRESHOLD, 0);
    assert hf_check_interval_ = Uint256(DEFAULT_HF_CHECK_INTERVAL, 0);

    
    return ();
}



namespace drip_configurator_instance{
    func deployed() -> (drip_configurator : felt){
        tempvar drip_configurator;
        %{ ids.drip_configurator = context.drip_configurator %}
        return (drip_configurator,);
    }

    func addTokenToAllowedList{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.addTokenToAllowedList(drip_configurator, _token);
    return();
    }

    func setLiquidationThreshold{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt, _liquidation_threshold: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setLiquidationThreshold(drip_configurator, _token, _liquidation_threshold);
    return();
    }

    func allowToken{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.allowToken(drip_configurator, _token);
    return();
    }

    func forbidToken{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.forbidToken(drip_configurator, _token);
    return();
    }

    func allowContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _adapter: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.allowContract(drip_configurator, _contract, _adapter);
    return();
    }

    func forbidContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.forbidContract(drip_configurator, _contract);
    return();
    }

    func setLimits{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setLimits(drip_configurator, _minimum_borrowed_amount, _maximum_borrowed_amount);
    return();
    }

    func setFastCheckParameters{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_chi_threshold: Uint256, _hf_check_interval: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setFastCheckParameters(drip_configurator, _chi_threshold, _hf_check_interval);
    return();
    }

    func setFees{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fee_interest: Uint256, _fee_liquidation: Uint256, _liquidation_premium: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setFees(drip_configurator, _fee_interest, _fee_liquidation, _liquidation_premium);
    return();
    }

    func upgradeOracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.upgradeOracleTransit(drip_configurator);
    return();
    }

    func upgradeDripTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_transit: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.upgradeDripTransit(drip_configurator, _drip_transit);
    return();
    }

    func upgradeConfigurator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_configurator: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.upgradeConfigurator(drip_configurator, _drip_configurator);
    return();
    }

    func setIncreaseDebtForbidden{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_state: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setIncreaseDebtForbidden(drip_configurator, _state);
    return();
    }

    // Getters

    func idToAllowedContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id: felt) -> (allowedContract: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (allowed_contract_) =  IDripConfigurator.idToAllowedContract(drip_configurator, id);
    return(allowed_contract_,);
    }

    func allowedContractToId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_allowed_contract: felt) -> (id: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (id_) =  IDripConfigurator.allowedContractToId(drip_configurator, _allowed_contract);
    return(id_,);
    }

    func allowedContractsLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id: felt) -> (allowedContractsLength: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (allowed_contract_length_) =  IDripConfigurator.allowedContractsLength(drip_configurator, id);
    return(allowed_contract_length_,);
    }


    func isAllowedContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt) -> (state: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (state_) =  IDripConfigurator.isAllowedContract(drip_configurator, _contract);
    return(state_,);
    }

}


namespace drip_manager_instance{
    func deployed() -> (drip_manager : felt){
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        return (drip_manager,);
    }

    func setDripConfigurator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip_configurator: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        IDripManager.setDripConfigurator(drip_manager, drip_configurator);
        return ();
    }

    func feeInterest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (feeInterest: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (fee_interest_) = IDripManager.feeInterest(drip_manager);
        return(fee_interest_,);
    }


    func feeLiquidation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (feeLiquidation: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager);
        return(fee_liqudidation_,);
    }


    func liquidationDiscount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (liquidationDiscount: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (liquidation_discount_) = IDripManager.liquidationDiscount(drip_manager);
        return(liquidation_discount_,);
    }


    func chiThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (chiThreshold: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (chi_threshold_) = IDripManager.chiThreshold(drip_manager);
        return(chi_threshold_,);
    }


    func hfCheckInterval{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (hf_check_interval: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (hf_check_interval_) = IDripManager.hfCheckInterval(drip_manager);
        return(hf_check_interval_,);
    }


    func minBorrowedAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (minimum_borrowed_amount: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (minimum_borrowed_amount_) = IDripManager.minBorrowedAmount(drip_manager);
        return(minimum_borrowed_amount_,);
    }


    func maxBorrowedAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (maximum_borrowed_amount: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (maximum_borrowed_amount_) = IDripManager.maxBorrowedAmount(drip_manager);
        return(maximum_borrowed_amount_,);
    }


    func getPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (pool: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (pool_) = IDripManager.getPool(drip_manager);
        return(pool_,);
    }


    func dripConfigurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (drip_configurator: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (drip_configurator_) = IDripManager.dripConfigurator(drip_manager);
        return(drip_configurator_,);
    }

}

namespace registery_instance{
    func deployed() -> (registery : felt){
        tempvar registery;
        %{ ids.registery = context.registery %}
        return (registery,);
    }

    func setDripFactory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip_factory : felt) -> () {
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.setDripFactory(registery, drip_factory);
        return ();
    }

    func setOracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(new_oracle_transit: felt) -> () {
    tempvar registery;
    %{ ids.registery = context.registery %}
    IRegistery.setOracleTransit(registery, new_oracle_transit);
    return ();
    }

}



namespace oracle_transit_instance{

    func deployed() -> (oracle_transit : felt){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        return (oracle_transit,);
    }

    func primitivePairId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(primitive: felt) -> (pair_id: felt){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        let (pair_id_) = IOracleTransit.primitivePairId(oracle_transit, primitive);
        return (pair_id_,);
    }

    func derivativePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(derivative: felt) -> (derivative_price_feed: felt){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        let (derivative_price_feed_) = IOracleTransit.derivativePriceFeed(oracle_transit, derivative);
        return (derivative_price_feed_,);
    }
}


namespace btc_instance{
    func deployed() -> (btc : felt){
        tempvar btc;
        %{ ids.btc = context.btc %}
        return (btc,);
    }
}

namespace dai_instance{
    func deployed() -> (dai : felt){
        tempvar dai;
        %{ ids.dai = context.dai %}
        return (dai,);
    }
}