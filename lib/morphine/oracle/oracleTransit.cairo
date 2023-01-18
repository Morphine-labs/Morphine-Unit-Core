%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
    get_contract_address,
)

from starkware.cairo.common.math_cmp import is_le, is_nn, is_not_zero

from starkware.cairo.common.uint256 import ALL_ONES, Uint256, uint256_eq, uint256_lt, uint256_check, uint256_sqrt
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import (
    abs_value,
    assert_250_bit,
    assert_in_range,
    assert_le,
    assert_le_felt,
    assert_lt,
    assert_lt_felt,
    assert_nn,
    assert_nn_le,
    assert_not_equal,
    assert_not_zero,
    horner_eval,
    is_quad_residue,
    sign,
    signed_div_rem,
    split_felt,
    split_int,
    sqrt,
    unsigned_div_rem,
)
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.access.ownable.library import Ownable

from morphine.interfaces.IEmpiricOracle import IEmpiricOracle

from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IJediSwapPair import IJediSwapPair
from morphine.utils.utils import pow
from morphine.utils.various import PRECISION


/// @title Oracle Transit
/// @author Graff Sacha (0xSacha)
/// @dev Modular and Intelligent Oracle contract
/// @custom:experimental This is an experimental contract. LP Pricing to think.

// Events

@event
func NewPrimitive(token: felt, pair_id: felt) {
}

@event
func NewDerivative(token: felt, price_feed: felt) {
}

@event
func NewLiquidityToken(token: felt) {
}

// Storage

@storage_var
func oracle() -> (oracle: felt) {
}

@storage_var
func pair_id(primitive: felt) -> (pair_id: felt) {
}

@storage_var
func derivative_to_price_feed(derivative: felt) -> (res: felt) {
}

@storage_var
func is_lp(token: felt) -> (state: felt) {
}

// Constructor

// @notice: Oracle Transit Constructor
// @param: _oracle Primitive Oracle (felt)
// @param: _registery Registery (felt)
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_oracle: felt, _registery: felt) {
    with_attr error_message("zero address") {
        assert_not_zero(_oracle);
    }
    oracle.write(_oracle);
    let (owner_) = IRegistery.owner(_registery);
    Ownable.initializer(owner_);
    return ();
}

// TOKEN MANAGEMENT

// @notice: Add Primitive
// @param: _token Token of wanted pricefeed (felt)
// @param: _pair_id Id for query price (felt)
@external
func addPrimitive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt, _pair_id: felt
) {
    Ownable.assert_only_owner();
    with_attr error_message("zero address or pair id") {
        assert_not_zero(_token * _pair_id);
    }
    let (decimals_) = IERC20.decimals(_token);
    let is_le_ = is_le(decimals_, 18);
    with_attr error_message("token decimals greater than 18") {
        assert_not_zero(is_le_);
    }
    let (oracle_) = oracle.read();

    let (_, price_feed_decimals_, _, _) = IEmpiricOracle.get_spot_median(oracle_,_pair_id);
    with_attr error_message("price feed decimals not equal to 8") {
        assert price_feed_decimals_ = 8;
    }
    pair_id.write(_token, _pair_id);
    NewPrimitive.emit(_token, _pair_id);
    return ();
}


// @notice: Add Derivative
// @param: _token Token of wanted pricefeed (felt)
// @param: _derivative_price_feed Contract to query underlying values (felt)
@external
func addDerivative{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt, _derivative_price_feed: felt
) {
    Ownable.assert_only_owner();
    with_attr error_message("zero address") {
        assert_not_zero(_token * _derivative_price_feed);
    }
    let (decimals_) = IERC20.decimals(_token);
    let is_le_ = is_le(decimals_, 18);
    with_attr error_message("token decimals greater than 18") {
        assert_not_zero(is_le_);
    }

    with_attr error_message("quote price error") {
        let (underlying_assets_len: felt, _, _, _) = IDerivativePriceFeed.calcUnderlyingValues(_derivative_price_feed,_token,Uint256(0,0));
    }

    with_attr error_message("quote price error") {
        assert_not_zero(underlying_assets_len);
    }
    derivative_to_price_feed.write(_token, _derivative_price_feed);
    NewDerivative.emit(_token, _derivative_price_feed);
    return ();
}


// @notice: Add Liquidity yoken
// @param: _token wanted liquidity token (felt)
@external
func addLiquidityToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt
) {
    Ownable.assert_only_owner();
    with_attr error_message("zero address") {
        assert_not_zero(_token);
    }
    
    let (decimals_) = IERC20.decimals(_token);
    let is_le_ = is_le(decimals_, 18);
    with_attr error_message("token decimals greater than 18") {
        assert_not_zero(is_le_);
    }

    with_attr error_message("quote token 0 error") {
        let (token_0_) = IJediSwapPair.token0(_token);
    }

    with_attr error_message("quote token 1 error") {
        let (token_1_) = IJediSwapPair.token1(_token);
    }

    with_attr error_message("quote reserve error") {
        let (reserve_0_, reserve_1_, _) = IJediSwapPair.get_reserves(_token);
    }
    
    let (pair_id_) = pair_id.read(token_0_);
    with_attr error_message("token 0 not supported") {
        assert_not_zero(pair_id_);
    }

    let (pair_id_) = pair_id.read(token_1_);
    with_attr error_message("token 1 not supported") {
        assert_not_zero(pair_id_);
    }

    with_attr error_message("LP reserve null") {
        assert_not_zero(reserve_0_.low * reserve_1_.low);
    }

    is_lp.write(_token, 1);
    NewLiquidityToken.emit(_token);
    return ();
}

// View

// @notice: Primitive Pair ID
// @param: _primitive Token to look for pair id (felt)
// @return: pair_id Pair ID (felt)
@view
func primitivePairId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _primitive: felt
) -> (pair_id: felt) {
    let (pair_id_: felt) = pair_id.read(_primitive);
    return (pair_id_,);
}

// @notice: Derivative Price Feed
// @param: _derivative Token to look for derivative pricefeed (felt)
// @return: price_feed_ Derivative Price Feed (felt)
@view
func derivativePriceFeed{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _derivative: felt
) -> (price_feed: felt) {
    let (price_feed_: felt) = derivative_to_price_feed.read(_derivative);
    return (price_feed_,);
}

// @notice: Check if the token is registred LP token
// @param: _token Token to check (felt)
// @return: is_lp 1 is registred lp, 0 not registred (felt)
@view
func isLiquidityToken{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _token: felt
) -> (is_lp: felt) {
    let (is_lp_: felt) = is_lp.read(_token);
    return (is_lp_,);
}

// @notice: convert To USD
// @dev decimals token are managed and the output is 8 decimals
// @param: _amount amount of token (Uint256)
// @param: _token token to convert (felt)
// @return: tokenPriceUsd  Token Price in USD (Uint256)
@view
func convertToUSD{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _amount: Uint256, _token: felt
) -> (tokenPriceUsd: Uint256) {
    alloc_locals;
    let (decimals_) = IERC20.decimals(_token);
    let (multiplier_) = pow(10, decimals_);
    let (token_price_) = get_price(_token);
    let (step1_) = SafeUint256.mul(_amount, token_price_);
    let (token_price_usd_,_) = SafeUint256.div_rem(step1_, Uint256(multiplier_, 0));
    return (token_price_usd_,);
}

// @notice: convert From USD
// @dev decimals token are managed and the input is 8 decimals
// @param: _amount amount of tokens in USD (Uint256)
// @param: _token  convert to Token (felt)
// @return: tokenPrice  Token Price (Uint256)
@view
func convertFromUSD{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _amount: Uint256, _token: felt
) -> (tokenPrice: Uint256) {
    alloc_locals;
    let (decimals_) = IERC20.decimals(_token);
    let (multiplier_) = pow(10, decimals_);
    let (token_price_) = get_price(_token);
    let (step1_) = SafeUint256.mul(_amount, Uint256(multiplier_, 0));
    let (token_price_, _) = SafeUint256.div_rem(step1_, token_price_);
    return (token_price_,);
}

// @notice: convert
// @dev Converts directly an asset into an other one
// @param: _amount amount of tokens from (Uint256)
// @param: _token_from  Token from (felt)
// @param: _token_to  Token To (felt)
// @return: price  Token Price (Uint256)
@view
func convert{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _amount: Uint256, _token_from: felt, _token_to: felt
) -> (price: Uint256) {
    let (usd_) = convertToUSD(_amount, _token_from);
    let (price_) = convertFromUSD(usd_, _token_to);
    return (price_,);
}

// Internals

// @notice: get_price
// @param: _token  Token to get price (felt)
// @return: token_price_usd   Token Price in USD (Uint256)
func get_price{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_token: felt) -> (
    token_price_usd: Uint256
) {
    alloc_locals;
    let (derivative_to_price_feed_) = derivative_to_price_feed.read(_token);
    let (oracle_) = oracle.read();
    if (derivative_to_price_feed_ == 0) {
        let (pair_id_) = pair_id.read(_token);
        if(pair_id_ == 0){
            let (is_lp_) = is_lp.read(_token);
            if(is_lp_ == 0){
                with_attr error_message("token not supported") {
                    assert 1 = 0;
                } 
                return (Uint256(0,0),);
            } else {
                let (token0_) = IJediSwapPair.token0(_token);
                let (decimals_token0_) = IERC20.decimals(token0_);
                let (one_unit_token0_) = pow(10, decimals_token0_);

                let (token1_) = IJediSwapPair.token1(_token);
                let (decimals_token1_) = IERC20.decimals(token1_);
                let (one_unit_token1_) = pow(10, decimals_token1_);


                let (total_supply_) = IERC20.totalSupply(_token);

                let (reserve0_decimals_, reserve1_decimals_, _) = IJediSwapPair.get_reserves(_token);
                let (reserve0_precision_) = SafeUint256.mul(reserve0_decimals_, Uint256(PRECISION, 0));
                let (reserve0_, _) = SafeUint256.div_rem(reserve0_precision_, Uint256(one_unit_token0_, 0));
                let (reserve1_precision_) = SafeUint256.mul(reserve1_decimals_, Uint256(PRECISION, 0));
                let (reserve1_, _) = SafeUint256.div_rem(reserve1_precision_, Uint256(one_unit_token1_, 0));
                let (total_reserve_) = SafeUint256.mul(reserve0_,reserve1_);
                let (reserve_sqrt_) =  uint256_sqrt(total_reserve_);

                let (price_primitive_0_) = convertToUSD(Uint256(one_unit_token0_, 0), token0_);
                let (price_primitive_1_) = convertToUSD(Uint256(one_unit_token1_, 0), token1_);
                let (total_price_) = SafeUint256.mul(price_primitive_0_, price_primitive_1_);
                let (product_sqrt_) = uint256_sqrt(total_price_);

                let (step1_) = SafeUint256.mul(reserve_sqrt_, product_sqrt_);
                let (num_) = SafeUint256.mul(step1_, Uint256(2,0));
                let (lp_price_usd_, _) = SafeUint256.div_rem(num_, total_supply_);
                return (lp_price_usd_,);
            }
        } else {
            let (price_, _, _, _) = IEmpiricOracle.get_spot_median(oracle_,pair_id_);
            with_attr error_message("zero price") {
                assert_not_zero(price_);
            }
            return (Uint256(price_, 0),);
        }
    } else {
        let (decimals_) = IERC20.decimals(_token);
        let (multiplier_) = pow(10, decimals_);
        let (
            underlying_assets_len: felt,
            underlying_assets: felt*,
            underlyings_amounts_len: felt,
            underlyings_amounts: Uint256*,
        ) = IDerivativePriceFeed.calcUnderlyingValues(derivative_to_price_feed_, _token, Uint256(multiplier_,0));
        with_attr error_message("quote price error") {
            assert_not_zero(underlying_assets_len);
        }
        let (new_price_) = recursive_calcul_derivative(
            underlying_assets_len, underlying_assets, underlyings_amounts_len, underlyings_amounts
        );
        return (new_price_,);
    }
}

// @notice: recursive_calcul_derivative
// @param: underlying_assets_len  Underlying Assets Length (felt)
// @param: underlying_assets  Underlying Assets (felt*)
// @param: underlying_amounts_len  Underlying Amounts Length (felt)
// @param: underlying_amounts  Underlying Amounts (Uint256*)
// @return: res Token Price in USD (Uint256)
func recursive_calcul_derivative{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    underlying_assets_len: felt,
    underlying_assets: felt*,
    underlying_amounts_len: felt,
    underlying_amounts: Uint256*,
) -> (res: Uint256) {
    alloc_locals;
    if (underlying_assets_len == 0) {
        return (Uint256(0, 0),);
    }
    let token_: felt = [underlying_assets];
    let amount_: Uint256 = [underlying_amounts];

    let (underlying_value_: Uint256) = convertToUSD(amount_,token_);
    let (next_value_: Uint256) = recursive_calcul_derivative(
        underlying_assets_len - 1,
        underlying_assets + 1,
        underlying_amounts_len - 1,
        underlying_amounts + Uint256.SIZE,
    );
    let (res_: Uint256) = SafeUint256.add(underlying_value_, next_value_);
    return (res=res_);
}