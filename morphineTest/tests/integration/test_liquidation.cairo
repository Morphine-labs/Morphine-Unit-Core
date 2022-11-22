
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
from morphine.interfaces.IDripInfraFactory import IDripInfraFactory
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IDripConfigurator import IDripConfigurator, AllowedToken
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IDripTransit import IDripTransit, AccountCallArray
from morphine.interfaces.IERC4626 import IERC4626
from morphine.utils.utils import pow

from morphine.utils.various import DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, PRECISION, DEFAULT_FEE_LIQUIDATION, DEFAULT_FEE_LIQUIDATION_EXPIRED, DEFAULT_FEE_LIQUIDATION_EXPIRED_PREMIUM, DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER



const ADMIN = 'morphine-admin';
const USER_1 = 'user-1';

// NFT
const PASS_TOKEN_NAME = 'morphine_pool_access';
const PASS_TOKEN_SYMBOL = 'MPA';


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

    
    tempvar interest_rate_model_contract;
    tempvar pool;
    tempvar nft;
  
    %{
        ids.interest_rate_model_contract = deploy_contract("./lib/morphine/pool/linearInterestRateModel.cairo", [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract

        ids.pool = deploy_contract("./lib/morphine/pool/pool.cairo", [context.registery, context.dai, ids.ERC4626_NAME, ids.ERC4626_SYMBOL, ids.EXPECTED_LIQUIDITY_LIMIT_LO, ids.EXPECTED_LIQUIDITY_LIMIT_HI, ids.interest_rate_model_contract]).contract_address 
        context.pool = ids.pool    

        ids.nft = deploy_contract("./lib/morphine/token/morphinePass.cairo", [ids.PASS_TOKEN_NAME, ids.PASS_TOKEN_SYMBOL, context.registery]).contract_address 
        context.nft = ids.nft  
    %}


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
    let (nft_) = nft_instance.deployed();
    drip_infra_factory_instance.deployDripInfra(pool_, nft_, 1, Uint256(MINIMUM_BORROWED_AMOUNT_LO,MINIMUM_BORROWED_AMOUNT_HI), Uint256(MAXIMUM_BORROWED_AMOUNT_LO,MAXIMUM_BORROWED_AMOUNT_HI), 2, allowed_assets, 0);
    let (a1_, a2_, a3_) = drip_infra_factory_instance.getDripInfraAddresses();
    %{
        context.drip_manager = ids.a1_
        context.drip_transit = ids.a2_
        context.drip_configurator = ids.a3_
    %}

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

        ids.new_drip_transit = deploy_contract("./lib/morphine/drip/dripTransit.cairo", [context.drip_manager, context.nft, 1]).contract_address
        context.new_drip_transit = ids.new_drip_transit

        ids.new_drip_transit_false = deploy_contract("./lib/morphine/drip/dripTransit.cairo", [context.dummy_drip_manager, context.nft, 1]).contract_address
        context.new_drip_transit_false = ids.new_drip_transit_false

        ids.new_drip_configurator = deploy_contract("./lib/morphine/drip/dripConfiguratorSideline.cairo", [context.drip_manager]).contract_address
        context.new_drip_configurator = ids.new_drip_configurator

        ids.new_drip_configurator_false = deploy_contract("./lib/morphine/drip/dripConfiguratorSideline.cairo", [context.dummy_drip_manager]).contract_address
        context.new_drip_configurator_false = ids.new_drip_configurator_false


    %}
    return();
}



@view
func test_setup{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dai_) = dai_instance.deployed();
    let (eth_) = eth_instance.deployed();
    let (veth_) = veth_instance.deployed();
    let (drip_transit_) = drip_transit_instance.deployed();
    let (oracle_transit_) = oracle_transit_instance.deployed();
    let (fee_interest_) = drip_manager_instance.feeInterest();
    let (fee_liqudidation_) = drip_manager_instance.feeLiquidation();    
    let (fee_liqudidation_expired_) = drip_manager_instance.feeLiquidationExpired();
    let (liquidation_discount_) = drip_manager_instance.liquidationDiscount();
    let (liquidation_discount_expired_) = drip_manager_instance.liquidationDiscountExpired();
    assert fee_interest_ = Uint256(DEFAULT_FEE_INTEREST,0);
    assert fee_liqudidation_ = Uint256(DEFAULT_FEE_LIQUIDATION,0);
    assert fee_liqudidation_expired_ = Uint256(DEFAULT_FEE_LIQUIDATION_EXPIRED,0);
    assert liquidation_discount_ = Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM,0);
    assert liquidation_discount_expired_ = Uint256(PRECISION - DEFAULT_FEE_LIQUIDATION_EXPIRED_PREMIUM,0);
    let (underlying_) = drip_manager_instance.underlying();
    assert underlying_ = dai_;
    let (token_mask1_) = drip_manager_instance.tokenMask(dai_);
    assert token_mask1_ = Uint256(1,0);
    let (token_mask2_) = drip_manager_instance.tokenMask(eth_);
    assert token_mask2_ = Uint256(2,0);
    let (token_mask3_) = drip_manager_instance.tokenMask(veth_);
    assert token_mask3_ = Uint256(4,0);
    let (allowed_token_length_) = drip_manager_instance.allowedTokensLength();
    assert allowed_token_length_ = 3;
    let (forbidden_token_mask_) = drip_manager_instance.forbiddenTokenMask();
    assert (forbidden_token_mask_) = Uint256(0,0);
    let (token_from_mask1_) = drip_manager_instance.tokenByMask(Uint256(1,0));
    assert token_from_mask1_ = dai_;
    let (token_from_mask2_) = drip_manager_instance.tokenByMask(Uint256(2,0));
    assert token_from_mask2_ = eth_;
    let (token_from_mask3_) = drip_manager_instance.tokenByMask(Uint256(4,0));
    assert token_from_mask3_ = veth_;
    let (token_from_id1_) = drip_manager_instance.tokenById(0);
    assert token_from_id1_ = dai_;
    let (token_from_id2_) = drip_manager_instance.tokenById(1);
    assert token_from_id2_ = eth_;
    let (token_from_id3_) = drip_manager_instance.tokenById(2);
    assert token_from_id3_ = veth_;
    let (liquidation_threshold1_) = drip_manager_instance.liquidationThreshold(dai_);
    assert liquidation_threshold1_ = Uint256(liquidation_discount_.low - DEFAULT_FEE_LIQUIDATION, 0);
    let (liquidation_threshold2_) = drip_manager_instance.liquidationThreshold(eth_);
    assert liquidation_threshold2_ = Uint256(ETH_LT_LOW, ETH_LT_HIGH);
    let (liquidation_threshold3_) = drip_manager_instance.liquidationThreshold(veth_);
    assert liquidation_threshold3_ = Uint256(VETH_LT_LOW, VETH_LT_HIGH);
    let (liquidation_threshold_from_mask1_) = drip_manager_instance.liquidationThresholdByMask(Uint256(1,0));
    assert liquidation_threshold_from_mask1_ = Uint256(liquidation_discount_.low - DEFAULT_FEE_LIQUIDATION, 0);
    let (liquidation_threshold_from_mask2_) = drip_manager_instance.liquidationThresholdByMask(Uint256(2,0));
    assert liquidation_threshold_from_mask2_ = Uint256(ETH_LT_LOW, ETH_LT_HIGH);
    let (liquidation_threshold_from_mask3_) = drip_manager_instance.liquidationThresholdByMask(Uint256(4,0));
    assert liquidation_threshold_from_mask3_ = Uint256(VETH_LT_LOW, VETH_LT_HIGH);
    let (liquidation_threshold_from_id1_) = drip_manager_instance.liquidationThresholdById(0);
    assert liquidation_threshold_from_id1_ = Uint256(liquidation_discount_.low - DEFAULT_FEE_LIQUIDATION, 0);
    let (liquidation_threshold_from_id2_) = drip_manager_instance.liquidationThresholdById(1);
    assert liquidation_threshold_from_id2_ = Uint256(ETH_LT_LOW, ETH_LT_HIGH);
    let (liquidation_threshold_from_id3_) = drip_manager_instance.liquidationThresholdById(2);
    assert liquidation_threshold_from_id3_ = Uint256(VETH_LT_LOW, VETH_LT_HIGH);
    let (drip_transit_from_drip_manager_) = drip_manager_instance.dripTransit();
    assert drip_transit_from_drip_manager_ = drip_transit_;
    let (oracle_transit_from_drip_manager_) = drip_manager_instance.oracleTransit();
    assert oracle_transit_from_drip_manager_ = oracle_transit_;
    let (minimum_borrowed_amount_, maximum_borrowed_amount_) = drip_transit_instance.limits();
    assert minimum_borrowed_amount_ = Uint256(MINIMUM_BORROWED_AMOUNT_LO, MINIMUM_BORROWED_AMOUNT_HI);
    assert maximum_borrowed_amount_ = Uint256(MAXIMUM_BORROWED_AMOUNT_LO, MAXIMUM_BORROWED_AMOUNT_HI);
    let (limit_per_block_) = drip_transit_instance.maxBorrowedAmountPerBlock();
    assert limit_per_block_ = Uint256(MAXIMUM_BORROWED_AMOUNT_LO * DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER, 0);
    let (is_increase_debt_forbidden_) = drip_transit_instance.isIncreaseDebtForbidden();
    assert is_increase_debt_forbidden_ = 0;
    let (expiration_date_) = drip_transit_instance.expirationDate();
    assert expiration_date_ = 0;
    return();
}

namespace drip_configurator_instance{
    func deployed() -> (drip_configurator : felt){
        tempvar drip_configurator;
        %{ ids.drip_configurator = context.drip_configurator %}
        return (drip_configurator,);
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
        IDripTransit.approveDripTransfers(_from, _state);
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

    func limits{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() ->(minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256){
        tempvar drip_transit;
        %{ ids.drip_transit = context.drip_transit %}
        let (minimum_borrowed_amount_, maximum_borrowed_amount_) = IDripTransit.limits(drip_transit);
        return(minimum_borrowed_amount_, maximum_borrowed_amount_,);
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

namespace pool_instance{
    func deployed() -> (pool : felt){
        tempvar pool;
        %{ ids.pool = context.pool %}
        return (pool,);
    }
}

namespace nft_instance{
    func deployed() -> (nft : felt){
        tempvar nft;
        %{ ids.nft = context.nft %}
        return (nft,);
    }
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