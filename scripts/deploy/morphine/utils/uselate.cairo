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

from starkware.cairo.common.cairo_builtins import HashBuiltin

// @notice: Struct representing a Drip Position
struct Position {
    asset: felt,
    total_debt : felt,
}


// @notice: Calculate a Pool debt
// @param: _pool_id pool id
// @return: Position
@view
func poolDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool_id: felt) -> (
    debt: Position
) {
    let (registery_) = registery.read();
    let (pool_factory_) = IRegistery.getPoolFactory(registery_);
    let (pool_) = IPoolFactory.getPoolFromId(pool_factory_, _pool_id);
    let (borrow_info_) = borrow_info.read(pool_);
    let (cumulative_index_) = IPool.cumulativeIndex();
    let (diff_cumulative_index_) = uint256_sub(cumulative_index_, borrow_info_.cumulative_index);
    let (interest_) = uint256_permillion(borrow_info_.amount, diff_cumulative_index_);
    let (total_debt_) = uint256_add(borrow_info_.amount, interest_);
    let (asset_) = IPool.asset(pool_);
    return (Position(asset_, total_debt_),);
}

// @notice: Calculate all Pool Debt
// @return: debt_len return all debt hold by different pools
// @return: deb Position
// TODO
@view
func allPoolDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    debt_len: felt, debt: Position
) {
    let (registery_) = registery.read();
    let (pool_factory_) = IRegistery.getPoolFactory(registery_);
    let (pool_amount_) = IPoolFactory.poolAmount(pool_factory_);
    let (local debt: Position*) = alloc();
    let (debt_len) = complete_debt_tab(pool_amount_, 0, debt);
    return (debt_len, debt,);
}

// @notice: Calculate collateral
// @param: _asset_id asset id
// @return: collateralAmount
// MAYBE SHOULD be a UINT256
@view
func collateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _asset_id: felt
) -> (collateralAmount: felt) {
    let (registery_) = registery.read();
    let (integraton_manager_) = IRegistery.integrationManager(registery_);
    let (asset_) = IIntegrationManager.collateral(_asset_id);
    let (collateral_amount_) = collateral_amount.read(asset_);
    return (collateral_amount_);
}

// @notice: Calculate all collateral
@view
func allCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    collateral_len: felt, collateral: Position
) {
    let (registery_) = registery.read();
    let (integration_manager_) = IRegistery.integrationManager(registery_);
    let (id_amount_) = IIntegrationManager.assetAmount(integration_manager_);
    let (local collateral: Position*) = alloc();
    let (collateral_len) = complete_collateral_tab(pool_amount_, 0, debt);
    return (collateral_len, collateral,);
}

@view
func dripValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    dripValue: felt
) {
    let (collateral_len: felt, collateral: Position) = allCollateral();
    let (debt_len: felt, debt: Position) = allPoolDebt();
    return (collateral_len, collateral,);
}

@external
func activate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller_) = get_caller_address();
    let (registery_) = registery.read();
    let (drip_factory_) = IRegistery.getDripFactory(registery_);
    with_attr error_message("Drip: only callable by drip factory") {
        assert caller_ = drip_factory_;
    }
    let (is_live_) = is_live.read();
    with_attr error_message("Drip: drip already live") {
        assert is_live_ = FALSE;
    }
    is_live.write(TRUE);
}

@external
func borrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _pool_id: felt, _amount: Uint256
) {
    Ownable.assert_only_owner();
    assert_drip_live();
    let (position_) = poolDebt(_pool_id);
    let (debt_) = position.amount;
    let (is_debt_nul_) = uint256_eq(debt_, Uint256(0, 0));
    with_attr error_message("Drip: you have to repay your debt first") {
        assert is_debt_nul_ = TRUE;
    }
    IPool.borrow(pool_, _amount);
    let (cumulative_index_) = IPool.cumulativeIndex();
    pool_to_borrow_info.write(pool_, BorrowInfo(_amount, cumulative_index_));
    return ();
}

@external
func repayDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _pool_id: felt, _amount: Uint256
) {
    Ownable.assert_only_owner();
    assert_drip_live();
    let (position_) = poolDebt(_pool_id);
    let (debt_) = position.amount;
    let (is_debt_nul_) = uint256_eq(debt_, Uint256(0, 0));
    with_attr error_message("Drip: no Debt") {
        assert is_debt_nul_ = FALSE;
    }

    let (is_allowed_amount1_) = uint256_le(_amount, debt_);
    let (is_allowed_amount2_) = uint256_le(Uint256(0, 0), _amount);
    with_attr error_message("Drip: repay amount out of range") {
        assert is_allowed_amount1_ * is_allowed_amount1_ = TRUE;
    }

    IPool.repayDebt(pool_, _amount);

    let (new_borrowed_amount_) = uint256_sub(debt_, _amount);
    let (is_fully_paid_) = uint256_eq(new_borrowed_amount_, Uint256(0, 0));
    if (is_fully_paid_ == TRUE) {
        pool_to_borrow_info.write(pool_, BorrowInfo(Uint256(0, 0), Uint256(0, 0)));
    } else {
        let (registery_) = registery.read();
        let (pool_factory_) = IRegistery.getPoolFactory(registery_);
        let (pool_) = IPoolFactory.getPoolFromId(pool_factory_, _pool_id);
        let (borrow_info_) = borrow_info.read(pool_);
        let (cumulative_index_) = borrow_info_.cumulative_index;
        pool_to_borrow_info.write(pool_, BorrowInfo(new_borrowed_amount_, cumulative_index_));
    }
    return ();
}

@external
func addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _asset_id: felt, _amount: Uint256
) {
    Ownable.assert_only_owner();
    assert_drip_live();
    let (caller_) = get_caller_address();
    let (this_) = get_contract_address();
    let (registery_) = registery.read();
    let (integraton_manager_) = IRegistery.integrationManager(registery_);
    let (asset_) = IIntegrationManager.assetFromId(_asset_id);
    let (test_) = is_not_zero(asset_);
    with_attr error_message("Drip: unknow asset id") {
        assert test_ = 1;
    }
    let (previous_collateral_amount_) = collateral_amount.read(asset_);
    SafeERC20.transferFrom(asset_, caller_, this_, _amount);
    let (new_collateral_amount_, _) = uint256_add(previous_collateral_amount_, _amount);
    collateral_amount.write(asset_, new_collateral_amount_);
    return ();
}

@view
func assetValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _asset_id: felt, _amount: Uint256
) -> (assetValue: Uint256) {
    let (registery_) = registery.read();
    let (integraton_manager_) = IRegistery.integrationManager(registery_);
    let (asset_) = IIntegrationManager.assetFromId(_asset_id);
    let (test_) = is_not_zero(asset_);
    with_attr error_message("Drip: unknow asset id") {
        assert test_ = 1;
    }
    let (value_interpreter_) = IRegistery.valueInterpreter(registery_);
    let (asset_value_) = IValueInterpreter.assetToUsd(value_interpreter_, asset_, _amount);
    return (asset_value_,);
}

@view
func collateralValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _asset_id: felt, _amount: Uint256
) -> (assetValue: Uint256) {
    let (registery_) = registery.read();
    let (integraton_manager_) = IRegistery.integrationManager(registery_);
    let (asset_) = IIntegrationManager.assetFromId(_asset_id);
    let (test_) = is_not_zero(asset_);
    with_attr error_message("Drip: unknow asset id") {
        assert test_ = 1;
    }
    let (value_interpreter_) = IRegistery.valueInterpreter(registery_);
    let (asset_value_) = IValueInterpreter.assetToUsd(value_interpreter_, asset_, _amount);
    return (asset_value_,);
}

// Internals

func assert_drip_live{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_live_) = is_live.read();
    with_attr error_message("Drip: not live") {
        assert is_live_ = TRUE;
    }
    return ();
}

func complete_debt_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _pool_amount: felt, _debt_len: felt, _debt: Position*
) -> (debtLen: felt) {
    if (_pool_amount == 0) {
        return (_debt_len);
    }
    let (position: Position) = poolDebt(_pool_amount - 1);
    let (is_debt_nul_) = uint256_eq(position.amount, Uint256(0, 0));
    if (is_debt_nul_ == 1) {
        complete_debt_tab(_pool_amount - 1, _debt_len, _debt);
        return ();
    } else {
        assert _debt[debt_len] = position;
        complete_debt_tab(_pool_amount - 1, _debt_len + 1, _debt);
    }
}

func complete_collateral_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _asset_amount: felt, _collateral_len: felt, _collateral: Position*
) -> (collateralLen: felt) {
    if (_asset_amount == 0) {
        return (_collateral_len);
    }
    let (position_: Position) = collateral(_asset_amount - 1);
    let (is_collateral_nul_) = uint256_eq(position_.amount, Uint256(0, 0));
    if (is_collateral_nul_ == 1) {
        complete_debt_tab(_asset_amount - 1, _collateral_len, _collateral);
        return ();
    } else {
        assert _collateral[_collateral_len] = position_;
        complete_debt_tab(_asset_amount - 1, _collateral_len + 1, _collateral);
    }
}
