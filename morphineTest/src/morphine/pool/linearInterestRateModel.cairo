%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.uint256 import (
    uint256_check,
    uint256_le
)

from morphine.utils.various import PRECISION



@storage_var
func slope1() -> (res: Uint256) {
}

@storage_var
func slope2() -> (res: Uint256) {
}

@storage_var
func availableLiquidity() -> (res: Uint256) {
}

@storage_var
func base_rate() -> (res: Uint256) {
}

@storage_var
func optimal_liquidity_utilization() -> (res: Uint256) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _optimal_liquidity_utilization: Uint256,
    _slope1: Uint256,
    _slope2: Uint256,
    _base_rate: Uint256) {
    alloc_locals;
    let (is_optimal_liquidity_utilization_in_range_) = uint256_le(
        _optimal_liquidity_utilization, Uint256(PRECISION, 0)
    );
    let (is_base_rate_in_range_) = uint256_le(
        _optimal_liquidity_utilization, Uint256(PRECISION, 0)
    );
    let (is_slop1_in_range_) = uint256_le(_slope1, Uint256(PRECISION, 0));
    let (is_slop2_in_range_) = uint256_le(_slope2, Uint256(PRECISION, 0));

    with_attr error_message("Parameter out of range") {
        assert is_optimal_liquidity_utilization_in_range_ * is_base_rate_in_range_ * is_slop1_in_range_ * is_slop2_in_range_ = 1;
    }

    optimal_liquidity_utilization.write(_optimal_liquidity_utilization);
    slope1.write(_slope1);
    slope2.write(_slope2);
    base_rate.write(_base_rate);
    return ();
}



@view
func modelParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    optimalLiquidityUtilization: Uint256,
    baseRate: Uint256,
    slop1: Uint256,
    slop2: Uint256) {
    alloc_locals;
    let (optimal_liquidity_utilization_) = optimal_liquidity_utilization.read();
    let (base_rate_) = base_rate.read();
    let (slop1_) = slope1.read();
    let (slop2_) = slope2.read();
    return(optimal_liquidity_utilization_, base_rate_, slop1_, slop2_);
}