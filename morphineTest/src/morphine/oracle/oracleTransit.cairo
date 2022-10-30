%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
    get_contract_address,
)

from starkware.cairo.common.math_cmp import is_le, is_nn, is_not_zero

from starkware.cairo.common.uint256 import ALL_ONES, Uint256, uint256_eq, uint256_lt, uint256_check
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.access.ownable.library import Ownable

from morphine.interfaces.IEmpiricOracle import IEmpiricOracle

from morphine.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from morphine.interfaces.IRegistery import IRegistery
from morphine.utils.utils import pow



// Events

@event
func NewPrimitive(token: felt, pair_id: felt) {
}

@event
func NewDerivative(token: felt, price_feed: felt) {
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

// Constructor
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
    let (underlying_assets_len: felt, _, _, _) = IDerivativePriceFeed.calcUnderlyingValues(_derivative_price_feed,_token,Uint256(0,0));
    with_attr error_message("quote price error") {
        assert_not_zero(underlying_assets_len);
    }
    derivative_to_price_feed.write(_token, _derivative_price_feed);
    NewDerivative.emit(_token, _derivative_price_feed);
    return ();
}

// View

@view
func primitivePairId{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _primitive: felt
) -> (pair_id: felt) {
    let (pair_id_: felt) = pair_id.read(_primitive);
    return (pair_id_,);
}

@view
func derivativePriceFeed{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _derivative: felt
) -> (price_feed: felt) {
    let (price_feed_: felt) = derivative_to_price_feed.read(_derivative);
    return (price_feed_,);
}

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

@view
func convert{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _amount: Uint256, _token_from: felt, _token_to: felt
) -> (price: Uint256) {
    let (usd_) = convertToUSD(_amount, _token_from);
    let (price_) = convertFromUSD(usd_, _token_to);
    return (price_,);
}

@view
func fastCheck{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _amount_from: Uint256, _token_from: felt, _amount_to: Uint256, _token_to: felt
) -> (collateralFrom: Uint256, collateralTo: Uint256) {
    alloc_locals;
    let (collateral_from_) = convertToUSD(_amount_from, _token_from);
    let (collateral_to_) = convertToUSD(_amount_to, _token_to);
    return (collateral_from_, collateral_to_,);
}

// Internals

func get_price{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_token: felt) -> (
    token_price_usd: Uint256
) {
    alloc_locals;
    let (derivative_to_price_feed_) = derivative_to_price_feed.read(_token);
    let (oracle_) = oracle.read();
    if (derivative_to_price_feed_ == 0) {
        let (pair_id_) = pair_id.read(_token);
        with_attr error_message("token not supported") {
            assert_not_zero(pair_id_);
        }
        let (price_, _, _, _) = IEmpiricOracle.get_spot_median(oracle_,pair_id_);
        with_attr error_message("zero price") {
            assert_not_zero(price_);
        }
        return (Uint256(price_, 0),);
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
