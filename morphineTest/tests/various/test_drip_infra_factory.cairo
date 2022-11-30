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


const ADMIN = 'morphine-admin';
const USER_1 = 'user-1';
const DRIP = 'drip';
const DRIP_MANAGER = 'drip-manager';

// Token 
const TOKEN_NAME = 'dai';
const TOKEN_SYMBOL = 'DAI';
const TOKEN_DECIMALS = 6;
const TOKEN_INITIAL_SUPPLY_LO = 1000000000000;
const TOKEN_INITIAL_SUPPLY_HI = 0;

// LinearRateModel
const SLOPE1_LO = 15*10**15;
const SLOPE1_HI = 0;
const SLOPE2_LO = 1*10**18; 
const SLOPE2_HI = 0; 
const BASE_RATE_LO =  0;
const BASE_RATE_HI =  0;
const OPTIMAL_RATE_LO = 80*10**16; 
const OPTIMAL_RATE_HI = 0; 


// Registery
const TREASURY = 'morphine_treasyury';
const ORACLE_TRANSIT = 'oracle_transit';
const DRIP_HASH = 'drip_hash';

// Pool
const ERC4626_NAME = 'Mdai';
const ERC4626_SYMBOL = 'MDAI';
const EXPECTED_LIQUIDITY_LIMIT_LO = 1000000*10**6;
const EXPECTED_LIQUIDITY_LIMIT_HI = 0;


@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;

    tempvar dai;
    tempvar interest_rate_model_contract;
    tempvar registery_contract;
    tempvar pool;

    %{
        ids.dai = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME, ids.TOKEN_SYMBOL, ids.TOKEN_DECIMALS, ids.TOKEN_INITIAL_SUPPLY_LO, ids.TOKEN_INITIAL_SUPPLY_HI, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dai = ids.dai

        ids.interest_rate_model_contract = deploy_contract(
            "./lib/morphine/pool/linearInterestRateModel.cairo", 
            [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract

        ids.registery_contract = deploy_contract(
            "./lib/morphine/registery.cairo", 
            [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.DRIP_HASH]).contract_address 
        context.registery_contract = ids.registery_contract

        ids.pool = deploy_contract("./lib/morphine/pool/pool.cairo", [ids.registery_contract, ids.dai, ids.ERC4626_NAME, ids.ERC4626_SYMBOL, ids.EXPECTED_LIQUIDITY_LIMIT_LO, ids.EXPECTED_LIQUIDITY_LIMIT_HI, ids.interest_rate_model_contract]).contract_address 
        context.pool = ids.pool    
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

    return();
}



@view
func test_drip_infra_factory{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (dif_) = drip_infra_factory_instance.deployed();
    let (array1_: felt*) = alloc();
    let (allowed_tokens: AllowedToken*) = alloc();
    let (pool_) = pool_instance.deployed();
    drip_infra_factory_instance.deployDripInfra(pool_, 2, 0, Uint256(0,0), Uint256(10000,0), 0, allowed_tokens, 0);
    let (a1_, a2_, a3_) = drip_infra_factory_instance.getDripInfraAddresses();

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