%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.math_cmp import is_le, is_nn, is_not_zero

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_lt,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from morphine.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from morphine.utils.various import ALL_ONES, APPROVE_SELECTOR, PRECISION

from morphine.interfaces.IDrip import IDrip

from morphine.interfaces.IRegistery import IRegistery

@storage_var
func slope_1() -> (res: Uint256) {
}

@storage_var
func slope_2() -> (res: Uint256) {
}

@storage_var
func availableLiquidity() -> (res: Uint256) {
}

@storage_var
func expected_liquidity_last_update() -> (res: Uint256) {
}

@storage_var
func base_rate() -> (res: Uint256) {
}

@storage_var
func optimal_liquidity_use() -> (res: Uint256) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _available_liquidity: Uint256,
    _expected_liquidity: Uint256,
    _slope_1: Uint256,
    _slope_2: Uint256,
    _base_rate: Uint256,
    _optimal_liquidity_utilization: Uint256,
) {
    availableLiquidity.write(_available_liquidity);
    expected_liquidity_last_update.write(_expected_liquidity);
    slope_1.write(_slope_1);
    slope_2.write(_slope_2);
    base_rate.write(_base_rate);
    optimal_liquidity_use.write(_optimal_liquidity_utilization);
    return ();
}

func calculBorrowRate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    borrowRate: Uint256
) {
    alloc_locals;
    let (available_liquidity_) = availableLiquidity.read();
    let (expected_liquidity_) = expected_liquidity_last_update.read();
    let (is_expected_liquidity_nul_) = uint256_eq(expected_liquidity_, Uint256(0, 0));
    // prevent from sending token to the pool
    let (is_expected_liquidity_lt_expected_liquidity_) = uint256_le(
        expected_liquidity_, available_liquidity_
    );
    let (base_rate_) = base_rate.read();
    if (is_expected_liquidity_nul_ + is_expected_liquidity_lt_expected_liquidity_ != 0) {
        return (base_rate_,);
    }

    // expected_liquidity_last_update - available_liquidity
    // liquidity_utilization_ = -------------------------------------
    //                               expected_liquidity_last_update

    let (step1_) = uint256_sub(expected_liquidity_, available_liquidity_);
    let (step2_, _) = uint256_mul(step1_, Uint256(PRECISION, 0));
    let (liquidity_utilization_, _) = uint256_unsigned_div_rem(step2_, expected_liquidity_);
    let (optimal_liquidity_utilization_) = optimal_liquidity_use.read();
    let (is_utilization_lt_optimal_utilization_) = uint256_le(
        liquidity_utilization_, optimal_liquidity_utilization_
    );

    // if liquidity_utilization_ < optimal_liquidity_utilization_:
    //                                    liquidity_utilization_
    // borrow_rate = base_rate +  slop1 * -----------------------------
    //                                     optimal_liquidity_utilization_

    let (slop1_) = slope_1.read();
    if (is_utilization_lt_optimal_utilization_ == 1) {
        let (step1_, _) = uint256_mul(liquidity_utilization_, Uint256(PRECISION, 0));
        let (step2_, _) = uint256_unsigned_div_rem(step1_, optimal_liquidity_utilization_);
        let (step3_, _) = uint256_mul(step2_, slop1_);
        let (borrow_rate_, _) = uint256_add(step3_, base_rate_);
        return (borrow_rate_,);
    } else {
        // if liquidity_utilization_ >= optimal_liquidity_utilization_:
        //
        //                                           liquidity_utilization_ - optimal_liquidity_utilization_
        // borrow_rate = base_rate + slop1 + slop2 * ------------------------------------------------------
        //                                              1 - optimal_liquidity_utilization

        let (slop2_) = slope_2.read();
        let (step2_, _) = uint256_mul(Uint256(PRECISION, 0), step1_);
        let (step3_) = uint256_sub(Uint256(PRECISION, 0), optimal_liquidity_utilization_);
        let (step4_, _) = uint256_unsigned_div_rem(step2_, step3_);
        let (step5_, _) = uint256_mul(step4_, slop2_);
        let (step6_, _) = uint256_add(step5_, slop1_);
        let (borrow_rate_, _) = uint256_add(step6_, base_rate_);
        return (borrow_rate_,);
    }
}
