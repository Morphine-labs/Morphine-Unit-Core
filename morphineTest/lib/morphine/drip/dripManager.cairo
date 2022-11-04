%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.math_cmp import is_le, is_nn, is_not_zero

from starkware.cairo.common.uint256 import Uint256, uint256_pow2

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_lt,
    uint256_eq,
    uint256_add,
)
from morphine.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.starknet.common.syscalls import deploy
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.safemath.library import SafeUint256

from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from morphine.interfaces.IDrip import IDrip

from morphine.interfaces.IRegistery import IRegistery

from morphine.interfaces.IPool import IPool

from morphine.interfaces.IDripFactory import IDripFactory

from morphine.interfaces.IOracleTransit import IOracleTransit

from morphine.utils.various import PRECISION

// Events

@event
func ExecuteOrder(borrower: felt, target: felt) {
}

// Storage

@storage_var
func borrower_to_drip(borrower: felt) -> (drip: felt) {
}

@storage_var
func drip_factory() -> (drip_factory: felt) {
}

@storage_var
func underlying() -> (underlying: felt) {
}

@storage_var
func pool() -> (pool: felt) {
}

@storage_var
func registery() -> (pool: felt) {
}

@storage_var
func minimum_borrowed_amount() -> (minimum_borrowed_amount: Uint256) {
}

@storage_var
func maximum_borrowed_amount() -> (maximum_borrowed_amount: Uint256) {
}

// Interest fee protocol charges: fee = interest accrues * feeInterest
@storage_var
func fee_interest() -> (fee_interest: Uint256) {
}

// Liquidation fee protocol charges: fee = totalValue * feeLiquidation
@storage_var
func fee_liqudidation() -> (fee_liqudidation: Uint256) {
}

// Multiplier to get amount which liquidator should pay: amount = totalValue * liquidationDiscount
@storage_var
func liquidation_discount() -> (liquidation_discount: Uint256) {
}

@storage_var
func drip_transit() -> (drip_junction: felt) {
}

@storage_var
func drip_configurator() -> (drip_configurator: felt) {
}

@storage_var
func id_to_allowed_token(id: felt) -> (token: felt) {
}

@storage_var
func allowed_token_to_id(token: felt) -> (id: felt) {
}

@storage_var
func allowed_tokens_length() -> (length: felt) {
}

@storage_var
func liquidation_threshold(token: felt) -> (lt: Uint256) {
}

@storage_var
func token_mask(token: felt) -> (mask: Uint256) {
}

@storage_var
func forbiden_token_mask() -> (mask: Uint256) {
}

@storage_var
func enabled_tokens(drip: felt) -> (mask: Uint256) {
}

@storage_var
func fast_check_counter(drip: felt) -> (block: Uint256) {
}

@storage_var
func adapter_to_contract(adapter: felt) -> (contract: felt) {
}

@storage_var
func oracle_transit() -> (oracle_transit: felt) {
}

@storage_var
func chi_threshold() -> (mask: Uint256) {
}

@storage_var
func hf_check_interval() -> (interval: Uint256) {
}

// Protector
func assert_only_drip_configurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (caller_) = get_caller_address();
    let (drip_configurator_) = drip_configurator.read();
    with_attr error_message("Only the configurator can call this function") {
        assert caller_ = drip_configurator_;
    }
    return();
}

func assert_only_drip_transit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller_) = get_caller_address();
    let (drip_transit_) = drip_transit.read();
    with_attr error_message("Only callable by drip transit") {
        assert caller_ = drip_transit_;
    }
    return ();
}

func assert_only_drip_transit_or_adapters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (caller_) = get_caller_address();
    let (adapter_to_contract_) = adapter_to_contract.read(caller_);

    let (is_not_adapter_) = is_equal(adapter_to_contract_, 0);
    let (drip_transit_) = drip_transit.read();

    with_attr error_message("Only the configurator can call this function") {
        assert (is_not_adapter_ * (drip_transit_ - caller_)) = 0;
    }
    return();
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_pool: felt) {
    alloc_locals;
    with_attr error_message("pool is address zero") {
        assert_not_zero(_pool);
    }
    let (registery_) = IPool.getRegistery(_pool);
    registery.write(registery_);
    let (underlying_) = IPool.asset(_pool);
    underlying.write(underlying_);
    add_token(underlying_);
    let (oracle_transit_) = IRegistery.oracleTransit(registery_);
    oracle_transit.write(oracle_transit_);
    let (drip_factory_) = IRegistery.dripFactory(registery_);
    drip_factory.write(drip_factory_);
    let (drip_configurator_) = get_caller_address();
    drip_configurator.write(drip_configurator_);
    return ();
}

@external
func openDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrowed_amount: Uint256, _on_belhalf_of: felt
) -> (drip: felt) {
    alloc_locals;
    ReentrancyGuard._start();
    assert_only_drip_transit();
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_allowed_borrowed_amount1_) = uint256_lt(minimum_borrowed_amount_, _borrowed_amount);
    let (is_allowed_borrowed_amount2_) = uint256_lt(_borrowed_amount, maximum_borrowed_amount_);
    with_attr error_message("borrow amount out of limit") {
        assert_not_zero(is_allowed_borrowed_amount1_ * is_allowed_borrowed_amount2_);
    }
    let (pool_) = pool.read();
    let (cumulative_index_) = IPool.calculLinearCumulativeIndex(pool_);
    let (drip_factory_) = drip_factory.read();
    let (drip_) = IDripFactory.takeDrip(drip_factory_, _borrowed_amount, cumulative_index_);
    IPool.borrow(pool_, _borrowed_amount, drip_);
    safe_drip_set(_on_belhalf_of, drip_);
    enabled_tokens.write(drip_, Uint256(1, 0));
    fast_check_counter.write(drip_, Uint256(1, 0));
    ReentrancyGuard._end();
    return (drip_,);
}

@external
func closeDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _borrower: felt, _is_liquidated: felt, _total_value: Uint256, _payer: felt, _to: felt
) -> (remainingFunds: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    assert_only_drip_transit();
    let (drip_) = getDripOrRevert(_borrower);
    let (borrowed_amount_, borrowed_amount_with_interests_) = calcDripAccruedInterest(drip_);
    let (amount_to_pool_, remaining_funds_, profit_, loss_) = calcClosePayments(
        _total_value, _is_liquidated, borrowed_amount_, borrowed_amount_with_interests_
    );
    let (underlying_) = underlying.read();
    let (underlying_balance_) = IERC20.balanceOf(underlying_, drip_);
    let (stack_) = SafeUint256.add(amount_to_pool_, remaining_funds_);
    let (is_surplus_) = uint256_lt(stack_, underlying_balance_);
    if (is_surplus_ == 1) {
        let (surplus_) = SafeUint256.sub_lt(underlying_balance_, stack_);
        IDrip.safeTransfer(drip_, underlying_, _to, surplus_);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        let (cover_) = SafeUint256.sub_le(stack_, underlying_balance_);
        IERC20.transferFrom(underlying_ ,_payer, drip_, cover_);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    let (pool_) = pool.read();
    IDrip.safeTransfer(drip_, underlying_, pool_, amount_to_pool_);
    IPool.repayDripDebt(pool_, borrowed_amount_, profit_, loss_);

    // transfer remaining funds to borrower [Liquidation case only]
    let (is_remaining_funds_) = uint256_lt(Uint256(0, 0), remaining_funds_);
    if (is_remaining_funds_ == 1) {
        IDrip.safeTransfer(drip_, underlying_, _borrower, remaining_funds_);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }   
    transfer_assets_to(drip_, _to);
    let (drip_factory_) = drip_factory.read();
    IDripFactory.returnDrip(drip_factory_, drip_);
    borrower_to_drip.write(_borrower, 0);
    ReentrancyGuard._end();
    return (remaining_funds_,);
}

@external
func manageDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrower: felt, _amount: Uint256, _increase: felt
) {
    alloc_locals;
    ReentrancyGuard._start();
    assert_only_drip_transit();
    let (drip_) = getDripOrRevert(_borrower);
    let (borrowed_amount_, cumulative_index_, current_cumulative_index_) = dripParameters(drip_);
    let (pool_) = pool.read();
    let (underlying_) = underlying.read();
    tempvar temp_borrowed_amount: Uint256;
    if (_increase == 0) {
        let (new_borrowed_amount_) = SafeUint256.sub_lt(borrowed_amount_, _amount);
        temp_borrowed_amount.low = new_borrowed_amount_.low;
        temp_borrowed_amount.high = new_borrowed_amount_.high;
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        let (new_borrowed_amount_) = SafeUint256.add(borrowed_amount_, _amount);
        temp_borrowed_amount.low = new_borrowed_amount_.low;
        temp_borrowed_amount.high = new_borrowed_amount_.high;
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_allowed_borrowed_amount1_) = uint256_lt(minimum_borrowed_amount_, temp_borrowed_amount);
    let (is_allowed_borrowed_amount2_) = uint256_lt(temp_borrowed_amount, maximum_borrowed_amount_);
    with_attr error_message("borrow amount out of limit") {
        assert_not_zero(is_allowed_borrowed_amount1_ * is_allowed_borrowed_amount2_);
    }

    if (_increase == 1) {
        let (step1_) = SafeUint256.mul(current_cumulative_index_, cumulative_index_);
        let (step2_) = SafeUint256.mul(step1_, temp_borrowed_amount);
        let (step3_) = SafeUint256.mul(current_cumulative_index_, _amount);
        let (step4_) = SafeUint256.mul(cumulative_index_, borrowed_amount_);
        let (step5_) = SafeUint256.add(step4_, step3_);
        let (cumulative_index_at_borrow_more_, _) = SafeUint256.div_rem(step2_, step5_);
        IPool.borrow(pool_, _amount, drip_);
        IDrip.updateParameters(drip_, temp_borrowed_amount, cumulative_index_at_borrow_more_);
        ReentrancyGuard._end();
        return ();
    } else {
        let (step1_) = SafeUint256.mul(borrowed_amount_, current_cumulative_index_);
        let (step2_, _) = SafeUint256.div_rem(step1_, cumulative_index_);
        let (interest_accrued_) = SafeUint256.sub_le(step2_, borrowed_amount_);
        let (fee_interest_) = fee_interest.read();
        let (profit_precision_) = SafeUint256.mul(interest_accrued_, fee_interest_);
        let (profit_, _) = SafeUint256.div_rem(profit_precision_, Uint256(PRECISION, 0));
        let (step1_) = SafeUint256.add(_amount, interest_accrued_);
        let (total_) = SafeUint256.add(step1_, profit_);
        IDrip.safeTransfer(drip_, underlying_, pool_, total_);
        IPool.repayDripDebt(pool_, step1_, profit_, Uint256(0, 0));
        let (new_cumulative_index_) = IPool.calculLinearCumulativeIndex(pool_);
        IDrip.updateParameters(drip_, temp_borrowed_amount, new_cumulative_index_);
        ReentrancyGuard._end();
        return ();
    }
}

@external
func addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _payer: felt, _on_belhalf_of: felt, _token: felt, _amount: Uint256
) {
    alloc_locals;
    ReentrancyGuard._start();
    assert_only_drip_transit();
    let (drip_) = getDripOrRevert(_on_belhalf_of);
    check_and_enable_token(drip_, _token);
    IERC20.transferFrom(_token, _payer, drip_, _amount);
    ReentrancyGuard._end();
    return ();
}

@external
func transferDripOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _from: felt, _to: felt
) {
    ReentrancyGuard._start();
    assert_only_drip_transit();
    let (drip_) = getDripOrRevert(_from);
    borrower_to_drip.write(_from, 0);
    safe_drip_set(_to, drip_);
    ReentrancyGuard._end();
    return ();
}

@external
func approveDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrower: felt, _target: felt, _token: felt, _amount: Uint256
) {
    alloc_locals;
    ReentrancyGuard._start();
    assert_only_drip_transit_or_adapters();
    let (caller_) = get_caller_address();
    let (drip_transit_) = drip_transit.read();
    let (is_drip_transit_) = is_equal(caller_, drip_transit_);
    if (is_drip_transit_ == 0) {
        let (adapter_to_contract_) = adapter_to_contract.read(caller_);
        let (is_target_) = is_equal(adapter_to_contract_,  _target);
        with_attr error_message("not allowed target") {
            assert_not_zero(_target * is_target_);
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    let (token_mask_) = token_mask.read(_token);
    let (is_nul_)= uint256_eq(Uint256(0,0), token_mask_);
    with_attr error_message("not allowed token") {
        assert is_nul_ = 0;
    }
    let (drip_) = getDripOrRevert(drip_transit_);
    IDrip.approveToken(drip_, _token, _target);
    ReentrancyGuard._end();
    return ();
}

@external
func executeOrder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrower: felt, _to: felt, _selector: felt, _calldata_len: felt, _calldata: felt*
) -> (retdata_len: felt, retdata: felt*) {
    alloc_locals;
    ReentrancyGuard._start();
    let (caller_) = get_caller_address();
    let (adapter_to_contract_) = adapter_to_contract.read(caller_);
    let (is_target_) = is_equal(adapter_to_contract_, _to);
    with_attr error_message("not allowed target") {
        assert_not_zero(_to * is_target_);
    }
    let (drip_) = getDripOrRevert(_borrower);
    let (retdata_len: felt, retdata: felt*) = IDrip.execute(
        drip_, _to, _selector, _calldata_len, _calldata
    );
    ReentrancyGuard._end();
    ExecuteOrder.emit(_borrower, _to);
    return (retdata_len, retdata);
}

@external
func checkAndEnableToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _drip: felt, _token: felt
) {
    assert_only_drip_transit_or_adapters();
    check_and_enable_token(_drip, _token);
    return ();
}

@external
func fastCollateralCheck{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _drip: felt,
    _token_in: felt,
    _token_out: felt,
    _balance_in_before: Uint256,
    _balance_out_before: Uint256,
) {
    alloc_locals;
    assert_only_drip_transit_or_adapters();
    check_and_enable_token(_drip, _token_in);
    let (fast_check_counter_) = fast_check_counter.read(_drip);
    let (hf_check_interval_) = hf_check_interval.read();
    let (oracle_transit_) = oracle_transit.read();
    let (is_le_) = uint256_le(fast_check_counter_, hf_check_interval_);
    if (is_le_ == 1) {
        let (balance_in_after_) = IERC20.balanceOf(_token_in, _drip);
        let (balance_out_after_) = IERC20.balanceOf(_token_out, _drip);
        let (diff_in_) = SafeUint256.sub_le(_balance_in_before, balance_in_after_);
        let (diff_out_) = SafeUint256.sub_le(balance_out_after_, _balance_out_before);
        let (amount_in_collateral_, amount_out_collateral_) = IOracleTransit.fastCheck(
            oracle_transit_, diff_in_, _token_in, diff_out_, _token_out
        );
        let (is_le_) = uint256_le(balance_in_after_, Uint256(1, 0));
        let (amount_out_collateral_precision_) = SafeUint256.mul(
            amount_out_collateral_, Uint256(PRECISION, 0)
        );
        let (chi_threshold_) = chi_threshold.read();
        let (amount_in_collateral_chi_) = SafeUint256.mul(amount_in_collateral_, chi_threshold_);
        let (is_lt_) = uint256_lt(amount_in_collateral_chi_, amount_out_collateral_precision_);
        if (is_lt_ == 1) {
            let (new_fast_check_counter_) = SafeUint256.add(fast_check_counter_, Uint256(1, 0));
            fast_check_counter.write(_drip, new_fast_check_counter_);
            return ();
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    fullCollateralCheck(_drip);
    return ();
}

@external
func addToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) {
    assert_only_drip_configurator();
    add_token(_token);
    return ();
}

@external
func setParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _minimum_borrowed_amount: Uint256,
    _maximum_borrowed_amount: Uint256,
    _fee_interest: Uint256,
    _fee_liquidation: Uint256,
    _liquidation_discount: Uint256,
    _chi_threshold: Uint256,
    _hf_check_interval: Uint256,
) {
    assert_only_drip_configurator();
    let (is_lt_) = uint256_lt(_maximum_borrowed_amount, _minimum_borrowed_amount);
    with_attr error_message("Incorrect limits") {
        assert is_lt_ = 0;
    }
    minimum_borrowed_amount.write(_minimum_borrowed_amount);
    maximum_borrowed_amount.write(_maximum_borrowed_amount);
    fee_interest.write(_fee_interest);
    fee_liqudidation.write(_fee_liquidation);
    chi_threshold.write(_chi_threshold);
    hf_check_interval.write(_hf_check_interval);
    return ();
}

@external
func setLiquidationThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _token: felt, _liquidation_threshold: Uint256
) {
    alloc_locals;
    assert_only_drip_configurator();
    let (token_mask_) = token_mask.read(_token);
    let (is_nul_) = uint256_eq(Uint256(0,0), token_mask_);
    with_attr error_message("token not allowed") {
        assert is_nul_ = 0;
    }
    liquidation_threshold.write(_token, _liquidation_threshold);
    return ();
}

@external
func setForbidMask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _fobid_mask: Uint256
) {
    assert_only_drip_configurator();
    forbiden_token_mask.write(_fobid_mask);
    return ();
}

@external
func setDripConfigurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip_configurator: felt
) {
    assert_only_drip_configurator();
    drip_configurator.write(_drip_configurator);
    return ();
}


@external
func changeContractAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _adapter: felt, _target: felt
) {
    assert_only_drip_configurator();
    adapter_to_contract.write(_adapter, _target);
    return ();
}

@external
func upgradeContracts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip_transit: felt, _oracle_transit: felt
) {
    assert_only_drip_configurator();
    drip_transit.write(_drip_transit);
    drip_transit.write(_oracle_transit);
    return ();
}


func fullCollateralCheck{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _drip: felt
) {
    alloc_locals;
    let (_, borrowed_amount_with_interests_) = calcDripAccruedInterest(_drip);
    let (underlying_) = underlying.read();
    let (oracle_transit_) = oracle_transit.read();
    let (borrowed_amount_with_interests_usd_) = IOracleTransit.convertToUSD(
        oracle_transit_, borrowed_amount_with_interests_, underlying_
    );
    let (borrowed_amount_with_interests_usd_precision_,_) = SafeUint256.div_rem(
        borrowed_amount_with_interests_usd_, Uint256(PRECISION, 0)
    );
    let (count_) = allowed_tokens_length.read();
    let (enabled_tokens_) = enabled_tokens.read(_drip);
    let (total_twv_usd_precision_) = recursive_calcul_value(
        0, count_, _drip, enabled_tokens_, oracle_transit_, Uint256(0, 0)
    );
    let (is_lt_) = uint256_lt(
        total_twv_usd_precision_, borrowed_amount_with_interests_usd_precision_
    );
    with_attr error_message("not enough collateral") {
        assert_not_zero(is_lt_);
    }
    let (fast_check_counter_) = fast_check_counter.read(_drip);
    fast_check_counter.write(_drip, Uint256(1, 0));
    return ();
}

// Getters

@view
func tokenMask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) -> (token_mask: Uint256) {
    let (token_mask_) = token_mask.read(_token);
    return(token_mask_,);
}

@view
func allowedToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_id: felt) -> (allowed_token: felt) {
    let (allowed_token_) = id_to_allowed_token.read(_id);
    return(allowed_token_,);
}

@view
func enabledTokensMap{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (enabled_tokens: Uint256) {
    let (enabled_tokens_) = enabled_tokens.read(_drip);
    return(enabled_tokens_,);
}


@view
func liquidationThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) -> (liquidation_threshold: Uint256) {
    let (liquidation_threshold_) = liquidation_threshold.read(_token);
    return(liquidation_threshold_,);
}


@view
func adapterToContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_adapter: felt) -> (contract: felt) {
    let (contract_) = adapter_to_contract.read(_adapter);
    return(contract_,);
}

@view
func feeInterest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (feeInterest: Uint256) {
    let (fee_interest_) = fee_interest.read();
    return(fee_interest_,);
}

@view
func feeLiquidation{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (feeLiquidation: Uint256) {
    let (fee_liqudidation_) = fee_liqudidation.read();
    return(fee_liqudidation_,);
}

@view
func liquidationDiscount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (liquidationDiscount: Uint256) {
    let (liquidation_discount_) = liquidation_discount.read();
    return(liquidation_discount_,);
}

@view
func chiThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (chiThreshold: Uint256) {
    let (chi_threshold_) = chi_threshold.read();
    return(chi_threshold_,);
}

@view
func hfCheckInterval{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (hf_check_interval: Uint256) {
    let (hf_check_interval_) = hf_check_interval.read();
    return(hf_check_interval_,);
}

@view
func minBorrowedAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (minimum_borrowed_amount: Uint256) {
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    return(minimum_borrowed_amount_,);
}

@view
func maxBorrowedAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (maximum_borrowed_amount: Uint256) {
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    return(maximum_borrowed_amount_,);
}

@view
func getPool{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (pool: felt) {
    let (pool_) = pool.read();
    return(pool_,);
}

@view
func dripConfigurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (drip_configurator: felt) {
    let (drip_configurator_) = drip_configurator.read();
    return(drip_configurator_,);
}

@view
func calcClosePayments{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _total_value: Uint256,
    _is_liquidated: felt,
    _borrowed_amount: Uint256,
    _borrowed_amount_with_interests: Uint256,
) -> (amount_to_pool: Uint256, remaining_funds: Uint256, profit: Uint256, loss: Uint256) {
    alloc_locals;
    let (fee_interest_) = fee_interest.read();
    let (step1_) = SafeUint256.sub_le(_borrowed_amount_with_interests, _borrowed_amount);
    let (step2_) = SafeUint256.mul(step1_, fee_interest_);
    let (step3_, _) = SafeUint256.div_rem(step2_, Uint256(PRECISION, 0));
    let (amount_to_pool_) = SafeUint256.add(step3_, _borrowed_amount_with_interests);
    tempvar temp_amount_to_pool_: Uint256;
    tempvar temp_remaining_funds_: Uint256;
    tempvar temp_profit_: Uint256;
    tempvar temp_loss_: Uint256;
    if (_is_liquidated == 1) {
        let (liquidation_discount_) = liquidation_discount.read();
        let (fee_liqudidation_) = fee_liqudidation.read();
        let (step1_) = SafeUint256.add(_total_value, liquidation_discount_);
        let (total_funds_, _) = SafeUint256.div_rem(step1_, Uint256(PRECISION, 0));
        let (step1_) = SafeUint256.mul(_total_value, fee_liqudidation_);
        let (new_amount_to_pool_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION, 0));
        let (is_le_) = uint256_le(new_amount_to_pool_, total_funds_);
        if (is_le_ == 1) {
            let (remaining_funds_) = SafeUint256.sub_le(total_funds_, new_amount_to_pool_);
            temp_remaining_funds_.low = remaining_funds_.low;
            temp_remaining_funds_.high = remaining_funds_.high;
            temp_amount_to_pool_.low = new_amount_to_pool_.low;
            temp_amount_to_pool_.high = new_amount_to_pool_.high;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            temp_remaining_funds_.low = 0;
            temp_remaining_funds_.high = 0;
            temp_amount_to_pool_.low = total_funds_.low;
            temp_amount_to_pool_.high = total_funds_.high;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        let (is_le_) = uint256_le(_borrowed_amount_with_interests, total_funds_);
        if (is_le_ == 1) {
            let (profit_) = SafeUint256.sub_le(
                temp_amount_to_pool_, _borrowed_amount_with_interests
            );
            temp_profit_.low = profit_.low;
            temp_profit_.high = profit_.high;
            temp_loss_.low = 0;
            temp_loss_.high = 0;
        } else {
            let (loss_) = SafeUint256.sub_lt(_borrowed_amount_with_interests, temp_amount_to_pool_);
            temp_loss_.low = loss_.low;
            temp_loss_.high = loss_.high;
            temp_profit_.low = 0;
            temp_profit_.high = 0;
        }
    } else {
        let (profit_) = SafeUint256.sub_lt(amount_to_pool_, _borrowed_amount_with_interests);
        temp_profit_.low = profit_.low;
        temp_profit_.high = profit_.high;
        temp_loss_.low = 0;
        temp_loss_.high = 0;
        temp_remaining_funds_.low = 0;
        temp_remaining_funds_.high = 0;
        temp_amount_to_pool_.low = amount_to_pool_.low;
        temp_amount_to_pool_.high = amount_to_pool_.high;
    }
    return (temp_amount_to_pool_, temp_remaining_funds_, temp_profit_, temp_loss_);
}

@view
func getDripOrRevert{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrower: felt
) -> (drip: felt) {
    let (drip_) = borrower_to_drip.read(_borrower);
    with_attr error_message("has not drip") {
        assert_not_zero(drip_);
    }
    return (drip_,);
}

@view
func getDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrower: felt
) -> (drip: felt) {
    let (drip_) = borrower_to_drip.read(_borrower);
    return (drip_,);
}

@view
func calcDripAccruedInterest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip: felt
) -> (borrowedAmount: Uint256, borrowedAmountWithInterest: Uint256) {
    alloc_locals;
    let (borrowed_amount_, cumulative_index_, current_cumulative_index_) = dripParameters(_drip);
    let (step1_) = SafeUint256.mul(borrowed_amount_, cumulative_index_);
    let (borrowed_amount_with_interests_, _) = SafeUint256.div_rem(
        step1_, current_cumulative_index_
    );
    return (borrowed_amount_, borrowed_amount_with_interests_,);
}

@view
func dripParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip: felt
) -> (borrowedAmount: Uint256, cumulativeIndex: Uint256, currentCumulativeIndex: Uint256) {
    let (borrowed_amount_) = IDrip.borrowedAmount(_drip);
    let (cumulative_index_) = IDrip.cumulativeIndex(_drip);
    let (pool_) = pool.read();
    let (current_cumulative_index_) = IPool.calculLinearCumulativeIndex(pool_);
    return (borrowed_amount_, cumulative_index_, current_cumulative_index_,);
}

@view
func allowedTokensLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    tokenLength: felt
) {
    let (allowed_token_length_) = allowed_tokens_length.read();
    return (allowed_token_length_,);
}

@view
func oracleTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    oracleTransit: felt
) {
    let (oracle_transit_) = oracle_transit.read();
    return (oracle_transit_,);
}

// Internals

func recursive_calcul_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _index: felt,
    _count: felt,
    _drip: felt,
    _enabled_tokens: Uint256,
    _oracle_transit: felt,
    _cumulative_twv_usd: Uint256,
) -> (total_twv_usd: Uint256) {
    alloc_locals;
    if (_index == _count) {
        return (_cumulative_twv_usd,);
    }
    let (token_mask_) = uint256_pow2(Uint256(_index, 0));
    let (low_) = bitwise_and(_enabled_tokens.low, token_mask_.low);
    let (high_) = bitwise_and(_enabled_tokens.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0, 0), Uint256(low_, high_));
    tempvar cumulative_twv_usd_temp_: Uint256;
    if (is_bt_ == 1) {
        let (token_) =  id_to_allowed_token.read(_count);
        let (balance_) = IERC20.balanceOf(token_, _drip);
        let (has_token_) = uint256_lt(Uint256(1, 0), balance_);
        if (has_token_ == 1) {
            let (value_) = IOracleTransit.convertToUSD(_oracle_transit, balance_, token_);
            let (lt_) = liquidation_threshold.read(token_);
            let (lt_value_) = SafeUint256.mul(value_, lt_);
            let (new_cumulative_twv_usd_) = SafeUint256.add(_cumulative_twv_usd, lt_value_);
            cumulative_twv_usd_temp_.low = new_cumulative_twv_usd_.low;
            cumulative_twv_usd_temp_.high = new_cumulative_twv_usd_.high;
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
        } else {
            disable_token(_drip, token_);
            cumulative_twv_usd_temp_.low = _cumulative_twv_usd.low;
            cumulative_twv_usd_temp_.high = _cumulative_twv_usd.high;
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
        }
    } else {
        cumulative_twv_usd_temp_.low = _cumulative_twv_usd.low;
        cumulative_twv_usd_temp_.high = _cumulative_twv_usd.high;
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    return recursive_calcul_value(
        _index + 1, _count, _drip, _enabled_tokens, _oracle_transit, cumulative_twv_usd_temp_
    );
}

func transfer_assets_to{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _drip: felt, _to: felt
) {
    alloc_locals;
    with_attr error_message("can't send to the zero address") {
        assert_not_zero(_to);
    }
    let (enabled_tokens_) = enabled_tokens.read(_drip);
    let (count_) = allowed_tokens_length.read();
    let (oracle_transit_) = oracle_transit.read();
    recursive_transfer_token(0, count_, _drip, _to, enabled_tokens_, oracle_transit_);
    return ();
}

func recursive_transfer_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _index: felt,
    _count: felt,
    _drip: felt,
    _to: felt,
    _enabled_tokens: Uint256,
    _oracle_transit: felt,
) {
    alloc_locals;
    if (_index == _count) {
        return ();
    }
    let (token_mask_) = uint256_pow2(Uint256(_index, 0));
    let (low_) = bitwise_and(_enabled_tokens.low, token_mask_.low);
    let (high_) = bitwise_and(_enabled_tokens.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0, 0), Uint256(low_, high_));
    if (is_bt_ == 1) {
        let (token_) = id_to_allowed_token.read(_count);
        let (balance_) = IERC20.balanceOf(token_, _drip);
        let (has_token_) = uint256_lt(Uint256(1, 0), balance_);
        if (has_token_ == 1) {
            IDrip.safeTransfer(_drip, token_, _to, balance_);
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        }
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    return recursive_transfer_token(
        _index + 1, _count, _drip, _to, _enabled_tokens, _oracle_transit
    );
}

func check_and_enable_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _drip: felt, _token: felt
) {
    alloc_locals;
    let (token_mask_) = token_mask.read(_token);
    let (is_nul1_) = uint256_eq(token_mask_, Uint256(0,0));
    let (forbiden_token_mask_) = forbiden_token_mask.read();

    let (low_) = bitwise_and(forbiden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(forbiden_token_mask_.high, token_mask_.high);
    let (is_nul2_) = uint256_eq(Uint256(0, 0), Uint256(low_, high_));
    with_attr error_message("not allowed token") {
        assert_not_zero(is_nul1_ * is_nul2_);
    }

    let (enabled_tokens_) = enabled_tokens.read(_drip);
    let (low_) = bitwise_and(enabled_tokens_.low, token_mask_.low);
    let (high_) = bitwise_and(enabled_tokens_.high, token_mask_.high);
    let (is_eq_) = uint256_eq(Uint256(0, 0), Uint256(low_, high_));
    if (is_eq_ == 0) {
        let (low_) = bitwise_or(enabled_tokens_.low, token_mask_.low);
        let (high_) = bitwise_or(enabled_tokens_.high, token_mask_.high);
        enabled_tokens.write(_drip, Uint256(low_, high_));
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    return ();
}

func disable_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
    _drip: felt, _token: felt
) {
    let (token_mask_) = token_mask.read(_token);
    let (enabled_tokens_) = enabled_tokens.read(_drip);
    let (low_) = bitwise_and(enabled_tokens_.low, token_mask_.low);
    let (high_) = bitwise_and(enabled_tokens_.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0, 0), Uint256(low_, high_));
    if (is_bt_ == 1) {
        let (low_) = bitwise_xor(enabled_tokens_.low, token_mask_.low);
        let (high_) = bitwise_xor(enabled_tokens_.high, token_mask_.high);
        enabled_tokens.write(_drip, Uint256(low_, high_));
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    return ();
}

func safe_drip_set{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrower: felt, _drip: felt
) {
    let (drip_) = borrower_to_drip.read(_borrower);
    let (has_not_drip_) = is_equal(0, drip_);
    with_attr error_message("zero address or user already has a drip") {
        assert_not_zero(_borrower * has_not_drip_);
    }
    borrower_to_drip.write(_borrower, _drip);
    return ();
}

func add_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) {
    alloc_locals;
    let (token_mask_) = token_mask.read(_token);
    let (is_bt_) = uint256_lt(Uint256(0, 0), token_mask_);
    with_attr error_message("token already added") {
        assert is_bt_ = 0;
    }

    let (allowed_token_length_) = allowed_tokens_length.read();
    let (is_le_) = uint256_le(Uint256(256, 0), Uint256(allowed_token_length_, 0));
    with_attr error_message("too much tokens") {
        assert is_le_ = 0;
    }
    let (token_mask_) = uint256_pow2(Uint256(allowed_token_length_ + 1, 0));
    token_mask.write(_token, token_mask_);
    allowed_token_to_id.write(_token, allowed_token_length_ + 1);
    id_to_allowed_token.write(allowed_token_length_ + 1, _token);
    allowed_tokens_length.write(allowed_token_length_ + 1);
    return ();
}

func is_equal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(a: felt, b: felt) -> (state: felt) {
    if (a == b){
        return(1,);
    } else {
        return(0,);
    }
}
