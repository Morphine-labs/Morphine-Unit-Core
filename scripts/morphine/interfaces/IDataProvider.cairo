%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct FaucetInfo {
    token_address: felt,  
    user_balance: Uint256,  
    remaining_time: felt,
}

struct MinterInfo {
    token_address: felt,  
    token_uri: felt,
    minter_address: felt,  
    is_whitelisted: felt,
    has_minted: felt,
}

struct TokenInfo {
    token_address: felt,  
    user_balance: Uint256,  
    value: Uint256,
}

struct UserTokenCollateral {
    token_address: felt,  
    lt: Uint256,
    user_balance: Uint256,  
    value: Uint256,
}


struct PoolTokenInfo {
    token_address: felt,  
    user_balance: Uint256,  
    value: Uint256,
    apr: Uint256,
}

struct NftInfo {
    token_address: felt,  
    has_token: felt,  
    uri: felt,
}

struct DripMiniInfo {
    token_address: felt,
    total_balance: Uint256,  
    token_value: Uint256,
    user_balance: Uint256,  
    health_factor: Uint256,
}

struct DripFullInfo {
    user_balance: Uint256,  
    total_balance: Uint256,  
    total_weighted_balance: Uint256,  
    debt: Uint256,
    health_factor: Uint256,
    drip_address: felt,
}

struct DripTokens {
    token_address: felt,  
    lt: Uint256,
    drip_balance: Uint256,  
    value: Uint256,
}

struct DripListInfo {
    pool_address: felt,
    token_address: felt,
    nft: felt,  
    borrow_rate: Uint256,  
    pool_liq: Uint256,
    pool_liq_usd: Uint256,
}

struct LimitInfo {
    minimum_borrowed_amount: Uint256,  
    maximum_borrowed_amount: Uint256,
}

struct FeesInfo {
    fee_interest: Uint256,  
    fee_liqudidation: Uint256,  
    fee_liqudidation_expired: Uint256,
    liquidation_discount: Uint256,
    liquidation_discount_expired: Uint256,
}

struct AllowedToken {
    address: felt,  // Address of token
    liquidation_threshold: Uint256,  // LT for token in range 0..1,000,000 which represents 0-100%
}

struct PoolInfo {
    pool_address: felt,
    name: felt,
    symbol: felt,
    asset: felt,
    borrow_rate: Uint256,  
    supply_rate: Uint256,
    share_price: Uint256,
    tvl: Uint256,
    insurrance_value: Uint256,

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
}

@contract_interface
namespace IDataProvider {

    func dripManager() -> (drip_manager: felt) {
    }

    func dripTransit() -> (drip_transit: felt) {
    }

    func targetContract() -> (target: felt) {
    }
}
