
%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, ALL_ONES
from starkware.starknet.common.syscalls import get_block_timestamp, get_block_number
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc


// OpenZeppelin dependencies
from openzeppelin.token.erc20.IERC20 import IERC20

// Project dependencies
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IEmpiricOracle import IEmpiricOracle
from morphine.interfaces.IDripInfraFactory import IDripInfraFactory
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IDripConfigurator import IDripConfigurator, AllowedToken
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IDripTransit import IDripTransit, AccountCallArray
from morphine.interfaces.IERC4626 import IERC4626
from morphine.interfaces.IMorphinePass import IMorphinePass
from morphine.interfaces.IMinter import IMinter
from morphine.interfaces.IDrip import IDrip




from morphine.utils.utils import pow

from morphine.utils.various import DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, PRECISION, DEFAULT_FEE_LIQUIDATION, DEFAULT_FEE_LIQUIDATION_EXPIRED, DEFAULT_FEE_LIQUIDATION_EXPIRED_PREMIUM, DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER, APPROVE_SELECTOR, REVERT_IF_RECEIVED_LESS_THAN_SELECTOR, ADD_COLLATERAL_SELECTOR, INCREASE_DEBT_SELECTOR, DECREASE_DEBT_SELECTOR, ENABLE_TOKEN_SELECTOR,DISABLE_TOKEN_SELECTOR 



const ADMIN = 'morphine-admin';
const USER_1 = 'user-1';
const USER_2 = 'user_2';

// NFT
const PASS_TOKEN_NAME = 'morphine_pool_access';
const PASS_TOKEN_SYMBOL = 'MPA';


// Token 1 ETH
const TOKEN_NAME_1 = 'ethereum';
const TOKEN_SYMBOL_1 = 'ETH';
const TOKEN_DECIMALS_1 = 18;
const TOKEN_INITIAL_SUPPLY_LO_1 = 10000000000000000000;
const TOKEN_INITIAL_SUPPLY_HI_1 = 0;
const ETH_LT_LOW = 80*10**16;
const ETH_LT_HIGH = 0;


// Token 2 BTC
const TOKEN_NAME_2 = 'bitcoin';
const TOKEN_SYMBOL_2 = 'BTC';
const TOKEN_DECIMALS_2 = 18;
const TOKEN_INITIAL_SUPPLY_LO_2 = 5*10**18;
const TOKEN_INITIAL_SUPPLY_HI_2 = 0;
const BTC_LT_LOW = 85*10**16;
const BTC_LT_HIGH = 0;

// Token 3 DAI
const TOKEN_NAME_3 = 'dai';
const TOKEN_SYMBOL_3 = 'DAI';
const TOKEN_DECIMALS_3 = 6;
const TOKEN_INITIAL_SUPPLY_LO_3 = 1000000*10**6;
const TOKEN_INITIAL_SUPPLY_HI_3 = 0;

// Token 4 ERC4626 VETH
const TOKEN_NAME_4 = 'vethereum';
const TOKEN_SYMBOL_4 = 'VETH';
const VETH_LT_LOW = 70*10**16;
const VETH_LT_HIGH = 0;

// Token 5 RD
const TOKEN_NAME_5 = 'random';
const TOKEN_SYMBOL_5 = 'RD';
const TOKEN_DECIMALS_5 = 18;
const TOKEN_INITIAL_SUPPLY_LO_5 = 20000*10**18;
const TOKEN_INITIAL_SUPPLY_HI_5 = 0;

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
const SLOPE1_LO = 15*10**15;
const SLOPE1_HI = 0;
const SLOPE2_LO = 1*10**18; 
const SLOPE2_HI = 0; 
const BASE_RATE_LO =  0;
const BASE_RATE_HI =  0;
const OPTIMAL_RATE_LO = 80*10**16; 
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


const BORROW_AMOUNT_LOW = 20000*10**6;
const BORROW_AMOUNT_HIGH = 0;
const LEVERAGE_FACTOR_LOW = 3*10**18;
const LEVERAGE_FACTOR_HIGH = 0;
const WRONG_LEVERAGE_FACTOR_LOW = 157*10**18;
const WRONG_LEVERAGE_FACTOR_HIGH = 0;

const RANDOM_ADDRESS = 'random_address';


@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (__fp__, _) = get_fp_and_pc();
    tempvar eth;
    tempvar btc;
    tempvar dai;
    tempvar veth;
    tempvar rd;
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

        ids.rd = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME_5, ids.TOKEN_SYMBOL_5, ids.TOKEN_DECIMALS_5, ids.TOKEN_INITIAL_SUPPLY_LO_5, ids.TOKEN_INITIAL_SUPPLY_HI_5, ids.ADMIN, ids.ADMIN]).contract_address 
        context.rd = ids.rd

        # Deploying empiric oracle 

        ids.empiric_oracle = deploy_contract("./tests/mocks/empiricOracle.cairo",[]).contract_address 
        context.empiric_oracle = ids.empiric_oracle
    %}
    

    // Set assets value
    IEmpiricOracle.set_spot_median(empiric_oracle, ETH_USD, ETH_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, BTC_USD, BTC_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, DAI_USD, DAI_PRICE, DECIMALS_FEED, LUT, NSA);

    tempvar drip_hash;
    tempvar drip_factory;

    %{
        ids.drip_hash = declare("./lib/morphine/drip/drip.cairo").class_hash
        context.drip_hash = ids.drip_hash

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, context.drip_hash]).contract_address 
        context.registery = ids.registery

        ids.drip_factory = deploy_contract("./lib/morphine/drip/dripFactory.cairo", [context.registery]).contract_address 
        context.drip_factory = ids.drip_factory

        ids.erc4626_pricefeed = deploy_contract("./lib/morphine/oracle/derivativePriceFeed/erc4626.cairo", []).contract_address 
        context.erc4626_pricefeed = ids.erc4626_pricefeed

        ids.oracle_transit = deploy_contract("./lib/morphine/oracle/oracleTransit.cairo",[ids.empiric_oracle, ids.registery]).contract_address 
        context.oracle_transit = ids.oracle_transit

    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.oracle_transit, ids.eth, ids.registery] ] %}

    IRegistery.setOracleTransit(registery, oracle_transit);
    IRegistery.setDripFactory(registery, drip_factory);
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

    %{
        [stop_prank() for stop_prank in stop_pranks] 
    %}

    
    tempvar interest_rate_model_contract;
    tempvar pool;
    tempvar morphine_pass;
    tempvar minter;

    %{
        ids.interest_rate_model_contract = deploy_contract("./lib/morphine/pool/linearInterestRateModel.cairo", [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract

        ids.pool = deploy_contract("./lib/morphine/pool/pool.cairo", [context.registery, context.dai, ids.ERC4626_NAME, ids.ERC4626_SYMBOL, ids.EXPECTED_LIQUIDITY_LIMIT_LO, ids.EXPECTED_LIQUIDITY_LIMIT_HI, ids.interest_rate_model_contract]).contract_address 
        context.pool = ids.pool    

        ids.morphine_pass = deploy_contract("./lib/morphine/token/morphinePass.cairo", [ids.PASS_TOKEN_NAME, ids.PASS_TOKEN_SYMBOL, context.registery]).contract_address 
        context.morphine_pass = ids.morphine_pass  

        ids.minter = deploy_contract("./lib/morphine/token/minter.cairo", [context.morphine_pass]).contract_address 
        context.minter = ids.minter  
    %}

    let (whitelisted_addresses: felt*) = alloc();
    assert whitelisted_addresses[0] = USER_1;
    minter_instance.setWhitelist(1, whitelisted_addresses);
    let (minter_) = minter_instance.deployed();

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.morphine_pass] ] %}
    morphine_pass_instance.setMinter(minter_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

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

    tempvar drip_manager;
    tempvar drip_transit;
    tempvar drip_configurator;

    let (allowed_assets: AllowedToken*) = alloc();
    let (eth_) = eth_instance.deployed();
    let (veth_) = veth_instance.deployed();
    assert allowed_assets[0] = AllowedToken(eth_, Uint256(ETH_LT_LOW, ETH_LT_HIGH));
    assert allowed_assets[1] = AllowedToken(veth_, Uint256(VETH_LT_LOW, VETH_LT_HIGH));
    let (pool_) = pool_instance.deployed();
    let (morphine_pass_) = morphine_pass_instance.deployed();
    drip_infra_factory_instance.deployDripInfra(pool_, morphine_pass_, 1, Uint256(MINIMUM_BORROWED_AMOUNT_LO,MINIMUM_BORROWED_AMOUNT_HI), Uint256(MAXIMUM_BORROWED_AMOUNT_LO,MAXIMUM_BORROWED_AMOUNT_HI), 2, allowed_assets, 0);
    let (a1_, a2_, a3_) = drip_infra_factory_instance.getDripInfraAddresses();
    %{
        context.drip_manager = ids.a1_
        context.drip_transit = ids.a2_
        context.drip_configurator = ids.a3_
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    drip_configurator_instance.setMaxEnabledTokens(Uint256(2,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.registery, context.morphine_pass, context.pool] ] %}
    let (drip_manager_) = drip_manager_instance.deployed();
    registery_instance.addDripManager(drip_manager_);
    let (drip_transit_) = drip_transit_instance.deployed();
    morphine_pass_instance.addDripTransit(drip_transit_);
    pool_instance.connectDripManager(drip_manager_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.minter] ] %}
    minter_instance.mint();
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(500000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (shares_)  = pool_instance.deposit(Uint256(500000*10**6,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.transfer(dai_, USER_1, Uint256(BORROW_AMOUNT_LOW, BORROW_AMOUNT_HIGH));
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    tempvar erc4626_adapter;
    tempvar erc4626_adapter_second;

    %{
        ids.erc4626_adapter = deploy_contract("./lib/morphine/adapters/ERC4626/ERC4626.cairo", [context.drip_manager, context.veth]).contract_address
        context.erc4626_adapter = ids.erc4626_adapter

        ids.erc4626_adapter_second = deploy_contract("./lib/morphine/adapters/ERC4626/ERC4626.cairo", [context.drip_manager, context.veth]).contract_address
        context.erc4626_adapter_second = ids.erc4626_adapter_second
    %}


    tempvar new_drip_transit;
    tempvar new_drip_transit_false;
    tempvar new_drip_configurator;
    tempvar new_drip_configurator_false;
    tempvar dummy_drip_manager;

    %{
        ids.dummy_drip_manager = deploy_contract("./lib/morphine/drip/dripManager.cairo", [context.pool]).contract_address
        context.dummy_drip_manager = ids.dummy_drip_manager

        ids.new_drip_transit = deploy_contract("./lib/morphine/drip/dripTransit.cairo", [context.drip_manager, context.morphine_pass, 1]).contract_address
        context.new_drip_transit = ids.new_drip_transit

        ids.new_drip_transit_false = deploy_contract("./lib/morphine/drip/dripTransit.cairo", [context.dummy_drip_manager, context.morphine_pass, 1]).contract_address
        context.new_drip_transit_false = ids.new_drip_transit_false

        ids.new_drip_configurator = deploy_contract("./lib/morphine/drip/dripConfiguratorSideline.cairo", [context.drip_manager]).contract_address
        context.new_drip_configurator = ids.new_drip_configurator

        ids.new_drip_configurator_false = deploy_contract("./lib/morphine/drip/dripConfiguratorSideline.cairo", [context.dummy_drip_manager]).contract_address
        context.new_drip_configurator_false = ids.new_drip_configurator_false
    %}

    %{ stop_warps = [warp(0, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    %{ stop_rolls = [roll(1, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    drip_configurator_instance.setExpirationDate(5000);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.dai] ] %}
    let (dai_) = dai_instance.deployed();
    let (drip_manager_) = drip_manager_instance.deployed();
    IERC20.approve(dai_, drip_manager_, Uint256(BORROW_AMOUNT_LOW, BORROW_AMOUNT_HIGH));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.openDrip(Uint256(BORROW_AMOUNT_LOW, BORROW_AMOUNT_HIGH), USER_1, Uint256(LEVERAGE_FACTOR_LOW, LEVERAGE_FACTOR_HIGH));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ [stop_roll() for stop_roll in stop_rolls] %}
    %{ [stop_warp() for stop_warp in stop_warps] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    let (erc4626_adapter_) = erc4626_adapter_instance.deployed();
    let (veth_) = veth_instance.deployed();
    drip_configurator_instance.allowContract(veth_, erc4626_adapter_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_calc_close_payments_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    let (amount_to_pool_, remaining_funds_, profit_, loss_) = drip_manager_instance.calcClosePayments(Uint256(0,0), 0, Uint256(100000,0), Uint256(110000,0));
    assert amount_to_pool_ = Uint256(111000, 0);
    assert remaining_funds_ = Uint256(0,0);
    assert profit_ = Uint256(1000,0);
    assert loss_ = Uint256(0,0);
    
    let (amount_to_pool_, remaining_funds_, profit_, loss_) = drip_manager_instance.calcClosePayments(Uint256(120000,0), 1, Uint256(100000,0), Uint256(110000,0)); 
    assert amount_to_pool_ = Uint256(113400, 0);
    assert remaining_funds_ = Uint256(1800,0);
    assert profit_ = Uint256(3400,0);
    assert loss_ = Uint256(0,0);

    let (amount_to_pool_, remaining_funds_, profit_, loss_) = drip_manager_instance.calcClosePayments(Uint256(121200,0), 2, Uint256(100000,0), Uint256(110000,0)); 
    assert amount_to_pool_ = Uint256(113424, 0);  
    assert remaining_funds_ = Uint256(2928,0);
    assert profit_ = Uint256(3424,0);
    assert loss_ = Uint256(0,0);


    let (amount_to_pool_, remaining_funds_, profit_, loss_) = drip_manager_instance.calcClosePayments(Uint256(116000,0), 1, Uint256(100000,0), Uint256(110000,0));
    assert amount_to_pool_ = Uint256(111360, 0);
    assert remaining_funds_ = Uint256(0,0);
    assert profit_ = Uint256(1360,0);
    assert loss_ = Uint256(0,0);

    let (amount_to_pool_, remaining_funds_, profit_, loss_) = drip_manager_instance.calcClosePayments(Uint256(112000,0), 1, Uint256(100000,0), Uint256(110000,0));
    assert amount_to_pool_ = Uint256(107520, 0);
    assert remaining_funds_ = Uint256(0,0);
    assert profit_ = Uint256(0,0);
    assert loss_ = Uint256(2480,0);

    let (amount_to_pool_, remaining_funds_, profit_, loss_) = drip_manager_instance.calcClosePayments(Uint256(112000,0), 3, Uint256(100000,0), Uint256(110000,0));
    assert amount_to_pool_ = Uint256(112000, 0);
    assert remaining_funds_ = Uint256(0,0);
    assert profit_ = Uint256(2000,0);
    assert loss_ = Uint256(0,0);
    
    return();
}

@view
func test_calc_accrued_interests_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(60000000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(60000000000, 0);

    let (borrow_rate_) = pool_instance.borrowRate();
    %{
        print(ids.borrow_rate_.low)
        print(ids.borrow_rate_.high)
    %}
   
    %{ stop_warps = [warp(31536000, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(60135000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(60148500000, 0);
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}

@view
func test_enable_token_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.enableToken(veth_);
    return();
}

@view
func test_enable_token_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_manager] ] %}
    drip_manager_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Pausable: paused") %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_enable_token_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit, context.drip_manager] ] %}
    %{ expect_revert(error_message="only drip transit or adapter") %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_enable_token_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (btc_) = btc_instance.deployed();


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="not allowed token") %}
    drip_transit_instance.enableToken(btc_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_enable_token_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    drip_configurator_instance.forbidToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="token forbidden") %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_enable_token_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();

    %{
         store(context.drip_manager, "max_allowed_enabled_tokens_length", [0,0])
    %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Too many enabled tokens") %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_enable_token_7{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    %{ expect_events({"name": "TokenEnabled", "data": [ids.USER_1, context.veth],"from_address": context.drip_transit}) %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (enabled_tokens_) = drip_manager_instance.enabledTokensMap(drip_);
    assert enabled_tokens_ = Uint256(5,0);
    return();
}


@view
func test_increase_debt_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    return();
}

@view
func test_increase_debt_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    drip_configurator_instance.setIncreaseDebtForbidden(1);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="increase debt forbidden") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_increase_debt_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    
    %{
        store(context.drip_transit, "nft", [0])
        store(context.drip_transit, "max_borrowed_amount_per_block", [0,0])
    %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="borrowed per block limit") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}


@view
func test_increase_debt_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    let (veth_) = veth_instance.deployed();

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    drip_configurator_instance.forbidToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="action prohibited with forbidden tokens") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_increase_debt_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    let (veth_) = veth_instance.deployed();

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.enableToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_configurator] ] %}
    drip_configurator_instance.forbidToken(veth_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="action prohibited with forbidden tokens") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_increase_debt_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit, context.drip_manager] ] %}
    %{ expect_revert(error_message="only callable by drip transit") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_increase_debt_7{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_manager] ] %}
    drip_manager_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Pausable: paused") %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}


@view
func test_increase_debt_8{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "IncreaseBorrowedAmount", "data": [ids.USER_1, 10000*10**6,0],"from_address": context.drip_transit}) %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(60000000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(60000000000, 0);

    let (borrow_rate_) = pool_instance.borrowRate();
    %{
        print(ids.borrow_rate_.low)
        print(ids.borrow_rate_.high)
    %}

    let (max_allowed_enabled_tokens_length_) = drip_manager_instance.maxAllowedTokensLength();
    assert max_allowed_enabled_tokens_length_ = Uint256(2,0);
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    


    let (borrowed_amount_) = IDrip.borrowedAmount(drip_);
    assert borrowed_amount_ = Uint256(70000*10**6,0);
    let (cumulative_index_) = IDrip.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(1000000000000000000,0);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(70000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(70000000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(70000000000, 0);


    return();
}

@view
func test_increase_debt_9{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "IncreaseBorrowedAmount", "data": [ids.USER_1, 10000*10**6,0],"from_address": context.drip_transit}) %}
    %{ stop_warps = [warp(40 * 31536000, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(65400000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(65940000000, 0);

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.increaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    
    let (borrowed_amount_, drip_index_, current_index_) = drip_manager_instance.dripParameters(drip_);
    assert borrowed_amount_ = Uint256(70000*10**6,0);
    assert drip_index_ = Uint256(1011936339522546419,0);
    assert current_index_ = Uint256(1090000000000000000,0);

    %{ [stop_warp() for stop_warp in stop_warps] %}

    return();
}


@view
func test_decrease_debt_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.decreaseDebt(Uint256(10000*10**6,0));
    return();
}

@view
func test_decrease_debt_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit, context.drip_manager] ] %}
    %{ expect_revert(error_message="only callable by drip transit") %}
    drip_transit_instance.decreaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_decrease_debt_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_manager] ] %}
    drip_manager_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Pausable: paused") %}
    drip_transit_instance.decreaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_decrease_debt_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_manager] ] %}
    drip_manager_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Pausable: paused") %}
    drip_transit_instance.decreaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}


@view
func test_decrease_debt_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DecreaseBorrowedAmount", "data": [ids.USER_1, 10000*10**6,0],"from_address": context.drip_transit}) %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (max_allowed_enabled_tokens_length_) = drip_manager_instance.maxAllowedTokensLength();
    assert max_allowed_enabled_tokens_length_ = Uint256(2,0);
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.decreaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(50000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(50000000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(50000000000, 0);
    let (cumulative_index_) = IDrip.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(1000000000000000000,0);
    return();
}

@view
func test_decrease_debt_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DecreaseBorrowedAmount", "data": [ids.USER_1, 10000*10**6,0],"from_address": context.drip_transit}) %}
    %{ stop_warps = [warp(40 * 31536000, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    
    
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(65400000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(65940000000, 0);
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.decreaseDebt(Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(55940000000,0);
    assert borrowedAmountWithInterest_ = Uint256(55940000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(55940000000, 0);
    let (cumulative_index_) = IDrip.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(1090000000000000000,0);
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}

@view
func test_decrease_debt_7{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DecreaseBorrowedAmount", "data": [ids.USER_1, 2970*10**6,0],"from_address": context.drip_transit}) %}
    %{ stop_warps = [warp(40 * 31536000, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    
    
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(65400000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(65940000000, 0);
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.decreaseDebt(Uint256(2970*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(62700000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(62970000000, 0);
    let (cumulative_index_) = IDrip.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(1043062200956937799,0);
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}

@view
func test_add_collateral_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dai_) = dai_instance.deployed();
    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.addCollateral(USER_2, dai_, Uint256(10000*10**6,0));
    return();
}

@view
func test_add_collateral_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dai_) = dai_instance.deployed();

    %{ stop_pranks = [start_prank(ids.USER_2, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="drip transfer not allowed") %}
    drip_transit_instance.addCollateral(USER_1, dai_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_add_collateral_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dai_) = dai_instance.deployed();

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_manager] ] %}
    drip_manager_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Pausable: paused") %}
    drip_transit_instance.addCollateral(USER_1, dai_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_add_collateral_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (btc_) = btc_instance.deployed();

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="not allowed token") %}
    drip_transit_instance.addCollateral(USER_1, btc_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_add_collateral_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "AddCollateral", "data": [ids.USER_1, context.dai, 10000*10**6,0],"from_address": context.drip_transit}) %}
    let (dai_) = dai_instance.deployed();
    let (drip_manager_) = drip_manager_instance.deployed();
    
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.dai] ] %}
    IERC20.transfer(dai_, USER_1, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.dai] ] %}
    IERC20.approve(dai_, drip_manager_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.addCollateral(USER_1, dai_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (tv_, tvw_) = drip_transit_instance.calcTotalValue(drip_);
    assert tv_ = Uint256(90000*10**6,0);
    return();
}

@view
func test_add_collateral_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "AddCollateral", "data": [ids.USER_1, context.eth, 2*10**18,0],"from_address": context.drip_transit}) %}
    let (eth_) = eth_instance.deployed();
    let (drip_manager_) = drip_manager_instance.deployed();
    
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.eth] ] %}
    IERC20.transfer(eth_, USER_1, Uint256(2*10**18,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.eth] ] %}
    IERC20.approve(eth_, drip_manager_, Uint256(2*10**18,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.addCollateral(USER_1, eth_, Uint256(2*10**18,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (tv_, tvw_) = drip_transit_instance.calcTotalValue(drip_);
    assert tv_ = Uint256(84000*10**6,0);

    let (enabled_tokens_) = drip_manager_instance.enabledTokensMap(drip_);
    assert enabled_tokens_ = Uint256(3,0);
    return();
}

@view
func test_approve_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ expect_revert(error_message="target is not adapter") %}
    drip_transit_instance.approve(USER_2, dai_, Uint256(10000*10**6,0));
    return();
}

@view
func test_approve_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    let (adapter_) = drip_manager_instance.contractToAdapter(veth_);
    let (erc4626_adapter_) = erc4626_adapter_instance.deployed();
    assert adapter_ = erc4626_adapter_;
    let (btc_) = btc_instance.deployed();
    %{ expect_revert(error_message="not allowed token") %}
    drip_transit_instance.approve(veth_, btc_, Uint256(10000*10**6,0));
    return();
}

@view
func test_approve_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.approve(veth_, dai_, Uint256(10000*10**6,0));
    return();
}

@view
func test_approve_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    let (dai_) = dai_instance.deployed();
    
    %{ stop_pranks = [start_prank(ids.USER_2, contract) for contract in [context.drip_manager] ] %}
    %{ expect_revert(error_message="not allowed target") %}
    drip_transit_instance.approve(veth_, dai_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_approve_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.approve(veth_, dai_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (allowance_) = IERC20.allowance(dai_, drip_, veth_);
    assert allowance_ = Uint256(10000*10**6,0);
    return();
}

@view
func test_approve_drip_transfer_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "TransferDripAllowed", "data": [ids.USER_2, ids.USER_1, 1],"from_address": context.drip_transit}) %}
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.approveDripTransfers(USER_2, 1);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_tranfer_allowed_) = drip_transit_instance.isTransferAllowed(USER_2, USER_1);
    return();
}

@view
func test_transfer_drip_ownership_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_revert(error_message="not permisonless error") %}
    drip_transit_instance.transferDripOwnership(USER_2);
    return();
}

@view
func test_transfer_drip_ownership_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{
         store(context.drip_transit, "nft", [0])
    %}
    %{ expect_revert(error_message="transfer not allowed") %}
    drip_transit_instance.transferDripOwnership(USER_2);
    return();
}

@view
func test_transfer_drip_ownership_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    %{
        store(context.drip_transit, "nft", [0])
        store(context.dai, "ERC20_balances", [1000*10**6,0], key=[ids.drip_])
    %}

    %{ stop_pranks = [start_prank(ids.USER_2, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.approveDripTransfers(USER_1, 1);
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="transfer not allowed for liquiditable drip") %}
    drip_transit_instance.transferDripOwnership(USER_2);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_transfer_drip_ownership_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    %{
        store(context.drip_transit, "nft", [0])
        store(context.drip_manager, "borrower_to_drip", [898], key=[ids.USER_2])
    %}
    %{ expect_events({"name": "TransferDrip", "data": [ids.USER_1, ids.USER_2],"from_address": context.drip_transit}) %}

    %{ stop_pranks = [start_prank(ids.USER_2, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.approveDripTransfers(USER_1, 1);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="zero address or user already has a drip") %}
    drip_transit_instance.transferDripOwnership(USER_2);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_transfer_drip_ownership_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    %{
        store(context.drip_transit, "nft", [0])
    %}
    %{ expect_events({"name": "TransferDrip", "data": [ids.USER_1, ids.USER_2],"from_address": context.drip_transit}) %}

    %{ stop_pranks = [start_prank(ids.USER_2, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.approveDripTransfers(USER_1, 1);
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.transferDripOwnership(USER_2);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (drip_new_owner_) = drip_manager_instance.getDrip(USER_2);
    assert drip_new_owner_ = drip_;
    return();
}


@view
func test_multicall_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = INCREASE_DEBT_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 2;
    let (call_data: felt*) = alloc();
    assert call_data[0] = 10000*10**6;
    assert call_data[1] = 0;

    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.multicall(1, call_array, 2, call_data);
    return();
}

@view
func test_multicall_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = 33;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 2;
    let (call_data: felt*) = alloc();
    assert call_data[0] = 10000*10**6;
    assert call_data[1] = 0;
    
    %{ expect_revert(error_message="unknown selector") %}
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.multicall(1, call_array, 2, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return();
}

@view
func test_multicall_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "AddCollateral", "data": [ids.USER_1, context.dai, 10000*10**6,0],"from_address": context.drip_transit}) %}
    let (dai_) = dai_instance.deployed();
    let (drip_manager_) = drip_manager_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.dai] ] %}
    IERC20.transfer(dai_, USER_1, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.dai] ] %}
    IERC20.approve(dai_, drip_manager_, Uint256(10000*10**6,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = ADD_COLLATERAL_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 4;
    let (call_data: felt*) = alloc();
    assert call_data[0] = USER_1;
    assert call_data[1] = dai_;
    assert call_data[2] = 10000*10**6;
    assert call_data[3] = 0;

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.multicall(1, call_array, 4, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (tv_, tvw_) = drip_transit_instance.calcTotalValue(drip_);
    assert tv_ = Uint256(90000*10**6,0);
    return();
}

@view
func test_multicall_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "IncreaseBorrowedAmount", "data": [ids.USER_1, 10000*10**6,0],"from_address": context.drip_transit}) %}
    let (dai_) = dai_instance.deployed();


    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = INCREASE_DEBT_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 2;
    let (call_data: felt*) = alloc();
    assert call_data[0] = 10000*10**6;
    assert call_data[1] = 0;


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.multicall(1, call_array, 2, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (tv_, tvw_) = drip_transit_instance.calcTotalValue(drip_);
    assert tv_ = Uint256(90000*10**6,0);
    let (borrowed_amount_) = IDrip.borrowedAmount(drip_);
    assert borrowed_amount_ = Uint256(70000*10**6,0);
    let (cumulative_index_) = IDrip.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(1*10**18,0);

    return();
}

@view
func test_multicall_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dai_) = dai_instance.deployed();
    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = INCREASE_DEBT_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 2;
    assert call_array[1].to = drip_transit_;
    assert call_array[1].selector = DECREASE_DEBT_SELECTOR;
    assert call_array[1].data_offset = 2;
    assert call_array[1].data_len = 2;
    let (call_data: felt*) = alloc();
    assert call_data[0] = 10000*10**6;
    assert call_data[1] = 0;
    assert call_data[2] = 10000*10**6;
    assert call_data[3] = 0;


    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="can not decrease and increase debt") %}
    drip_transit_instance.multicall(2, call_array, 4, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return();
}

@view
func test_multicall_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "DecreaseBorrowedAmount", "data": [ids.USER_1, 10000*10**6,0],"from_address": context.drip_transit}) %}
    let (dai_) = dai_instance.deployed();


    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = DECREASE_DEBT_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 2;
    let (call_data: felt*) = alloc();
    assert call_data[0] = 10000*10**6;
    assert call_data[1] = 0;

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.multicall(1, call_array, 2, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (tv_, tvw_) = drip_transit_instance.calcTotalValue(drip_);
    assert tv_ = Uint256(70000*10**6,0);
    let (borrowed_amount_) = IDrip.borrowedAmount(drip_);
    assert borrowed_amount_ = Uint256(50000*10**6,0);
    let (cumulative_index_) = IDrip.cumulativeIndex(drip_);
    assert cumulative_index_ = Uint256(1*10**18,0);
    return();
}


@view
func test_multicall_7{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "TokenEnabled", "data": [ids.USER_1, context.eth],"from_address": context.drip_transit}) %}
    let (eth_) = eth_instance.deployed();


    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = ENABLE_TOKEN_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 1;
    let (call_data: felt*) = alloc();
    assert call_data[0] = eth_;

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.multicall(1, call_array, 1, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (enabled_tokens_) = drip_manager_instance.enabledTokensMap(drip_);
    assert enabled_tokens_ = Uint256(3,0);
    return();
}

@view
func test_multicall_8{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "TokenDisabled", "data": [ids.USER_1, context.eth],"from_address": context.drip_transit}) %}
    let (eth_) = eth_instance.deployed();


    let (drip_transit_) = drip_transit_instance.deployed();
    let (call_array: AccountCallArray*) = alloc();
    assert call_array[0].to = drip_transit_;
    assert call_array[0].selector = ENABLE_TOKEN_SELECTOR;
    assert call_array[0].data_offset = 0;
    assert call_array[0].data_len = 1;
    assert call_array[1].to = drip_transit_;
    assert call_array[1].selector = DISABLE_TOKEN_SELECTOR;
    assert call_array[1].data_offset = 1;
    assert call_array[1].data_len = 1;
    let (call_data: felt*) = alloc();
    assert call_data[0] = eth_;
    assert call_data[1] = eth_;

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.multicall(2, call_array, 2, call_data);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (enabled_tokens_) = drip_manager_instance.enabledTokensMap(drip_);
    assert enabled_tokens_ = Uint256(1,0);
    return();
}

@view
func test_close_drip_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (call_array_: AccountCallArray*) = alloc();
    let (calldata_: felt*) = alloc();
    %{ stop_warps = [warp(31536000, contract) for contract in [context.drip_configurator, context.drip_transit, context.drip_manager, context.pool] ] %}
    %{ expect_revert(error_message="has not drip") %}
    drip_transit_instance.closeDrip(USER_2, 0, call_array_, 0, calldata_);
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}

@view
func test_close_drip_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (call_array_: AccountCallArray*) = alloc();
    let (calldata_: felt*) = alloc();

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.drip_manager] ] %}
    drip_manager_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    %{ stop_warps = [warp(31536000, contract) for contract in [context.drip_transit, context.drip_manager, context.pool] ] %}
    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="Pausable: paused") %}
    drip_transit_instance.closeDrip(USER_2, 0, call_array_, 0, calldata_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}

@view
func test_close_drip_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    %{ stop_warps = [warp(40 * 31536000, contract) for contract in [context.drip_transit, context.drip_manager, context.pool] ] %}
    let (call_array_: AccountCallArray*) = alloc();
    let (calldata_: felt*) = alloc();
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(65400000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(65940000000, 0);

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    %{ expect_revert(error_message="can not return drip in the same block") %}
    drip_transit_instance.closeDrip(USER_2, 0, call_array_, 0, calldata_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}

@view
func test_close_drip_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ expect_events({"name": "CloseDrip", "data": [ids.USER_1, ids.USER_2],"from_address": context.drip_transit}) %}

    %{ stop_warps = [warp(40 * 31536000, contract) for contract in [context.drip_transit, context.drip_manager, context.pool, context.drip_factory] ] %}
    let (call_array_: AccountCallArray*) = alloc();
    let (calldata_: felt*) = alloc();
    let (drip_) = drip_manager_instance.getDrip(USER_1);
    let (borrowedAmount_ , borrowedAmountWithInterest_, borrowedAmountWithInterestAndFees_) = drip_manager_instance.calcDripAccruedInterest(drip_);
    assert borrowedAmount_ = Uint256(60000000000,0);
    assert borrowedAmountWithInterest_ = Uint256(65400000000, 0);
    assert borrowedAmountWithInterestAndFees_ = Uint256(65940000000, 0);

    %{ stop_pranks = [start_prank(ids.USER_1, contract) for contract in [context.drip_transit] ] %}
    drip_transit_instance.closeDrip(USER_2, 0, call_array_, 0, calldata_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (dai_) = dai_instance.deployed();
    let (user_balance_) = IERC20.balanceOf(dai_, USER_2);
    assert user_balance_ = Uint256(14060*10**6,0);

    let (total_assets_) = pool_instance.totalAssets();
    assert total_assets_ = Uint256(505940*10**6,0);
    let (expected_liquidity_) = pool_instance.expectedLiquidity();
    assert expected_liquidity_ = Uint256(505940*10**6,0);
    let (available_liquidity_) = pool_instance.availableLiquidity();
    assert available_liquidity_ = Uint256(505940*10**6,0);
    let (total_borrowed_) = pool_instance.totalBorrowed();
    assert total_borrowed_ = Uint256(0,0);
    
    %{ [stop_warp() for stop_warp in stop_warps] %}
    return();
}



namespace drip_configurator_instance{
    func deployed() -> (drip_configurator : felt){
        tempvar drip_configurator;
        %{ ids.drip_configurator = context.drip_configurator %}
        return (drip_configurator,);
    }

    func setMaxEnabledTokens{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_max_enabled_tokens: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setMaxEnabledTokens(drip_configurator, _new_max_enabled_tokens);
    return();
    }

    func addToken{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt, _liquidation_threshold: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.addToken(drip_configurator, _token, _liquidation_threshold);
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

    func setFees{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fee_interest: Uint256, _fee_liquidation: Uint256, _liquidation_premium: Uint256, _fee_liquidation_expired: Uint256, _liquidation_premium_expired: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setFees(drip_configurator, _fee_interest, _fee_liquidation, _liquidation_premium, _fee_liquidation_expired, _liquidation_premium_expired);
    return();
    }

    func setIncreaseDebtForbidden{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_state: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setIncreaseDebtForbidden(drip_configurator, _state);
    return();
    }

    func setLimitPerBlock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_limit: Uint256){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setLimitPerBlock(drip_configurator, _new_limit);
    return();
    }

    func setExpirationDate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_new_expiration_date: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.setExpirationDate(drip_configurator, _new_expiration_date);
    return();
    }

    func addEmergencyLiquidator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_liquidator: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.addEmergencyLiquidator(drip_configurator, _liquidator);
    return();
    }

    func removeEmergencyLiquidator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_liquidator: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.removeEmergencyLiquidator(drip_configurator, _liquidator);
    return();
    }


    func upgradeOracleTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.upgradeOracleTransit(drip_configurator);
    return();
    }

    func upgradeDripTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_transit: felt, _migrate_parameters: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.upgradeDripTransit(drip_configurator, _drip_transit, _migrate_parameters);
    return();
    }

    func upgradeConfigurator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_configurator: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    IDripConfigurator.upgradeConfigurator(drip_configurator, _drip_configurator);
    return();
    }


    // Getters

    func allowedContractsLength{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (allowedContractsLength: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (allowed_contract_length_) =  IDripConfigurator.allowedContractsLength(drip_configurator);
    return(allowed_contract_length_,);
    }

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

    func isAllowedContract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt) -> (state: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (state_) =  IDripConfigurator.isAllowedContract(drip_configurator, _contract);
    return(state_,);
    }

    func dripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (dripManager: felt){
    tempvar drip_configurator;
    %{ ids.drip_configurator = context.drip_configurator %}
    let (drip_manager_) =  IDripConfigurator.dripManager(drip_configurator);
    return(drip_manager_,);
    }

}


namespace drip_manager_instance{

    func deployed() -> (drip_manager : felt){
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        return (drip_manager,);
    }

    func pause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        IDripManager.pause(drip_manager);
        return();
    }

    func unpause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        IDripManager.unpause(drip_manager);
        return();
    }

    func checkEmergencyPausable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_caller: felt, _state: felt) -> (state: felt){
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (paused_) = IDripManager.checkEmergencyPausable(drip_manager, _caller, _state);
        return(paused_,);
    }

    func openDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(borrowed_amount: Uint256, on_belhalf_of: felt) -> (drip: felt){
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (drip_) = IDripManager.openDrip(drip_manager, borrowed_amount, on_belhalf_of);
        return(drip_,);
    }

    func closeDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(borrower: felt, type: felt, total_value: Uint256, payer: felt, to: felt) -> (remaining_funds: Uint256){
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (remaining_funds_) = IDripManager.closeDrip(drip_manager, borrower, type, total_value, payer, to);
        return(remaining_funds_,);
    }

    func underlying{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (underlying: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (underlying_) = IDripManager.underlying(drip_manager);
        return(underlying_,);
    }

    func allowedTokensLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (allowed_tokens_length: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (allowed_contract_length_) = IDripManager.allowedTokensLength(drip_manager);
        return(allowed_contract_length_,);
    }

    func maxAllowedTokensLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (max_allowed_contract_length_: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (max_allowed_contract_length_) = IDripManager.maxAllowedTokensLength(drip_manager);
        return(max_allowed_contract_length_,);
    }

    func tokenMask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) -> (token_mask: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (token_mask_) = IDripManager.tokenMask(drip_manager, _token);
        return(token_mask_,);
    }

    func enabledTokensMap{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (enabled_tokens: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (enabled_tokens_) = IDripManager.enabledTokensMap(drip_manager, _drip);
        return(enabled_tokens_,);
    }

    func forbiddenTokenMask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (forbiden_token_mask: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (forbiden_token_mask_) = IDripManager.forbiddenTokenMask(drip_manager);
        return(forbiden_token_mask_,);
    }

    func tokenByMask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token_mask: Uint256) -> (token: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (token_) = IDripManager.tokenByMask(drip_manager, _token_mask);
        return(token_,);
    }

    func tokenById{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_id: felt) -> (token: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (token_) = IDripManager.tokenById(drip_manager, _id);
        return(token_,);
    }

    func liquidationThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) -> (liquidationThresold: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (liquidation_threshold_) = IDripManager.liquidationThreshold(drip_manager, _token);
        return(liquidation_threshold_,);
    }

    func liquidationThresholdByMask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token_mask: Uint256) -> (liquidationThresold: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (liquidation_threshold_) = IDripManager.liquidationThresholdByMask(drip_manager, _token_mask);
        return(liquidation_threshold_,);
    }

    func liquidationThresholdById{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_id: felt) -> (liquidationThresold: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (liquidation_threshold_) = IDripManager.liquidationThresholdById(drip_manager, _id);
        return(liquidation_threshold_,);
    }

    func adapterToContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_adapter: felt) -> (contract: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (contract_) = IDripManager.adapterToContract(drip_manager, _adapter);
        return(contract_,);
    }

    func contractToAdapter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt) -> (adapter: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (adapter_) = IDripManager.contractToAdapter(drip_manager, _contract);
        return(adapter_,);
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

    func feeLiquidationExpired{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (feeLiquidationExpired: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (fee_liqudidation_expired_) = IDripManager.feeLiquidationExpired(drip_manager);
        return(fee_liqudidation_expired_,);
    }

    func liquidationDiscount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (liquidationDiscount: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (liquidation_discount_) = IDripManager.liquidationDiscount(drip_manager);
        return(liquidation_discount_,);
    }

    func liquidationDiscountExpired{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (liquidationDiscountExpired: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (liquidation_discount_expired_) = IDripManager.liquidationDiscountExpired(drip_manager);
        return(liquidation_discount_expired_,);
    }

    func canLiquidateWhilePaused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_liquidator: felt) -> (state: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (can_liquidate_while_paused_) = IDripManager.canLiquidateWhilePaused(drip_manager, _liquidator);
        return(can_liquidate_while_paused_,);
    }


    func getPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (pool: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (pool_) = IDripManager.getPool(drip_manager);
        return(pool_,);
    }

    func dripTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (drip_transit: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (drip_transit_) = IDripManager.dripTransit(drip_manager);
        return(drip_transit_,);
    }

    func dripConfigurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (drip_configurator: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (drip_configurator_) = IDripManager.dripConfigurator(drip_manager);
        return(drip_configurator_,);
    }

    func oracleTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (oracle_transit: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (oracle_transit_) = IDripManager.oracleTransit(drip_manager);
        return(oracle_transit_,);
    }

    // Drip

    func getDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(borrower: felt) -> (drip: felt) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (drip_) = IDripManager.getDrip(drip_manager, borrower);
        return(drip_,);
    }

    func dripParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (borrowedAmount: Uint256, cumulativeIndex: Uint256, currentCumulativeIndex: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (borrowedAmount, cumulativeIndex, currentCumulativeIndex) = IDripManager.dripParameters(drip_manager, _drip);
        return(borrowedAmount, cumulativeIndex, currentCumulativeIndex,);
    }



    // Calcul

    func calcClosePayments{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_total_value: Uint256, _type: felt, _borrowed_amount: Uint256, _borrowed_amount_with_interests: Uint256) -> (amount_to_pool: Uint256, remaining_funds: Uint256, profit: Uint256, loss: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (amount_to_pool, remaining_funds, profit, loss) = IDripManager.calcClosePayments(drip_manager, _total_value, _type, _borrowed_amount, _borrowed_amount_with_interests);
        return(amount_to_pool, remaining_funds, profit, loss,);
    }

    func calcDripAccruedInterest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (borrowedAmount: Uint256, borrowedAmountWithInterest: Uint256, borrowedAmountWithInterestAndFees: Uint256) {
        tempvar drip_manager;
        %{ ids.drip_manager = context.drip_manager %}
        let (borrowed_amount_, borrowed_amount_with_interests_, borrowed_amount_with_interests_and_fees_) = IDripManager.calcDripAccruedInterest(drip_manager, _drip);
        return (borrowed_amount_, borrowed_amount_with_interests_, borrowed_amount_with_interests_and_fees_,);
    }

}

namespace drip_transit_instance{

    func deployed() -> (drip_transit : felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        return (drip_transit,);
    }

    func openDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_amount: Uint256, _on_belhalf_of: felt, _leverage_factor: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.openDrip(drip_transit, _amount, _on_belhalf_of, _leverage_factor);
        return();
    }

    func openDripMultiCall{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrowed_amount: Uint256, _on_belhalf_of: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.openDripMultiCall(drip_transit, _borrowed_amount, _on_belhalf_of, _call_array_len, _call_array, _calldata_len, _calldata);
        return();
    }

    func closeDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.closeDrip(drip_transit, _to, _call_array_len, _call_array, _calldata_len, _calldata);
        return();
    }

    func liquidateDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrower: felt, _to: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.liquidateDrip(drip_transit, _borrower, _to, _call_array_len, _call_array, _calldata_len, _calldata);
        return();
    }

    func liquidateExpiredDrip{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrower: felt, _to: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.liquidateExpiredDrip(drip_transit, _borrower, _to, _call_array_len, _call_array, _calldata_len, _calldata);
        return();
    }

    // Drip Management

    func increaseDebt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_amount: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.increaseDebt(drip_transit, _amount);
        return();
    }

    func decreaseDebt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_amount: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.decreaseDebt(drip_transit, _amount);
        return();
    }

    func addCollateral{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_on_belhalf_of: felt, _token: felt, _amount: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.addCollateral(drip_transit, _on_belhalf_of, _token, _amount);
        return();
    }

    func multicall{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.multicall(drip_transit, _call_array_len, _call_array, _calldata_len, _calldata);
        return();
    }

    func enableToken{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_token: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.enableToken(drip_transit, _token);
        return();
    }

    func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_target: felt, _token: felt, _amount: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.approve(drip_transit, _target, _token, _amount);
        return();
    }

    func transferDripOwnership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.transferDripOwnership(drip_transit, _to);
        return();
    }

    func approveDripTransfers{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_from: felt, _state: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        IDripTransit.approveDripTransfers(drip_transit, _from, _state);
        return();
    }

    // Parameters 

    func isIncreaseDebtForbidden{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(is_increase_debt_forbidden: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (is_increase_debt_forbidden_) = IDripTransit.isIncreaseDebtForbidden(drip_transit);
        return(is_increase_debt_forbidden_,);
    }

    func maxBorrowedAmountPerBlock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(max_borrowed_amount_per_block: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (max_borrowed_amount_per_block_) = IDripTransit.maxBorrowedAmountPerBlock(drip_transit);
        return(max_borrowed_amount_per_block_,);
    }

    func expirationDate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(expiration_date: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (expiration_date_) = IDripTransit.expirationDate(drip_transit);
        return(expiration_date_,);
    }

    func isExpirable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(is_expirable: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (is_expirable_) = IDripTransit.isExpirable(drip_transit);
        return(is_expirable_,);
    }

    func isExpired{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(is_expired: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (is_expired_) = IDripTransit.isExpired(drip_transit);
        return(is_expired_,);
    }

    func limits{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (minimum_borrowed_amount_, maximum_borrowed_amount_) = IDripTransit.limits(drip_transit);
        return(minimum_borrowed_amount_, maximum_borrowed_amount_,);
    }

    func lastLimitSaved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (last_limit_saved: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (last_limit_saved_) = IDripTransit.lastLimitSaved(drip_transit);
        return(last_limit_saved_,);
    }
    
    func lastBlockSaved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (last_block_saved: felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (last_block_saved_) = IDripTransit.lastBlockSaved(drip_transit);
        return(last_block_saved_,);
    }

    func isTransferAllowed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_from: felt, _to: felt) -> (is_allowed : felt){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (is_tranfer_allowed_) = IDripTransit.isTransferAllowed(drip_transit, _from, _to);
        return(is_tranfer_allowed_,);
    }

    // Calul

    func calcTotalValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (total: Uint256, twv: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (TV_, TWV_) = IDripTransit.calcTotalValue(drip_transit, _drip);
        return(TV_, TWV_,);
    }

    func calcDripHealthFactor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip: felt) -> (health_factor: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (HF_) = IDripTransit.calcDripHealthFactor(drip_transit, _drip);
        return(HF_,);
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

    func addDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip_manager: felt) -> () {
        tempvar registery;
        %{ ids.registery = context.registery %}
        IRegistery.addDripManager(registery, drip_manager);
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


namespace pool_instance{
    func deployed() -> (pool : felt){
        tempvar pool;
        %{ ids.pool = context.pool %}
        return (pool,);
    }

    // Owner stuff
    func pause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.pause(pool);
    return();
    }

    func unpause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.unpause(pool);
    return();
    }

    func isPaused{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (state_) = IPool.isPaused(pool); 
    return(state_,);
    }

    func freezeBorrow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.freezeBorrow(pool); 
    return();
    }

    func unfreezeBorrow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.unfreezeBorrow(pool); 
    return();
    }

    func isBorrowFrozen{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (is_borrow_frozen_) = IPool.isBorrowFrozen(pool); 
    return(is_borrow_frozen_,);
    }

    func freezeRepay{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.freezeRepay(pool); 
    return();
    }

    func unfreezeRepay{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.unfreezeRepay(pool); 
    return();
    }

    func isRepayFrozen{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (is_repay_frozen_) = IPool.isRepayFrozen(pool); 
    return(is_repay_frozen_,);
    }

    func setWithdrawFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(withdraw_fee: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.setWithdrawFee(pool, withdraw_fee);
    return();
    }

    func withdrawFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (withdrawFee: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (withdraw_fee_) = IPool.withdrawFee(pool); 
    return(withdraw_fee_,);
    }

    func setExpectedLiquidityLimit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_expected_liquidity_limit: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.setExpectedLiquidityLimit(pool, _expected_liquidity_limit); 
    return();
    }

    func expectedLiquidityLimit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (expectedLiquidityLimit: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (expected_liquidity_limit_) = IPool.expectedLiquidityLimit(pool); 
    return(expected_liquidity_limit_,);
    }

    func totalAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (totalManagedAssets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (total_assets_) = IPool.totalAssets(pool); 
    return(total_assets_,);
    }


    func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256, _receiver: felt) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.deposit(pool, _assets, _receiver); 
    return(shares_,);
    }

    func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256, _receiver: felt) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (assets_) = IPool.mint(pool, _shares, _receiver); 
    return(assets_,);
    }

    func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256, _receiver: felt, _owner: felt) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.withdraw(pool, _assets, _receiver, _owner); 
    return(shares_,);
    }

    func redeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256, _receiver: felt, _owner: felt) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (assets_) = IPool.redeem(pool, _shares, _receiver, _owner); 
    return(assets_,);
    }

    func expectedLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (expectedLiquidity: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (expected_liquidity_) = IPool.expectedLiquidity(pool); 
    return(expected_liquidity_,);
    }

    func availableLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableLiquidity: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (available_liquidity_) = IPool.availableLiquidity(pool); 
    return(available_liquidity_,);
    }


    func previewDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.previewDeposit(pool, _assets); 
    return(shares_,);
    }

    func previewMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (assets_) = IPool.previewMint(pool, _shares); 
    return(assets_,);
    }

    func previewWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.previewWithdraw(pool, _assets); 
    return(shares_,);
    }

    func previewRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (asset_) = IPool.previewRedeem(pool, _shares); 
    return(asset_,);
    }

    func maxDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxAssets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_assets_) = IPool.maxDeposit(pool, _to); 
    return(max_assets_,);
    }

    func maxMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxShares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_shares_) = IPool.maxMint(pool, _to); 
    return(max_shares_,);
    }

    func maxWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxAssets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_assets_) = IPool.maxWithdraw(pool, _to); 
    return(max_assets_,);
    }

    func maxRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxShares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_shares_) = IPool.maxRedeem(pool, _to); 
    return(max_shares_,);
    }

    // borrow stuff

    func borrow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_borrow_amount: Uint256, _drip: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.borrow(pool, _borrow_amount, _drip); 
    return();
    }

    func totalBorrowed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (totalBorrowed: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (total_borrowed_) = IPool.totalBorrowed(pool); 
    return(total_borrowed_,);
    }

    func borrowRate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (borrowRate: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (borrow_rate_) = IPool.borrowRate(pool); 
    return(borrow_rate_,);
    }

    func calcLinearCumulativeIndex{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (cumulativeIndex: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (cumulative_index_) = IPool.calcLinearCumulativeIndex(pool); 
    return(cumulative_index_,);
    }

    func cumulativeIndex{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (cumulativeIndex: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (cumulative_index_) = IPool.cumulativeIndex(pool); 
    return(cumulative_index_,);
    }

    func lastUpdatedTimestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (lastUpdatedTimestamp: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (last_updated_timestamp_) = IPool.lastUpdatedTimestamp(pool); 
    return(last_updated_timestamp_,);
    }

    func repayDripDebt{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(borrowed_amount: Uint256, profit: Uint256, loss: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.repayDripDebt(pool, borrowed_amount, profit, loss);
    return();
    }

    func connectDripManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(drip_manager: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.connectDripManager(pool, drip_manager);
    return();
    }


}

namespace morphine_pass_instance{
    func deployed() -> (morphine_pass : felt){
        tempvar morphine_pass;
        %{ ids.morphine_pass = context.morphine_pass %}
        return (morphine_pass,);
    }

    func setMinter{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_minter: felt) {
        tempvar morphine_pass;
        %{ ids.morphine_pass = context.morphine_pass %}
        IMorphinePass.setMinter(morphine_pass, _minter);
        return ();
    }

    func addDripTransit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_drip_transit: felt) {
        tempvar morphine_pass;
        %{ ids.morphine_pass = context.morphine_pass %}
        IMorphinePass.addDripTransit(morphine_pass, _drip_transit);
        return ();
    }

    func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner: felt) -> (balance: Uint256) {
    tempvar morphine_pass;
    %{ ids.morphine_pass = context.morphine_pass %}
    let (balance_) =  IMorphinePass.balanceOf(morphine_pass, owner);
    return (balance_,);
    }

    // func ownerOf(tokenId: Uint256) -> (owner: felt) {
    // }

    // func totalSupply() -> (totalSupply: Uint256) {
    // }

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

namespace erc4626_adapter_instance{
    func deployed() -> (erc4626_adapter : felt){
        tempvar erc4626_adapter;
        %{ ids.erc4626_adapter = context.erc4626_adapter %}
        return (erc4626_adapter,);
    }

    func deployedSecond() -> (erc4626_adapter_second : felt){
        tempvar erc4626_adapter_second;
        %{ ids.erc4626_adapter_second = context.erc4626_adapter_second %}
        return (erc4626_adapter_second,);
    }
}


namespace minter_instance{
    func deployed() -> (erc4626_adapter : felt){
        tempvar minter;
        %{ ids.minter = context.minter %}
        return (minter,);
    }

    func isWhitelisted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user: felt) -> (state: felt) {
        tempvar minter;
        %{ ids.minter = context.minter %}
        let (state_) = IMinter.isWhitelisted(minter, _user);
        return(state_,);
    }

    func hasMinted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user: felt) -> (state: felt) {
        tempvar minter;
        %{ ids.minter = context.minter %}
        let (state_) = IMinter.hasMinted(minter, _user);
        return(state_,);
    }

    func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
        tempvar minter;
        %{ ids.minter = context.minter %}
        IMinter.mint(minter);
        return();
    }

    func setWhitelist{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address_len: felt, address: felt*) {
        tempvar minter;
        %{ ids.minter = context.minter %}
        IMinter.setWhitelist(minter, address_len, address);
        return();
    }
}

namespace new_drip_transit_instance{
    func deployedTrue() -> (new_drip_transit : felt){
        tempvar new_drip_transit;
        %{ ids.new_drip_transit = context.new_drip_transit %}
        return (new_drip_transit,);
    }

    func deployedFalse() -> (new_drip_transit_false : felt){
        tempvar new_drip_transit_false;
        %{ ids.new_drip_transit_false = context.new_drip_transit_false %}
        return (new_drip_transit_false,);
    }

    func isIncreaseDebtForbidden{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(is_increase_debt_forbidden: felt){
        tempvar new_drip_transit;
        %{ ids.new_drip_transit = context.new_drip_transit %}
        let (is_increase_debt_forbidden_) = IDripTransit.isIncreaseDebtForbidden(new_drip_transit);
        return(is_increase_debt_forbidden_,);
    }

    func maxBorrowedAmountPerBlock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(max_borrowed_amount_per_block: Uint256){
        tempvar new_drip_transit;
        %{ ids.new_drip_transit = context.new_drip_transit %}
        let (max_borrowed_amount_per_block_) = IDripTransit.maxBorrowedAmountPerBlock(new_drip_transit);
        return(max_borrowed_amount_per_block_,);
    }

    func expirationDate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(expiration_date: felt){
        tempvar new_drip_transit;
        %{ ids.new_drip_transit = context.new_drip_transit %}
        let (expiration_date_) = IDripTransit.expirationDate(new_drip_transit);
        return(expiration_date_,);
    }

    func isExpirable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(is_expirable: felt){
        tempvar new_drip_transit;
        %{ ids.new_drip_transit = context.new_drip_transit %}
        let (is_expirable_) = IDripTransit.isExpirable(new_drip_transit);
        return(is_expirable_,);
    }

    func limits{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256){
        tempvar new_drip_transit;
        %{ ids.new_drip_transit = context.new_drip_transit %}
        let (minimum_borrowed_amount_, maximum_borrowed_amount_) = IDripTransit.limits(new_drip_transit);
        return(minimum_borrowed_amount_, maximum_borrowed_amount_,);
    }
}

namespace new_drip_configurator_instance{
    func deployedTrue() -> (new_drip_transit : felt){
        tempvar new_drip_configurator;
        %{ ids.new_drip_configurator = context.new_drip_configurator %}
        return (new_drip_configurator,);
    }

    func deployedFalse() -> (new_drip_transit_false : felt){
        tempvar new_drip_configurator_false;
        %{ ids.new_drip_configurator_false = context.new_drip_configurator_false %}
        return (new_drip_configurator_false,);
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

namespace eth_instance{
    func deployed() -> (eth : felt){
        tempvar eth;
        %{ ids.eth = context.eth %}
        return (eth,);
    }
}

namespace veth_instance{
    func deployed() -> (veth : felt){
        tempvar veth;
        %{ ids.veth = context.veth %}
        return (veth,);
    }
}

namespace rd_instance{
    func deployed() -> (rd : felt){
        tempvar rd;
        %{ ids.rd = context.rd %}
        return (rd,);
    }
}