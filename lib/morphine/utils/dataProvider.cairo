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
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IDripConfigurator import IDripConfigurator
from morphine.interfaces.IDripTransit import IDripTransit
from morphine.interfaces.IInterestRateModel import IInterestRateModel
from morphine.interfaces.IDataProvider import IDataProvider, PoolInfo, FaucetInfo, AllowedToken, FeesInfo, TokenInfo, PoolTokenInfo, NftInfo, DripMiniInfo, DripListInfo, MinterInfo
from morphine.interfaces.IMorphinePass import IMorphinePass
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IMinter import IMinter

from starkware.cairo.common.uint256 import ALL_ONES, uint256_eq, uint256_lt, uint256_le

from morphine.utils.various import PRECISION, DEFAULT_FEE_INTEREST
from morphine.utils.utils import pow

/// @title: Data Provider
/// @author: Graff Sacha (0xSacha)
/// @dev: Helper conract to get useful data from Morphine
/// @custom:experimental This is an experimental contract




//
// Getters
//

// @notice: getFaucetInfo
// @return: faucetInfo_len: array len
// @return: faucetInfo: Faucet Info Pointer
@view
func getFaucetInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, faucet_array_len: felt, faucet_array: felt*) -> (
    faucetInfo_len: felt, faucetInfo: FaucetInfo*
) {
    alloc_locals;
    let (faucet_info: FaucetInfo*) = alloc();
    recursive_faucet_info(_user, faucet_array_len, faucet_array, faucet_info);
    return (faucet_array_len, faucet_info,);
}

// @notice: recursive_faucet_info
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
func getMinterInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, minter_array_len: felt, minter_array: felt*) -> (
    minterInfo_len: felt, minterInfo: MinterInfo*
) {
    alloc_locals;
    let (minter_info: MinterInfo*) = alloc();
    recursive_minter_info(_user, minter_array_len, minter_array, minter_info);
    return (minter_array_len, minter_info,);
}

// @notice: recursive_faucet_info
func recursive_minter_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, minter_array_len: felt, minter_array: felt*, minter_info: MinterInfo*) {
    alloc_locals;
    if(minter_array_len == 0){
        return();
    }
    let (nft_address_) = IMinter.nftContract(minter_array[0]);
    let (token_uri_) = IMorphinePass.baseURI(nft_address_);
    let (is_wl_) = IMinter.isWhitelisted(minter_array[0], _user);
    let (has_minted_) = IMinter.hasMinted(minter_array[0], _user);
    assert minter_info.token_address = nft_address_;
    assert minter_info.token_uri = token_uri_;
    assert minter_info.minter_address = minter_array[0];
    assert minter_info.is_whitelisted = is_wl_;
    assert minter_info.has_minted = has_minted_;
    return recursive_minter_info(_user, minter_array_len - 1, minter_array + 1, minter_info + MinterInfo.SIZE);
}

@view
func getUserTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, _user: felt, token_array_len: felt, token_array: felt*) -> (
    tokenInfo_len: felt, tokenInfo: TokenInfo*
) {
    alloc_locals;
    let (oracle_transit_) = IRegistery.oracleTransit(_registery);
    let (user_tokens: TokenInfo*) = alloc();
    let (user_tokens_len) = recursive_token_info(oracle_transit_, _user, token_array_len, token_array, 0, user_tokens);
    return (user_tokens_len, user_tokens,);
}

func recursive_token_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_oracle_transit: felt, _user: felt, token_array_len: felt, token_array: felt*, token_info_len: felt, token_info: TokenInfo*) ->(token_info_len: felt) {
    alloc_locals;
    if(token_array_len == 0){
        return(token_info_len,);
    }

    let (user_balance_) = IERC20.balanceOf(token_array[0], _user);
    let (state_) = uint256_le(Uint256(1,0), user_balance_);

    if(state_ == 1){
        assert token_info[0].token_address = token_array[0];
        assert token_info[0].user_balance = user_balance_;
        let (token_value_) = IOracleTransit.convertToUSD(_oracle_transit, user_balance_, token_array[0]);
        assert token_info[0].value = token_value_;
        return recursive_token_info(_oracle_transit, _user, token_array_len - 1, token_array + 1, token_info_len + 1, token_info + TokenInfo.SIZE);
    }   else {
        return recursive_token_info(_oracle_transit, _user, token_array_len - 1, token_array + 1, token_info_len , token_info);
    }
}

@view
func getUserPoolTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, _user: felt, pool_token_array_len: felt, pool_token_array: felt*) -> (
    PoolTokenInfo_len: felt, PoolTokenInfo: PoolTokenInfo*
) {
    alloc_locals;
    let (oracle_transit_) = IRegistery.oracleTransit(_registery);
    let (user_pool_tokens: PoolTokenInfo*) = alloc();
    let (user_pool_tokens_len) = recursive_pool_token_info(oracle_transit_, _user, pool_token_array_len, pool_token_array, 0, user_pool_tokens);
    return (user_pool_tokens_len, user_pool_tokens,);
}

// @notice: recursive pool_token
func recursive_pool_token_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_oracle_transit: felt, _user: felt, pool_token_array_len: felt, pool_token_array: felt*, pool_token_info_len: felt, pool_token_info: PoolTokenInfo*) ->(pool_token_info_len: felt) {
    alloc_locals;
    if(pool_token_array_len == 0){
        return(pool_token_info_len,);
    }
    let (user_balance_) = IERC20.balanceOf(pool_token_array[0], _user);
    let (state_) = uint256_le(Uint256(1,0), user_balance_);

    if(state_ == 1){
        assert pool_token_info[0].token_address = pool_token_array[0];
        assert pool_token_info[0].user_balance = user_balance_;
        let (pool_token_value_) = IOracleTransit.convertToUSD(_oracle_transit, user_balance_, pool_token_array[0]);
        assert pool_token_info[0].value = pool_token_value_;
        let (borrow_rate_) = IPool.borrowRate(pool_token_array[0]);
        let (total_assets_) = IPool.totalAssets(pool_token_array[0]);
        if(total_assets_.low == 0){
            assert pool_token_info[0].apr = Uint256(0,0);
            return recursive_pool_token_info(_oracle_transit, _user, pool_token_array_len - 1, pool_token_array + 1, pool_token_info_len + 1, pool_token_info + PoolTokenInfo.SIZE,);
        } else {
            let (total_borrowed_) = IPool.totalBorrowed(pool_token_array[0]);
            let (total_borrowed_precision_) = SafeUint256.mul(total_borrowed_, Uint256(PRECISION,0));
            let (utilization_,_)= SafeUint256.div_rem(total_borrowed_precision_, total_assets_);
            let (step1_) = SafeUint256.mul(borrow_rate_, Uint256(PRECISION - DEFAULT_FEE_INTEREST,0));
            let (step2_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
            let (step3_) = SafeUint256.mul(step2_, utilization_);
            let (step4_,_) = SafeUint256.div_rem(step3_, Uint256(PRECISION,0));
            assert pool_token_info[0].apr = step4_;
            return recursive_pool_token_info(_oracle_transit, _user, pool_token_array_len - 1, pool_token_array + 1, pool_token_info_len + 1, pool_token_info + PoolTokenInfo.SIZE,);
        }
    }   else {
        return recursive_pool_token_info(_oracle_transit, _user, pool_token_array_len - 1, pool_token_array + 1, pool_token_info_len , pool_token_info,);
    }
}


@view
func getUserPass{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, nft_len: felt, nft: felt*) -> (
    hasNft_len: felt, hasNft: NftInfo*
) {
    alloc_locals;
    let (nft_info: NftInfo*) = alloc();
    let (nft_info_len) = recursive_nft_info(_user, nft_len, nft, 0, nft_info);
    return (nft_info_len, nft_info,);
}

// @notice: recursive_faucet_info
func recursive_nft_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_user: felt, nft_array_len: felt, nft_array: felt*, has_nft_len: felt, has_nft: NftInfo*) ->(has_nft_len: felt) {
    alloc_locals;
    if(nft_array_len == 0){
        return(has_nft_len,);
    }
    let (user_balance_) = IMorphinePass.balanceOf(nft_array[0], _user);
    let (uri_) = IMorphinePass.baseURI(nft_array[0]);
    let (state_) = uint256_le(Uint256(1,0), user_balance_);

    if(state_ == 1){
        assert has_nft[0].token_address = nft_array[0];
        assert has_nft[0].has_token = 1;
        assert has_nft[0].uri = uri_;
        return recursive_nft_info(_user, nft_array_len - 1, nft_array + 1, has_nft_len + 1, has_nft + NftInfo.SIZE,);
    }   else {
        return recursive_nft_info(_user, nft_array_len - 1, nft_array + 1, has_nft_len , has_nft,);
    }
}

@view
func getUserDripsInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, _user: felt) -> (
    dripInfo_len: felt, dripInfo: DripMiniInfo*
) {
    alloc_locals;
    let (drip_info: DripMiniInfo*) = alloc();
    let (pool_info_len:felt) = IRegistery.poolsLength(_registery);
    let (drip_info_len: felt) = recursive_drip_info(_registery, _user, pool_info_len, 0, 0, drip_info);
    return (drip_info_len, drip_info,);
}

func recursive_drip_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, _user: felt, pool_info_len: felt, _index: felt, drip_info_len: felt, drip_info: DripMiniInfo*) -> (drip_info_len: felt) {
    alloc_locals;
    if(_index == pool_info_len){
        return(drip_info_len,);
    }
    let (pool_) = IRegistery.idToPool(_registery, _index);
    let (asset_) = IPool.asset(pool_);
    let (drip_manager_) = IPool.connectedDripManager(pool_);
    if(drip_manager_ == 0) {
        return recursive_drip_info(_registery, _user, pool_info_len, _index + 1, drip_info_len, drip_info);
    } else {
        let (drip_) = IDripManager.getDrip(drip_manager_, _user);
        if(drip_ == 0){
            return recursive_drip_info(_registery, _user, pool_info_len, _index + 1, drip_info_len, drip_info);
        } else {    
            let (_, _, due_amount_) = IDripManager.calcDripAccruedInterest(drip_manager_, drip_);
            let (drip_transit_) = IDripManager.dripTransit(drip_manager_);
            let (total_, twv_ )  = IDripTransit.calcTotalValue(drip_transit_, drip_);
            let (hf_ )  = IDripTransit.calcDripHealthFactor(drip_transit_, drip_);
            let (remaining_) = SafeUint256.sub_le(total_, due_amount_);
            assert drip_info[0].token_address = asset_;
            assert drip_info[0].total_balance = total_;
            assert drip_info[0].user_balance = remaining_;
            assert drip_info[0].health_factor = hf_;
            return recursive_drip_info(_registery, _user, pool_info_len, _index + 1, drip_info_len + 1, drip_info + DripMiniInfo.SIZE);
            
        }
    }
}

@view
func dripListInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt) -> (
    dripListInfo_len: felt, dripListInfo: DripListInfo*
) {
    alloc_locals;
    let (drip_list_info: DripListInfo*) = alloc();
    let (pool_info_len:felt) = IRegistery.poolsLength(_registery);
    let (oracle_transit_) = IRegistery.oracleTransit(_registery);
    let (drip_list_info_len:felt) = recursive_drip_list_info(_registery, oracle_transit_, pool_info_len, 0, 0, drip_list_info);
    return (drip_list_info_len, drip_list_info,);
}

func recursive_drip_list_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, _oracle_transit: felt ,pool_info_len: felt, _index: felt, drip_list_info_len: felt, drip_list_info: DripListInfo*) -> (drip_list_info_len: felt){
    alloc_locals;
    if(_index == pool_info_len){
        return(drip_list_info_len,);
    }
    let (pool_) = IRegistery.idToPool(_registery, _index);
    let (borrow_rate_) = IPool.borrowRate(pool_);
    let (asset_) = IPool.asset(pool_);
    let (available_liquidity_) = IPool.availableLiquidity(pool_);
    let (available_liquidity_usd_) = IOracleTransit.convertToUSD(_oracle_transit, available_liquidity_, asset_);
    let (drip_manager_) = IPool.connectedDripManager(pool_);
    if(drip_manager_ == 0){
        return recursive_drip_list_info(_registery, _oracle_transit, pool_info_len, _index + 1, drip_list_info_len, drip_list_info);
    } else {
        let (drip_transit_) = IDripManager.dripTransit(drip_manager_);
        let (nft_) = IDripTransit.getNft(drip_transit_);
        assert drip_list_info[0].token_address = asset_;
        assert drip_list_info[0].nft = nft_;
        assert drip_list_info[0].borrow_rate = borrow_rate_;
        assert drip_list_info[0].pool_liq = available_liquidity_;
        assert drip_list_info[0].pool_liq_usd = available_liquidity_usd_;
        return recursive_drip_list_info(_registery, _oracle_transit, pool_info_len, _index + 1, drip_list_info_len + 1, drip_list_info + DripListInfo.SIZE);
    }
}


@view
func poolListInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt) -> (
    pool_info_len: felt, pool_info: PoolInfo*
) {
    alloc_locals;
    let (pool_info: PoolInfo*) = alloc();
    let (pool_info_len:felt) = IRegistery.poolsLength(_registery);
    recursive_pool_list_info(_registery, pool_info_len, 0, pool_info);
    return (pool_info_len, pool_info,);
}

func recursive_pool_list_info{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt, pool_info_len: felt, _index: felt, pool_info: PoolInfo*) {
    alloc_locals;
    if(_index == pool_info_len){
        return();
    }

    let (pool_) = IRegistery.idToPool(_registery, _index);
    let (poolInfo_ : PoolInfo) = poolInfo(pool_);
    assert pool_info[_index] = poolInfo_;
    return recursive_pool_list_info(_registery, pool_info_len, _index + 1, pool_info);
}

// @notice: poolInfo
// @return: pool_info: Struct containing all info concenring a Pool
@view
func poolInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    pool_info: PoolInfo
) {
    alloc_locals;
    let (name_) = IPool.name(_pool);
    let (symbol_) = IPool.symbol(_pool);
    let (asset_) = IPool.asset(_pool);
    let (borrow_rate_) = IPool.borrowRate(_pool);
    let (total_assets_) = IPool.totalAssets(_pool);
    let (liquidity_limit_) = IPool.expectedLiquidityLimit(_pool);
    let (total_borrowed_) = IPool.totalBorrowed(_pool);
    let (total_borrowed_precision_) = SafeUint256.mul(total_borrowed_, Uint256(PRECISION,0));
    let (interest_rate_model_) = IPool.interestRateModel(_pool);
    let (optimal_liquidity_utilization_, base_rate_, slop1_, slop2_) = IInterestRateModel.modelParameters(interest_rate_model_);
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    let (registery_) = IPool.getRegistery(_pool);
    let (treasury_) = IRegistery.getTreasury(registery_);
    let (oracle_transit_) = IRegistery.oracleTransit(registery_);
    let (treasury_balance_lp_) = IPool.balanceOf(_pool, treasury_);
    let (treasury_balance_underlying_) = IPool.convertToAssets(_pool, treasury_balance_lp_);
    let (insurrance_value_) = IOracleTransit.convertToUSD(oracle_transit_, treasury_balance_underlying_, asset_);
    let (tvl_) = IOracleTransit.convertToUSD(oracle_transit_, total_assets_, asset_);
    let (underlying_decimals_) = IPool.decimals(_pool);
    let (one_underlying_unit_) = pow(10, underlying_decimals_);
    let (share_price_) = IPool.previewDeposit(_pool, Uint256(one_underlying_unit_,0));

    if(total_assets_.low == 0){
        return (PoolInfo(_pool, name_, symbol_, asset_, borrow_rate_, borrow_rate_, share_price_, tvl_, insurrance_value_,total_assets_, liquidity_limit_, total_borrowed_, Uint256(0,0), interest_rate_model_, optimal_liquidity_utilization_, base_rate_, slop1_, slop2_, drip_manager_),);
    } else {
        let (utilization_,_)= SafeUint256.div_rem(total_borrowed_precision_, total_assets_);
        let (step1_) = SafeUint256.mul(borrow_rate_, Uint256(PRECISION - DEFAULT_FEE_INTEREST,0));
        let (step2_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
        let (step3_) = SafeUint256.mul(step2_, utilization_);
        let (step4_,_) = SafeUint256.div_rem(step3_, Uint256(PRECISION,0));
        return (PoolInfo(_pool, name_, symbol_, asset_, borrow_rate_, step4_, share_price_, tvl_, insurrance_value_, total_assets_, liquidity_limit_, total_borrowed_, utilization_, interest_rate_model_, optimal_liquidity_utilization_, base_rate_, slop1_, slop2_, drip_manager_),);
    }
}


@view
func allowedContractsFromPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    allowed_contracts_len: felt, allowed_contracts: felt*
) {
    alloc_locals;
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    let (allowed_contracts: felt*) = alloc();
    if(drip_manager_ == 0){
        return(0, allowed_contracts);
    } else {
        let (drip_configurator_) = IDripManager.dripConfigurator(drip_manager_);
        let (allowed_contract_length_) = IDripConfigurator.allowedContractsLength(drip_manager_);
        recursive_contracts(drip_configurator_, allowed_contract_length_, 0, allowed_contracts);
        return(allowed_contract_length_, allowed_contracts);
    }
}

func recursive_contracts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_configurator: felt, _allowed_contract_length: felt, _index: felt,  allowed_contracts: felt*) {
    alloc_locals;
    if(_index == _allowed_contract_length){
        return();
    }
    let (contract_) = IDripConfigurator.idToAllowedContract(_drip_configurator, _index);
    assert allowed_contracts[_index] = contract_;
    return recursive_contracts(_drip_configurator, _allowed_contract_length, _index + 1, allowed_contracts);
}

@view
func allowedAssetsFromPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    allowed_assets_len: felt, allowed_assets: AllowedToken*
) {
    alloc_locals;
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    let (allowed_assets: AllowedToken*) = alloc();
    if(drip_manager_ == 0){
        return(0, allowed_assets);
    } else {
        let (allowed_tokens_length_) = IDripManager.allowedTokensLength(drip_manager_);
        recursive_tokens(drip_manager_, allowed_tokens_length_, 0, allowed_assets);
        return(allowed_tokens_length_, allowed_assets);
    }
}

func recursive_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_manager: felt, _allowed_tokens_length: felt, _index: felt,  allowed_assets: AllowedToken*) {
    alloc_locals;
    if(_index == _allowed_tokens_length){
        return();
    }
    let (asset_) = IDripManager.tokenById(_drip_manager, _index);
    let (lt_) = IDripManager.liquidationThreshold(_drip_manager, asset_);
    assert allowed_assets[_index] = AllowedToken(asset_, lt_);
    return recursive_tokens(_drip_manager, _allowed_tokens_length, _index + 1, allowed_assets);
}

@view
func feesFromPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    fees_info: FeesInfo
) {
    alloc_locals;
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    if(drip_manager_ == 0){
        return(FeesInfo(Uint256(0,0), Uint256(0,0), Uint256(0,0), Uint256(0,0), Uint256(0,0)),);
    } else {
        let (fee_interest_) = IDripManager.feeInterest(drip_manager_);
        let (fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);
        let (fee_liqudidation_expired_) = IDripManager.feeLiquidationExpired(drip_manager_);
        let (liquidation_discount_) = IDripManager.liquidationDiscount(drip_manager_);
        let (liquidation_discount_expired_) = IDripManager.liquidationDiscountExpired(drip_manager_);
        return(FeesInfo(fee_interest_, fee_liqudidation_, fee_liqudidation_expired_, liquidation_discount_, liquidation_discount_expired_),);
    }
}

@view
func accessFromPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    is_permisonless: felt, token_uri: felt
) {
    alloc_locals;
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    if(drip_manager_ == 0){
        return(0, 0,);
    } else {
        let (drip_transit_) = IDripManager.dripTransit(drip_manager_);
        let (nft_) = IDripTransit.getNft(drip_transit_);
        if(nft_ == 0){
            return(1, 0,);
        } else {
            let (token_uri_) = IMorphinePass.baseURI(nft_);
            return(0, token_uri_,);
        }
    }
}

@view
func expirationFromPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) -> (
    is_expirable: felt, remaining_time: felt
) {
    alloc_locals;
    let (drip_manager_) = IPool.connectedDripManager(_pool);
    if(drip_manager_ == 0){
        return(0, 0,);
    } else {
        let (drip_transit_) = IDripManager.dripTransit(drip_manager_);
        let (is_expirable_) = IDripTransit.isExpirable(drip_transit_);
        if(is_expirable_ == 0){
            return(0, 0,);
        } else {
            let (expiration_date_) = IDripTransit.expirationDate(drip_transit_);
            let (block_timestamp_) = get_block_timestamp();
            let is_le_ = is_le(block_timestamp_, expiration_date_);
            if(is_le_ == 1){
                return(1, expiration_date_ - block_timestamp_,);
            } else {
                return(1, 0);
            }
        }
    }
}