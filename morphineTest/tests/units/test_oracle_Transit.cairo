%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp, get_caller_address
from starkware.cairo.common.alloc import alloc

// OpenZeppelin dependencies
from openzeppelin.token.erc20.IERC20 import IERC20

// Project dependencies
from morphine.interfaces.IEmpiricOracle import IEmpiricOracle
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IERC4626 import IERC4626
from morphine.utils.utils import pow



const ADMIN = 'morphine-admin';


// Token 1 ETH
const TOKEN_NAME_1 = 'ethereum';
const TOKEN_SYMBOL_1 = 'ETH';
const TOKEN_DECIMALS_1 = 18;
const TOKEN_INITIAL_SUPPLY_LO_1 = 10000000000000000000;
const TOKEN_INITIAL_SUPPLY_HI_1 = 0;

// Token 2 BTC
const TOKEN_NAME_2 = 'bitcoin';
const TOKEN_SYMBOL_2 = 'BTC';
const TOKEN_DECIMALS_2 = 18;
const TOKEN_INITIAL_SUPPLY_LO_2 = 5*10**18;
const TOKEN_INITIAL_SUPPLY_HI_2 = 0;

// Token 3 DAI
const TOKEN_NAME_3 = 'dai';
const TOKEN_SYMBOL_3 = 'DAI';
const TOKEN_DECIMALS_3 = 6;
const TOKEN_INITIAL_SUPPLY_LO_3 = 20000*10**6;
const TOKEN_INITIAL_SUPPLY_HI_3 = 0;

// Token 4 ERC4626 VETH
const TOKEN_NAME_4 = 'vethereum';
const TOKEN_SYMBOL_4 = 'VETH';

// Token 5 DYMMY
const TOKEN_NAME_5 = 'dummy';
const TOKEN_SYMBOL_5 = 'DMY';
const TOKEN_DECIMALS_5 = 19;
const TOKEN_INITIAL_SUPPLY_LO_5 = 1*10**19;
const TOKEN_INITIAL_SUPPLY_HI_5 = 0;

// Token 5 DYMMYtri
const TOKEN_NAME_6 = 'dummytri';
const TOKEN_SYMBOL_6 = 'DMYT';
const TOKEN_DECIMALS_6 = 18;
const TOKEN_INITIAL_SUPPLY_LO_6 = 1*10**18;
const TOKEN_INITIAL_SUPPLY_HI_6 = 0;

// Oracle 

const ETH_USD = 19514442401534788;
const BTC_USD = 18669995996566340;
const DAI_USD = 28254602066752356;
const DMYT_USD = 949404849;

const DECIMALS_FEED = 8;
const ETH_PRICE = 200000000000;
const BTC_PRICE = 2500000000000;
const DAI_PRICE = 100000000;
const LUT = 0;
const NSA = 0;

// Registery
const TREASURY = 'morphine_treasyury';
const ORACLE_TRANSIT = 'oracle_transit';
const DRIP_HASH = 'drip_hash';


// LP
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar eth;
    tempvar btc;
    tempvar dai;
    tempvar veth;
    tempvar dmy;
    tempvar dmyt;
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

        ids.dmy = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME_5, ids.TOKEN_SYMBOL_5, ids.TOKEN_DECIMALS_5, ids.TOKEN_INITIAL_SUPPLY_LO_5, ids.TOKEN_INITIAL_SUPPLY_HI_5, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dmy = ids.dmy

        ids.dmyt = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME_6, ids.TOKEN_SYMBOL_6, ids.TOKEN_DECIMALS_6, ids.TOKEN_INITIAL_SUPPLY_LO_6, ids.TOKEN_INITIAL_SUPPLY_HI_6, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dmyt = ids.dmyt

        # Deploying empiric oracle 

        ids.empiric_oracle = deploy_contract("./tests/mocks/empiricOracle.cairo",[]).contract_address 
        context.empiric_oracle = ids.empiric_oracle
    %}

    // Set assets value
    IEmpiricOracle.set_spot_median(empiric_oracle, ETH_USD, ETH_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, BTC_USD, BTC_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, DAI_USD, DAI_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, DAI_USD, DAI_PRICE, DECIMALS_FEED, LUT, NSA);
    IEmpiricOracle.set_spot_median(empiric_oracle, DMYT_USD, 93, 9, LUT, NSA);


    %{

        ids.registery = deploy_contract("./lib/morphine/registery.cairo", [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.DRIP_HASH]).contract_address 
        context.registery = ids.registery

        ids.erc4626_pricefeed = deploy_contract("./lib/morphine/oracle/derivativePriceFeed/erc4626.cairo", []).contract_address 
        context.erc4626_pricefeed = ids.erc4626_pricefeed

        ids.oracle_transit = deploy_contract("./lib/morphine/oracle/oracleTransit.cairo",[ids.empiric_oracle, ids.registery]).contract_address 
        context.oracle_transit = ids.oracle_transit

    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.oracle_transit, ids.eth] ] %}

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



    return();
}



@view
func test_add_primitive_price_feed_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmyt_) = dmyt_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    oracle_transit_instance.addPrimitive(dmyt_, DMYT_USD);
    return ();
}




@view
func test_add_primitive_price_feed_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="zero address or pair id") %}
    oracle_transit_instance.addPrimitive(0, DMYT_USD);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_add_primitive_price_feed_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmyt_) = dmyt_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="zero address or pair id") %}
    oracle_transit_instance.addPrimitive(dmyt_, 0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_add_primitive_price_feed_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmy_) = dmy_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="token decimals greater than 18") %}
    oracle_transit_instance.addPrimitive(dmy_, DMYT_USD);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_add_primitive_price_feed_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmyt_) = dmyt_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="price feed decimals not equal to 8") %}
    oracle_transit_instance.addPrimitive(dmyt_, DMYT_USD);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_add_primitive_price_feed_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (eth_) = eth_instance.deployed();
    %{ expect_events({"name": "NewPrimitive", "data": [ids.eth_, ids.ETH_USD],"from_address": context.oracle_transit}) %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    oracle_transit_instance.addPrimitive(eth_, ETH_USD);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_add_derivative_price_feed_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmyt_) = dmyt_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    oracle_transit_instance.addDerivative(dmyt_, DMYT_USD);
    return ();
}

@view
func test_add_derivative_price_feed_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="zero address") %}
    oracle_transit_instance.addDerivative(0, DMYT_USD);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_add_derivative_price_feed_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmyt_) = dmyt_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="zero address") %}
    oracle_transit_instance.addDerivative(dmyt_, 0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_add_derivative_price_feed_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dmy_) = dmy_instance.deployed();
    
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="token decimals greater than 18") %}
    oracle_transit_instance.addDerivative(dmy_, DMYT_USD);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_add_derivative_price_feed_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    %{ expect_revert(error_message="quote price error") %}
    oracle_transit_instance.addDerivative(veth_, 867);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_add_derivative_price_feed_6{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (veth_) = veth_instance.deployed();
    let (erc4626_pricefeed_) = erc4626_pricefeed_instance.deployed();
    %{ expect_events({"name": "NewDerivative", "data": [ids.veth_, ids.erc4626_pricefeed_],"from_address": context.oracle_transit}) %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [context.oracle_transit] ] %}
    oracle_transit_instance.addDerivative(veth_, erc4626_pricefeed_);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}



@view
func test_get_price_feed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (eth_) = eth_instance.deployed();
    let (btc_) = btc_instance.deployed();
    let (dai_) = dai_instance.deployed();
    let (veth_) = veth_instance.deployed();
    let (erc4626_pricefeed_) = erc4626_pricefeed_instance.deployed();

    let (eth_id_) = oracle_transit_instance.primitivePairId(eth_);
    let (btc_id_) = oracle_transit_instance.primitivePairId(btc_);
    let (dai_id_) = oracle_transit_instance.primitivePairId(dai_);
    let (veth_derivative_price_feed_) = oracle_transit_instance.derivativePriceFeed(veth_);
    assert eth_id_ = ETH_USD;
    assert btc_id_ = BTC_USD;
    assert dai_id_ = DAI_USD;
    assert veth_derivative_price_feed_ = erc4626_pricefeed_;
    return ();
}

@view
func test_convert{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (eth_) = eth_instance.deployed();
    let (btc_) = btc_instance.deployed();
    let (dai_) = dai_instance.deployed();
    let (veth_) = veth_instance.deployed();
    let (erc4626_pricefeed_) = erc4626_pricefeed_instance.deployed();


    let (usd_) = oracle_transit_instance.convertToUSD(Uint256(2000000000000000000,0), eth_);
    assert usd_ = Uint256(400000000000,0);

    let (usd_) = oracle_transit_instance.convertToUSD(Uint256(2000000000000000000,0), btc_);
    assert usd_ = Uint256(5000000000000,0);

    let (usd_) = oracle_transit_instance.convertToUSD(Uint256(2000000,0), dai_);
    assert usd_ = Uint256(200000000,0);

    let (usd_) = oracle_transit_instance.convertToUSD(Uint256(2000000000000000000,0), veth_);
    assert usd_ = Uint256(800000000000,0);

    let (eth_price_) = oracle_transit_instance.convertFromUSD(Uint256(400000000000,0), eth_);
    assert eth_price_ = Uint256(2000000000000000000,0);

    let (btc_price_) = oracle_transit_instance.convertFromUSD(Uint256(5000000000000,0), btc_);
    assert btc_price_ = Uint256(2000000000000000000,0);

    let (dai_price) = oracle_transit_instance.convertFromUSD(Uint256(200000000,0), dai_);
    assert dai_price = Uint256(2000000,0);

    let (veth_price_) = oracle_transit_instance.convertFromUSD(Uint256(800000000000,0), veth_);
    assert veth_price_ = Uint256(2000000000000000000,0);

    let (dai_to_eth_) = oracle_transit_instance.convert(Uint256(4000000000,0), dai_, eth_);
    assert dai_to_eth_ = Uint256(2000000000000000000,0);

    let (btc_to_veth_) = oracle_transit_instance.convert(Uint256(4000000000000000000,0), btc_, veth_);
    assert btc_to_veth_ = Uint256(25000000000000000000,0);

    let (col_from_, col_to_) = oracle_transit_instance.fastCheck(Uint256(2000000000000000000,0), eth_, Uint256(2000000000000000000,0), btc_);
    assert col_from_ = Uint256(400000000000,0);
    assert col_to_ = Uint256(5000000000000,0);

    return ();
}


namespace pool_instance{
    func deployed() -> (starkvest_contract : felt){
        tempvar starkvest_contract;
        %{ ids.starkvest_contract = context.starkvest_contract %}
        return (starkvest_contract,);
    }

}


namespace eth_instance{
    func deployed() -> (eth : felt){
        tempvar eth;
        %{ ids.eth = context.eth %}
        return (eth,);
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

namespace veth_instance{
    func deployed() -> (veth : felt){
        tempvar veth;
        %{ ids.veth = context.veth %}
        return (veth,);
    }
}

namespace dmy_instance{
    func deployed() -> (dmy : felt){
        tempvar dmy;
        %{ ids.dmy = context.dmy %}
        return (dmy,);
    }
}

namespace dmyt_instance{
    func deployed() -> (dmyt : felt){
        tempvar dmyt;
        %{ ids.dmyt = context.dmyt %}
        return (dmyt,);
    }
}

namespace erc4626_pricefeed_instance{
    func deployed() -> (erc4626_pricefeed : felt){
        tempvar erc4626_pricefeed;
        %{ ids.erc4626_pricefeed = context.erc4626_pricefeed %}
        return (erc4626_pricefeed,);
    }
}

namespace empiric_oracle_instance{
    func deployed() -> (empiric_oracle : felt){
        tempvar empiric_oracle;
        %{ ids.empiric_oracle = context.empiric_oracle %}
        return (empiric_oracle,);
    }
}

namespace oracle_transit_instance{
    func deployed() -> (oracle_transit : felt){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        return (oracle_transit,);
    }

    func addPrimitive{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token: felt, pair_id: felt){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        IOracleTransit.addPrimitive(oracle_transit, token, pair_id);
        return ();
    }

    func addDerivative{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token: felt, derivative_price_feed: felt){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        IOracleTransit.addDerivative(oracle_transit, token, derivative_price_feed);
        return ();
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

    func fastCheck{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(amount_from: Uint256, token_from: felt, amount_to: Uint256, token_to: felt) -> (collateralFrom: Uint256, collateralTo: Uint256) {
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        let (collateral_from_, collateral_to_) = IOracleTransit.fastCheck(oracle_transit, amount_from, token_from, amount_to, token_to);
        return (collateral_from_, collateral_to_,);
    }

    func convertFromUSD{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(amount: Uint256, token: felt) -> (token_price: Uint256){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        let (token_price_) = IOracleTransit.convertFromUSD(oracle_transit, amount, token);
        return (token_price_,);
    }

    func convertToUSD{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(amount: Uint256, token: felt) -> (token_price_usd: Uint256){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        let (token_price_usd_) = IOracleTransit.convertToUSD(oracle_transit, amount, token);
        return (token_price_usd_,);
    }

    func convert{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(amount: Uint256, token_from: felt, token_to: felt) -> (amount_to: Uint256){
        tempvar oracle_transit;
        %{ ids.oracle_transit = context.oracle_transit %}
        let (amount_to_) = IOracleTransit.convert(oracle_transit, amount, token_from, token_to);
        return (amount_to_,);
    }

}