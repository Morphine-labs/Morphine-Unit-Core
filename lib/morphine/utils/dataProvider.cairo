// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc20.IERC20 import IERC20
from morphine.interfaces.IFaucet import IFaucet
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IInterestRateModel import IInterestRateModel

/// @title: Data Provider
/// @author: Graff Sacha (0xSacha)
/// @dev: Helper conract to get useful data from Morphine
/// @custom:experimental This is an experimental contract. LP Pricing to think.

struct FaucetInfo {
    token_address: felt,  
    user_balance: Uint256,  
    remaining_time: felt,
}


struct PoolInfo {
    pool_address: felt,
    name: felt,
    symbol: felt,
    asset: felt,
    borrow_rate: Uint256,
    supply_rate: Uint256,  
    total_assets: Uint256,  
    liquidity_limit: Uint256,
    total_borrowed: Uint256,
    utilization: Uint256,
    optimalLiquidityUtilization: Uint256,
    baseRate: Uint256,
    slope1: Uint256,
    slope2: Uint256,
}

//
// Getters
//

// @notice: Get the token address
// @return: Token address
@view
func getFaucetInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, faucet_array_len: felt, faucet_array: felt*) -> (
    faucetInfo_len: felt, faucetInfo: FaucetInfo*
) {
    alloc_locals;
    let (faucet_info: FaucetInfo*) = alloc();
    recursive_faucet_info(_user, faucet_array_len, faucet_array, faucet_info);
    return (faucet_array_len, faucet_info,);
}


func recursive_faucet_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, faucet_array_len: felt, faucet_array: felt*, faucet_info: FaucetInfo*) {
    alloc_locals;
    if(faucet_array_len == 0){
        return();
    }
    let (token_address_) = IFaucet.get_token_address(faucet_array[0]);
    assert faucet_info[0].token_address = token_address_;

    let (user_balance_) = IERC20.balanceOf(token_address_, _user);
    assert faucet_info[0].user_balance = user_balance_;

    let (state_) = IFaucet.isAllowedForTransaction(faucet_array[0], _user);

    if(state_ == 1){
        assert faucet_info[0].remaining_time = 0;
        return recursive_faucet_info(_user, faucet_array_len - 1, faucet_array + 1, faucet_info + FaucetInfo.SIZE);
    }   else {
        let (allowed_time_) = IFaucet.get_allowed_time(faucet_array[0], _user);
        let (block_timestamp_) = get_block_timestamp();
        let remaining_time_ = allowed_time_ - block_timestamp_;
        assert faucet_info[0].remaining_time = remaining_time_;
        return recursive_faucet_info(_user, faucet_array_len - 1, faucet_array + 1, faucet_info + FaucetInfo.SIZE);
    }
}


@view
func poolListInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt) -> (
    pool_info_len: felt, pool_info: PoolInfo*
) {
    alloc_locals;
    let (pool_info: PoolInfo*) = alloc();
    let (pool_info_len:felt) = IRegistery.poolsLength(_registery);
    recursive_pool_info(_registery, pool_info_len, 0, pool_info);
    return (pool_info_len, pool_info,);
}

func recursive_pool_list_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, pool_info_len: felt, _index: felt, pool_info: PoolInfo*) {
    alloc_locals;
    if(_index == pool_info_len){
        return();
    }

    let (pool_) = IRegistery.idToPool(_registery, _index)
    let (poolInfo_) = poolInfo(pool_);
    pool_info[index] = poolInfo_;
    return recursive_pool_list_info(_registery, pool_info_len, _index + 1, pool_info);
}


@view
func poolInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    pool_info: PoolInfo
) {
    alloc_locals;
    let (name_) = IPool.name(_pool);
    let (symbol_) = IPool.symbol(_pool);
    let (asset_) = IPool.asset(_pool);
    let (borrow_rate_) = IPool.borrowRate(_pool);
    let (total_assets_) = IPool.totalAssets();
    let (liquidity_limit_) = IPool.expectedLiquidityLimit();
    let (total_borrowed_) = IPool.totalBorrowed();
    let (total_assets_precision_) = SafeUint256.unsigned_div_rem();
    let (utilization_,_)= SafeUint256.unsigned_div_rem(total_assets_precision_, total_borrowed_);

    let (interest_rate_model_) = IPool.interestRateModel(_pool);
    let (modelParameters_) = IInterestRateModel.modelParameters(interest_rate_model_);
    
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    let (fee_interest_) = IDripManager.feeInterest(drip_manager_);
    let (fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);
    let (fee_liqudidation_expired_) = IDripManager.feeLiquidationExpired(drip_manager_);
    let (liquidation_discount_) = IDripManager.liquidationDiscount();
    let (liquidation_discount_expired_) = IDripManager.liquidationDiscountExpired();








    return (pool_info_len, pool_info,);
}

struct PoolInfo {
    pool_address: felt,
    name: felt,
    symbol: felt,
    asset: felt,
    borrow_rate: Uint256,  
    total_assets: Uint256,  
    liquidity_limit: Uint256,
    total_borrowed: Uint256,
    utilization: Uint256,

    interest_rate_model: felt,
    optimalLiquidityUtilization: Uint256,
    baseRate: Uint256,
    slope1: Uint256,
    slope2: Uint256,

    drip_manager: felt,
    expirable: felt,
    remaining_time: felt,
    
    fee_interest: Uint256,
    fee_liqudidation: Uint256,
    fee_liqudidation_expired: Uint256,
    liquidation_discount: Uint256,
    liquidation_discount_expired: Uint256,

    assets_list_len: felt,
    assets_list: 

    supply_rate: Uint256,

}

func recursive_pool_list_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, pool_info_len: felt, _index: felt, pool_info: PoolInfo*) {
    alloc_locals;
    if(_index == pool_info_len){
        return();
    }
    let (pool_) = IRegistery.idToPool(_registery, _index)


    let (token_address_) = IFaucet.get_token_address(faucet_array[0]);
    assert faucet_info[0].token_address = token_address_;

    let (user_balance_) = IERC20.balanceOf(token_address_, _user);
    assert faucet_info[0].user_balance = user_balance_;

    let (state_) = IFaucet.isAllowedForTransaction(faucet_array[0], _user);

    if(state_ == 1){
        assert faucet_info[0].remaining_time = 0;
        return recursive_faucet_info(_user, faucet_array_len - 1, faucet_array + 1, faucet_info + FaucetInfo.SIZE);
    }   else {
        let (allowed_time_) = IFaucet.get_allowed_time(faucet_array[0], _user);
        let (block_timestamp_) = get_block_timestamp();
        let remaining_time_ = allowed_time_ - block_timestamp_;
        assert faucet_info[0].remaining_time = remaining_time_;
        return recursive_faucet_info(_user, faucet_array_len - 1, faucet_array + 1, faucet_info + FaucetInfo.SIZE);
    }
}