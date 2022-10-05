// Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from src.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin
from src.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from src.IRegistery import IRegistery
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero

@storage_var
func registery() -> (registery: felt) {
}

@storage_var
func derivative_to_price_feed(derivative: felt) -> (res: felt) {
}

@storage_var
func is_supported_derivative_asset(derivative: felt) -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _registery: felt
) {
    registery.write(_registery);
    return ();
}

func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (registery_contract) = registery.read();
    let (owner : felt) = IRegistery.owner(registery_contract);
    let (caller) = get_caller_address();
    with_attr error_message("Ownable: caller is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("Ownable: caller is not the owner") {
        assert owner = caller;
    }
    return ();
}

// getters

@view
func derivativePriceFeed{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    derivative: felt
) -> (price_feed: felt) {
    let (price_feed_: felt) = derivative_to_price_feed.read(derivative);
    return (price_feed_,);
}

@view
func isSupportedDerivativeAsset{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    derivative: felt
) -> (is_supported_derivative_asset: felt) {
    let (is_supported_derivative_asset_: felt) = is_supported_derivative_asset.read(derivative);
    return (is_supported_derivative_asset_,);
}

@view
func assetToUsd{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _asset: felt, 
    _amount: Uint256) -> (asset_value: Uint256) {
    alloc_locals;
    if (amount.low == 0) {
        return (Uint256(0, 0),);
    }
    let (registery_ : felt) = registery.read();
    let (oracle_price_feed_: felt) = IRegistery.oracle(registery_);
    let (is_supported_primitive_asset_: felt) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(oracle_price_feed_, _asset);
    
    if (is_supported_primitive_asset_ == 1) {
        // Get price from oracle
        let (asset_value_: Uint256) = IOraclePriceFeedMixin.calcAssetValue(oracle_price_feed_, _asset, _amount);
        return (asset_value_,);
    } else {
        // Derivative (LP or ERC4626)
        let (is_supported_derivative_asset_) = is_supported_derivative_asset.read(_asset);
        if (isSupportedDerivativeAsset_ == 1) {
            let (derivative_price_feed_: felt) = derivativePriceFeed(_asset);
            // TODO : WTF
            let (asset_value_: Uint256) = calcul_derivative_value(
                derivative_price_feed_, _asset, _amount);
            return (asset_value_,);
        } else {
            // not supported asset
            return(Uint256(0,0),);
        }
    }
}

//
// External
//

@external
func addDerivative{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _derivative: felt, _price_feed: felt
) {
    assert_only_owner();
    is_supported_derivative_asset.write(_derivative, 1);
    derivative_to_price_feed.write(_derivative, _price_feed);
    return ();
}


//
// Internal
//

func calc_derivative_value{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _derivative_price_feed: felt, 
    _derivative: felt, 
    _amount: Uint256) -> (derivative_value: Uint256) {
    let (
        underlyingsAssets_len: felt,
        underlyingsAssets: felt*,
        underlyingsAmount_len: felt,
        underlyingsAmount: Uint256*,
    ) = IDerivativePriceFeed.calc_underlying_values(derivative_price_feed, derivative, amount);

    with_attr error_message("calc_derivative_value: No underlyings") {
        assert_not_zero(underlyingsAssets_len);
    }
    with_attr error_message("calc_derivative_value: Arrays unequal lengths") {
        assert underlyingsAssets_len = underlyingsAmount_len;
    }

    let (derivative_value_: Uint256) = calcul_underlying_values(
        underlyingsAssets_len,
        underlyingsAssets,
        underlyingsAmount_len,
        underlyingsAmount,
    );
    return (derivative_value_);
}

func calcul_underlying_values{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    underlying_assets_len: felt,
    underlying_assets: felt*,
    underlying_amounts_len: felt,
    underlying_amounts: Uint256*) -> (total_value: Uint256) {
    alloc_locals;
    if (underlying_assets_len == 0) {
        return (Uint256(0, 0),);
    }

    let asset_: felt = [underlying_assets];
    let amount_: Uint256 = [underlying_amounts];

    let (underlyingValue_: Uint256) = assetToUsd(asset_, amount_);
    let (nextValue_: Uint256) = calcul_underlying_values(
        underlying_assets_len - 1,
        underlying_assets + 1,
        underlying_amounts_len - 1,
        underlying_amounts + Uint256.SIZE,
    );
    let (total_value_: Uint256, _) = uint256_add(underlyingValue_, nextValue_);
    return (total_value_);
}