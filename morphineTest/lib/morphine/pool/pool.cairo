%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
)
from starkware.cairo.common.uint256 import (
    ALL_ONES,
    Uint256,
    uint256_check,
    uint256_eq,
    uint256_lt,
    uint256_le,
)
from starkware.cairo.common.math import assert_not_zero, assert_le, unsigned_div_rem

from openzeppelin.token.erc20.library import ERC20, ERC20_allowances
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.security.pausable.library import Pausable

from morphine.utils.RegisteryAccess import RegisteryAccess
from morphine.utils.fixedpointmathlib import mul_div_down, mul_div_up
from morphine.utils.safeerc20 import SafeERC20
from morphine.utils.various import uint256_permillion, PRECISION, SECONDS_PER_YEAR
from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IInterestRateModel import IInterestRateModel


// Events

@event
func Deposit(from_: felt, to: felt, amount: Uint256, shares: Uint256) {
}

@event
func Withdraw(from_: felt, to: felt, amount: Uint256, shares: Uint256) {
}

@event
func BorrowFrozen() {
}

@event
func BorrowUnfrozen() {
}

@event
func RepayFrozen() {
}

@event
func RepayUnfrozen() {
}

@event
func Borrow(from_: felt, amount: Uint256) {
}

@event
func RepayDebt(borrowedAmount: Uint256, profit: Uint256, loss: Uint256) {
}

@event
func NewWithdrawFee(value: Uint256) {
}

@event
func NewExpectedLiquidityLimit(value: Uint256) {
}

@event
func NewDripManagerConnected(drip: felt) {
}

@event
func UncoveredLoss(value: Uint256) {
}

@event
func NewInterestRateModel(interest_rate_model: felt) {
}


// Storage


@storage_var
func drip_manager() -> (res: felt) {
}

@storage_var
func underlying() -> (asset: felt) {
}

@storage_var
func interest_rate_model() -> (asset: felt) {
}

@storage_var
func expected_liquidity() -> (res: Uint256) {
}

@storage_var
func expected_liquidity_limit() -> (res: Uint256) {
}

@storage_var
func total_borrowed() -> (res: Uint256) {
}

@storage_var
func cumulative_index() -> (res: Uint256) {
}

@storage_var
func borrow_rate() -> (res: Uint256) {
}

@storage_var
func withdraw_fee() -> (res: Uint256) {
}

@storage_var
func last_updated_timestamp() -> (res: felt) {
}

@storage_var
func borrow_frozen() -> (res: felt) {
}

@storage_var
func repay_frozen() -> (res: felt) {
}

// Protectors


func assert_only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller_) = get_caller_address();
        let (drip_manager_) = drip_manager.read();
        with_attr error_message("caller not authorized") {
            assert caller_ = drip_manager_;
        }
        return ();
    }



// Constructor

// @notice Initialize the contract
// @param _registery registery address
// @param _asset asset use in the pool
// @param _name name of the pool
// @param _symbol symbol of the pool
// @param _expected_liquidity_limit pool liquidity limit
// @param _interest_rate_model pool interest rate
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _registery: felt,
    _asset: felt,
    _name: felt,
    _symbol: felt,
    _expected_liquidity_limit: Uint256,
    _interest_rate_model: felt
    ) {
    with_attr error_message("zero address not allowed") {
        assert_not_zero(_registery);
    }
    let (decimals_) = IERC20.decimals(_asset);
    ERC20.initializer(_name, _symbol, decimals_);
    underlying.write(_asset);
    RegisteryAccess.initializer(_registery);
    expected_liquidity_limit.write(_expected_liquidity_limit);
    cumulative_index.write(Uint256(PRECISION, 0));
    update_interest_rate_model(_interest_rate_model);
    return ();
}

// Actions

// Configurator stuff

// @notice pause pool contract
@external
func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RegisteryAccess.assert_only_owner();
    Pausable.assert_not_paused();
    Pausable._pause();
    return ();
}

// @notice unpause pool contract
@external
func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RegisteryAccess.assert_only_owner();
    Pausable.assert_paused();
    Pausable._unpause();
    return ();
}

// @notice freeze borrow from pool
@external
func freezeBorrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RegisteryAccess.assert_only_owner();
    assert_borrow_not_frozen();
    borrow_frozen.write(1);
    BorrowFrozen.emit();
    return ();
}

// @notice unfreeze borrow from pool
@external
func unfreezeBorrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RegisteryAccess.assert_only_owner();
    assert_borrow_frozen();
    borrow_frozen.write(0);
    BorrowUnfrozen.emit();
    return ();
}

// @notice freeze repay from pool
@external
func freezeRepay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RegisteryAccess.assert_only_owner();
    assert_repay_not_frozen();
    repay_frozen.write(1);
    RepayFrozen.emit();
    return ();
}

// @notice unfreeze repay from pool
@external
func unfreezeRepay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    RegisteryAccess.assert_only_owner();
    assert_repay_frozen();
    repay_frozen.write(0);
    let (caller_) = get_caller_address();
    RepayUnfrozen.emit();
    return ();
}

// @notice set withdraw fee from pool
// @param _base_withdraw_fee fee when withdraw pool
@external
func setWithdrawFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _base_withdraw_fee: Uint256
) {
    RegisteryAccess.assert_only_owner();
    let (max_fee_,_) = unsigned_div_rem(PRECISION, 100);
    let (is_allowed_amount1_) = uint256_le(_base_withdraw_fee, Uint256(max_fee_, 0));
    let (is_allowed_amount2_) = uint256_le(Uint256(0, 0), _base_withdraw_fee);
    with_attr error_message("0 <= withdrawFee <= 10.000") {
        assert is_allowed_amount1_ * is_allowed_amount2_ = 1;
    }
    withdraw_fee.write(_base_withdraw_fee);
    NewWithdrawFee.emit(_base_withdraw_fee);
    return ();
}

// @notice liquidity limit in pool
// @param _expected_liquidity_limit liquidity limit in pool
@external
func setExpectedLiquidityLimit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _expected_liquidity_limit: Uint256
) {
    RegisteryAccess.assert_only_owner();
    expected_liquidity_limit.write(_expected_liquidity_limit);
    NewExpectedLiquidityLimit.emit(_expected_liquidity_limit);
    return ();
}

// @notice update interest rate model in pool
// @param _interest_rate_model modify interest rate in pool
@external
func updateInterestRateModel{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _interest_rate_model: felt
) {
    RegisteryAccess.assert_only_owner();
    update_interest_rate_model(_interest_rate_model);
    return ();
}

// @notice connect a new drip manager to a pool
// @param _drip_manager drip manager address
@external
func connectDripManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip_manager: felt
) {
    alloc_locals;
    RegisteryAccess.assert_only_owner();
    let (this_) = get_contract_address();
    let (wanted_pool_) = IDripManager.getPool(_drip_manager);

    with_attr error_message("incompatible pool for drip manager") {
        assert this_ = wanted_pool_;
    }

    drip_manager.write(_drip_manager);
    NewDripManagerConnected.emit(_drip_manager);
    return ();
}

// Lender stuff

// @notice deposit assets in pool
// @param _assets amount of assets you want to deposit in the pool
// @param _receiver address who will receive the LP token
// @returns shares the number of LP you receive from deposit
@external
func deposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _assets: Uint256, _receiver: felt
) -> (shares: Uint256) {
    alloc_locals;
    ReentrancyGuard._start();
    Pausable.assert_not_paused();

    let (shares_) = previewDeposit(_assets);
    with_attr error_message("cannot deposit for 0 shares") {
        let (shares_is_zero) = uint256_eq(shares_, Uint256(0, 0));
        assert shares_is_zero = 0;
    }

    let (max_deposit_) = maxDeposit(_receiver);
    let (is_limit_not_exceeded_) = uint256_le(_assets, max_deposit_);
    with_attr error_message("amount exceeds max deposit") {
        assert is_limit_not_exceeded_ = 1;
    }

    with_attr error_message("zero address not allowed") {
        assert_not_zero(_receiver);
    }

    let (asset_) = underlying.read();
    let (caller_) = get_caller_address();
    let (this_) = get_contract_address();
    SafeERC20.transferFrom(asset_, caller_, this_, _assets);
    ERC20._mint(_receiver, shares_);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = SafeUint256.add(expected_liquidity_, _assets);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0, 0));

    ReentrancyGuard._end();
    Deposit.emit(caller_, _receiver, _assets, shares_);
    return (shares_,);
}

// @notice mint LP 
// @param _shares amount of shares you want to mint
// @param _receiver address who will receive the LP token
// @returns assets the number of assets you receive
@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _shares: Uint256, _receiver: felt
) -> (assets: Uint256) {
    alloc_locals;
    ReentrancyGuard._start();
    Pausable.assert_not_paused();

    let (assets_) = previewMint(_shares);

    with_attr error_message("cannot mint for 0 assets") {
        let (assets_is_zero_) = uint256_eq(assets_, Uint256(0, 0));
        assert assets_is_zero_ = 0;
    }

    let (max_mint_) = maxMint(_receiver);
    let (is_limit_not_exceeded_) = uint256_le(_shares, max_mint_);
    with_attr error_message("amount exceeds max mint") {
        assert is_limit_not_exceeded_ = 1;
    }

    with_attr error_message("zero address not allowed") {
        assert_not_zero(_receiver);
    }

    let (asset_) = underlying.read();
    let (caller_) = get_caller_address();
    let (this_) = get_contract_address();
    SafeERC20.transferFrom(asset_, caller_, this_, assets_);
    ERC20._mint(_receiver, _shares);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = SafeUint256.add(expected_liquidity_, assets_);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0, 0));

    ReentrancyGuard._end();
    Deposit.emit(caller_, _receiver, assets_, _shares);
    return (assets_,);
}

// @notice withdraw from pool
// @param _assets assets you want to retrieve
// @param _receiver address who will receive the LP token
// @param _owner owner address
// @returns shares the number of shares you retrieve

@external
func withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _assets: Uint256, _receiver: felt, _owner: felt
) -> (shares: Uint256) {
    alloc_locals;
    ReentrancyGuard._start();
    Pausable.assert_not_paused();
    let (registery_) = RegisteryAccess.registery();
    let (treasury_) = IRegistery.getTreasury(registery_);
    let (withdraw_fee_) = withdrawFee();
    let (step1_) = SafeUint256.mul(_assets, Uint256(PRECISION,0));
    let (step2_) = SafeUint256.sub_lt(Uint256(PRECISION,0), withdraw_fee_);
    let(assets_required_,_) = SafeUint256.div_rem(step1_, step2_);
    let (supply_) = ERC20.total_supply();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0));
    let (all_assets_) = totalAssets();
    let (res_) = mul_div_up(assets_required_, supply_, all_assets_);

    tempvar temp_shares_: Uint256;
    if (supply_is_zero == 1) {
        temp_shares_.low = assets_required_.low;
        temp_shares_.high = assets_required_.high;
    } else{
        temp_shares_.low = res_.low;
        temp_shares_.high = res_.high;
    }

    let shares_ = temp_shares_;

    let (shares_is_zero) = uint256_eq(shares_, Uint256(0, 0));
    with_attr error_message("cannot withdraw for 0 shares") {
        assert shares_is_zero = 0;
    }

    let (max_withdraw_) = maxWithdraw(_owner);
    let (is_limit_not_exceeded_) = uint256_le(_assets, max_withdraw_);
    with_attr error_message("amount exceeds max withdraw") {
        assert is_limit_not_exceeded_ = 1;
    }

    with_attr error_message("zero address not allowed") {
        assert_not_zero(_receiver);
    }

    let (caller_) = get_caller_address();
    ERC20_decrease_allowance_manual(_owner, caller_, shares_);
    ERC20._burn(_owner, shares_);

    let (ERC4626_asset_) = underlying.read();
    SafeERC20.transfer(ERC4626_asset_, _receiver, _assets);
    let (treasury_fee_) = SafeUint256.sub_le(assets_required_, _assets);
    SafeERC20.transfer(ERC4626_asset_, treasury_, treasury_fee_);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = SafeUint256.sub_le(expected_liquidity_, _assets);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0, 0));

    ReentrancyGuard._end();
    Withdraw.emit(_owner, _receiver, _assets, shares_);
    return (shares_,);
}

// @notice redeem from pool
// @param _shares number of shares you want to redeem
// @param _receiver address who will receive the reedem assets
// @param _owner owner address
// @returns assets the number of assets you reedem
@external
func redeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _shares: Uint256, _receiver: felt, _owner: felt
) -> (assets: Uint256) {
    alloc_locals;
    ReentrancyGuard._start();
    Pausable.assert_not_paused();

    let (assets_) = convertToAssets(_shares);
    let (withdraw_fee_) = withdrawFee();
    let (treasury_fee_) = mul_div_up(assets_, withdraw_fee_, Uint256(PRECISION,0));
    let (remaining_assets_) = SafeUint256.sub_le(assets_, treasury_fee_);
    let (registery_) = RegisteryAccess.registery();
    let (treasury_) = IRegistery.getTreasury(registery_);

    with_attr error_message("cannot redeem for 0 assets") {
        let (shares_is_zero) = uint256_eq(_shares, Uint256(0, 0));
        assert shares_is_zero = 0;
    }

    let (max_reedem_) = maxRedeem(_owner);
    let (is_limit_not_exceeded_) = uint256_le(_shares, max_reedem_);
    with_attr error_message("amount exceeds max redeem") {
        assert is_limit_not_exceeded_ = 1;
    }

    with_attr error_message("zero address not allowed") {
        assert_not_zero(_receiver);
    }

    let (caller_) = get_caller_address();
    ERC20_decrease_allowance_manual(_owner, caller_, _shares);
    ERC20._burn(_owner, _shares);

    let (ERC4626_asset_) = underlying.read();
    SafeERC20.transfer(ERC4626_asset_, _receiver, remaining_assets_);
    SafeERC20.transfer(ERC4626_asset_, treasury_, treasury_fee_);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = SafeUint256.sub_le(expected_liquidity_, assets_);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0, 0));

    ReentrancyGuard._end();
    Withdraw.emit(_owner, _receiver, remaining_assets_, _shares);
    return (remaining_assets_,);
}

// Borrower stuff

// @notice borrow from pool
// @param _borrow_amount amount borrow from the pool
// @param _drip address of the drip where you will got the assets borrowed
@external
func borrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrow_amount: Uint256, _drip: felt
) {
    alloc_locals;
    ReentrancyGuard._start();
    Pausable.assert_not_paused();
    assert_only_drip_manager();
    assert_borrow_not_frozen();
    let (underlying_) = underlying.read();
    with_attr error_message("drip address is zero") {
        assert_not_zero(_drip);
    }
    SafeERC20.transfer(underlying_, _drip, _borrow_amount);
    update_borrow_rate(Uint256(0, 0));

    let (total_borrowed_) = total_borrowed.read();
    let (new_total_borrowed_) = SafeUint256.add(total_borrowed_, _borrow_amount);
    total_borrowed.write(new_total_borrowed_);
    ReentrancyGuard._end();
    Borrow.emit(_drip, _borrow_amount);
    return ();
}

// @notice repay the drip debt
// @param _borrow_amount total amount you borrowed 
// @param _profit profit you made from the money you borrowed
// @param _loss loss you made from the money you borrowed
@external
func repayDripDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _borrowed_amount: Uint256, _profit: Uint256, _loss: Uint256
) {
    alloc_locals;
    ReentrancyGuard._start();
    Pausable.assert_not_paused();
    assert_only_drip_manager();
    assert_repay_not_frozen();

    let (is_profit_) = uint256_lt(Uint256(0, 0), _profit);

    let (registery_) = RegisteryAccess.registery();
    let (treasury_) = IRegistery.getTreasury(registery_);
    if (is_profit_ == 1) {
        let (amount_to_mint_) = convertToShares(_profit);
        ERC20._mint(treasury_, amount_to_mint_);
        let (expected_liquidity_) = expected_liquidity.read();
        let (new_expected_liqudity_) = SafeUint256.add(expected_liquidity_, _profit);
        expected_liquidity.write(new_expected_liqudity_);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        let (amount_to_burn_) = convertToShares(_loss);
        let (this_) = get_contract_address();
        let (treasury_balance_) = IERC20.balanceOf(this_, treasury_);
        let (is_treasury_balance_enough_) = uint256_le(amount_to_burn_, treasury_balance_);
        if (is_treasury_balance_enough_ == 0) {
            let (uncovered_loss_) = SafeUint256.sub_le(amount_to_burn_, treasury_balance_);
            UncoveredLoss.emit(uncovered_loss_);
            ERC20._burn(treasury_, treasury_balance_);
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            ERC20._burn(treasury_, amount_to_burn_);
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    }
    update_borrow_rate(_loss);
    let (total_borrowed_) = total_borrowed.read();
    let (new_total_borrowed_) = SafeUint256.sub_le(total_borrowed_, _borrowed_amount);
    total_borrowed.write(new_total_borrowed_);
    ReentrancyGuard._end();
    RepayDebt.emit(_borrowed_amount, _profit, _loss);
    return ();
}


//
// VIEW
//

// @notice check if contract are paused
// @return state if contract are paused
@view
func isPaused{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state : felt){
    let (is_paused_) = Pausable.is_paused();
    return(is_paused_,);
}

// @notice check if borrow are frozen
// @return state if borrow are frozen
@view
func isBorrowFrozen{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state : felt){
    let (is_borrow_frozen_) = borrow_frozen.read();
    return(is_borrow_frozen_,);
}

// @notice check if repay are frozen
// @return state if repay are frozen
@view
func isRepayFrozen{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state : felt){
    let (is_repay_frozen_) = repay_frozen.read();
    return(is_repay_frozen_,);
}


// @notice get registery 
// @return registery registrey address 
@view
func getRegistery{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (registery : felt){
    let (registery_) = RegisteryAccess.registery();
    return(registery_,);
}

// @notice get the underlying asset
// @return asset 
@view
func asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (asset: felt) {
    let (read_asset: felt) = underlying.read();
    return (read_asset,);
}


// @notice max deposit authorized 
// @param _to the address of the pool you want to deposit
// @return maxAssets the maximum amount of assets you can deposit
@view
func maxDeposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_to: felt) -> (
    maxAssets: Uint256
) {
    let (expected_liquidity_) = totalAssets();
    let (expected_liquidity_limit_) = expected_liquidity_limit.read();
    let (max_deposit_) = SafeUint256.sub_le(expected_liquidity_limit_, expected_liquidity_);
    return (max_deposit_,);
}

// @notice max mint authorized 
// @param _to the address of the pool where you want to mint shares
// @return maxShares the maximum amount of shares you can mint
@view
func maxMint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_to: felt) -> (
    maxShares: Uint256
) {
    let (max_deposit_) = maxDeposit(_to);
    let (max_mint_) = convertToShares(max_deposit_);
    return (max_mint_,);
}

// @notice max withdraw authorized 
// @param _from the address of the pool where you want to withdraw assets
// @return maxAsssets the maximum amount of assets you can withdraw
@view
func maxWithdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_from: felt) -> (
    maxAssets: Uint256
) {
    alloc_locals;
    let (balance_) = ERC20.balance_of(_from);
    let (max_assets_) = convertToAssets(balance_);
    let (withdraw_fee_) = withdrawFee();
    let (available_liquidity_) = availableLiquidity();
    let (is_enough_liquidity_) = uint256_le(max_assets_, available_liquidity_);
    if (is_enough_liquidity_ == 1) {
        let (treasury_fee_) = mul_div_up(max_assets_, withdraw_fee_, Uint256(PRECISION,0));
        let(new_max_assets_) = SafeUint256.sub_le(max_assets_, treasury_fee_);
        return (new_max_assets_,);
    } else {
        let (treasury_fee_) = mul_div_up(available_liquidity_, withdraw_fee_, Uint256(PRECISION,0));
        let(new_max_assets_) = SafeUint256.sub_le(available_liquidity_, treasury_fee_);
        return (new_max_assets_,);
    }
}


// @notice max redeem authorized 
// @param caller caller address
// @return maxShares the maximum amount of assets you can redeem
@view
func maxRedeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(caller: felt) -> (
    maxShares: Uint256
) {
    alloc_locals;
    let (max_assets_fee_) = maxWithdraw(caller);
    let (step1_) = SafeUint256.mul(max_assets_fee_, Uint256(PRECISION,0));
    let (withdraw_fee_) = withdrawFee();
    let (step2_) = SafeUint256.sub_lt(Uint256(PRECISION,0), withdraw_fee_);
    let (max_assets_, _) = SafeUint256.div_rem(step1_, step2_);
    let (max_reedem_) = convertToShares(max_assets_);
    return (max_reedem_,);
}

// @notice max redeem authorized 
// @param caller caller address
// @return maxShares the maximum amount of assets you can redeem
@view
func previewDeposit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _assets: Uint256
) -> (shares: Uint256) {
    return convertToShares(_assets);
}

// @notice give you preview of amount assets you will have if you burn your shares
// @param _shares number of shares
// @return assets number of assets you will have
@view
func previewMint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _shares: Uint256
) -> (assets: Uint256) {
    alloc_locals;
    let (supply_) = ERC20.total_supply();
    let (all_assets_) = totalAssets();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0));
    if(supply_is_zero == 1){
        return (_shares,);
    }
    let (assets_) = mul_div_up(_shares, all_assets_, supply_);
    return (assets_,);
}

// @notice give you preview of amount shares you will have if you withdraw your assets
// @param _assets number of assets
// @return shares number of shares you will have
@view
func previewWithdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _assets: Uint256
) -> (shares: Uint256) {
    alloc_locals;
    let (withdraw_fee_) = withdrawFee();
    let (step1_) = SafeUint256.mul(_assets, Uint256(PRECISION,0));
    let (step2_) = SafeUint256.sub_lt(Uint256(PRECISION,0), withdraw_fee_);
    let(assets_required_,_) = SafeUint256.div_rem(step1_, step2_);
    let (supply_) = ERC20.total_supply();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0));
    if (supply_is_zero == 1) {
        return (assets_required_,);
    }
    let (all_assets_) = totalAssets();
    let (shares_) = mul_div_up(assets_required_, supply_, all_assets_);
    return (shares_,);
}

// @notice give you preview of amount shares you will have if you withdraw your assets
// @param _shares number of shares
// @return assets number of assets you will have
@view
func previewRedeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _shares: Uint256
) -> (assets: Uint256) {
    alloc_locals;
    let (assets_) = convertToAssets(_shares);
    let (withdraw_fee_) = withdrawFee();
    let (treasury_fee_) = mul_div_up(assets_, withdraw_fee_, Uint256(PRECISION,0));
    let (remaining_assets_) = SafeUint256.sub_le(assets_, treasury_fee_);
    return (remaining_assets_,);
}


// @notice  calculate the cumulative index
//                                                           /     currentBorrowRate * timeDifference \
//  new_cumulative_index  = last_updated_cumulative_index * | 1 + ------------------------------------ |
//                                                          \              SECONDS_PER_YEAR          /
// @return cumulativeIndex new cumulativeIndex
@view
func calcLinearCumulativeIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (cumulativeIndex: Uint256) {
    alloc_locals;
    let (current_timestamp) = get_block_timestamp();
    let (last_updated_timestamp_) = last_updated_timestamp.read();
    let delta_timestamp_ = current_timestamp - last_updated_timestamp_;
    let (last_updated_cumulative_index_) = cumulative_index.read();
    let (borrow_rate_) = borrow_rate.read();

    //                                                           /     currentBorrowRate * timeDifference \
    //  new_cumulative_index  = last_updated_cumulative_index * | 1 + ------------------------------------ |
    //                                                          \              SECONDS_PER_YEAR          /

    let (step1_) = SafeUint256.mul(Uint256(delta_timestamp_, 0), borrow_rate_);
    let (step2_, _) = SafeUint256.div_rem(step1_, Uint256(SECONDS_PER_YEAR, 0));
    let (step3_) = SafeUint256.add(step2_, Uint256(PRECISION, 0));
    let (step4_) = SafeUint256.mul(step3_, last_updated_cumulative_index_);
    let (new_cumulative_index_, _) = SafeUint256.div_rem(step4_, Uint256(PRECISION, 0));
    return (new_cumulative_index_,);
}


// @notice convert assets to shares
// @param _assets assets to convert
// @return shares number of shares you can obtain from assets
@view
func convertToShares{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _assets: Uint256
) -> (shares: Uint256) {
    alloc_locals;
    let (supply_) = ERC20.total_supply();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0));
    if (supply_is_zero == 1) {
        return (_assets,);
    }
    let (all_assets_) = totalAssets();
    let (shares_) = mul_div_down(_assets, supply_, all_assets_);
    return (shares_,);
}

// @notice convert shares to assets
// @param _shares shares to convert
// @return assets number of assets you can obtain from shares
@view
func convertToAssets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _shares: Uint256
) -> (assets: Uint256) {
    alloc_locals;

    let (supply_) = ERC20.total_supply();
    let (all_assets_) = totalAssets();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0));
    if(supply_is_zero == 1){
        return (_shares,);
    }
    let (assets_) = mul_div_down(_shares, all_assets_, supply_);
    return (assets_,);
}

// @notice get total assets 
// @return totalManagedAssets total assets managed by a drip
@view
func totalAssets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalManagedAssets: Uint256
) {
    alloc_locals;
    let (expected_liquidity_) = expectedLiquidity();
    let (block_timestamp_) = get_block_timestamp();
    let (last_updated_timestamp_) = lastUpdatedTimestamp();
    let delta = block_timestamp_ - last_updated_timestamp_;
    let (total_borrowed_) = totalBorrowed();
    let (borrow_rate_) = borrowRate();

    //                                  currentBorrowRate * timeDifference
    //  interestAccrued = totalBorrow *  ------------------------------------
    //                                             SECONDS_PER_YEAR
    //

    let (step1_) = mul_div_down(borrow_rate_, Uint256(delta, 0), Uint256(SECONDS_PER_YEAR, 0));
    let (step2_) = SafeUint256.mul(total_borrowed_, step1_);
    let (interest_accrued_, _) = SafeUint256.div_rem(step2_, Uint256(PRECISION, 0));
    let (total_assets_) = SafeUint256.add(expected_liquidity_, interest_accrued_);
    return (total_assets_,);
}

// @notice get total borrowed
// @return totalBorrowed total borrowed by a drip
@view
func totalBorrowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalBorrowed: Uint256
) {
    let (total_borrowed_) = total_borrowed.read();
    return (total_borrowed_,);
}

// @notice get borrowed rate
// @return Borrow rate drip borrow rate
@view
func borrowRate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    borrowRate: Uint256
) {
    let (borrow_rate_) = borrow_rate.read();
    return (borrow_rate_,);
}

// @notice get cumulative index
// @return Borrow rate drip borrow rate after cumulative index
@view
func cumulativeIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    borrowRate: Uint256
) {
    let (cumulative_index_) = cumulative_index.read();
    return (cumulative_index_,);
}

// @notice get last timestamp update
// @return lastUpdatedTimestamp last time the timestamp was updated
@view
func lastUpdatedTimestamp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    lastUpdatedTimestamp: felt
) {
    let (last_updated_timestamp_) = last_updated_timestamp.read();
    return (last_updated_timestamp_,);
}

// @notice get expected liquidity
// @return expectedLiquidity expected liquidity
@view
func expectedLiquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (expectedLiquidity: Uint256) {
    let (expected_liquidity_) = expected_liquidity.read();
    return (expected_liquidity_,);
}

// @notice get expected liquidity limit
// @return expectedLiquidityLimit expected liquidity limit
@view
func expectedLiquidityLimit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    expectedLiquidityLimit: Uint256
) {
    let (expected_liquidity_limit_) = expected_liquidity_limit.read();
    return (expected_liquidity_limit_,);
}

// @notice get available liquidity 
// @return availableLiquidity available liquidity
@view
func availableLiquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    availableLiquidity: Uint256
) {
    let (underlying_) = underlying.read();
    let (this_) = get_contract_address();
    let (available_liquidity_) = IERC20.balanceOf(underlying_, this_);
    return (available_liquidity_,);
}

// @notice get withdrawFee
// @return withdrawFee withdraw fee
@view
func withdrawFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    withdrawFee: Uint256
) {
    alloc_locals;
    // let (withdraw_fee_) = withdraw_fee.read();
    // let (available_liquidity_) = availableLiquidity();
    // let (expected_liquidity_) = expected_liquidity.read();
    // let (is_expected_liquidity_nul_) = uint256_eq(expected_liquidity_,Uint256(0,0));
    // let (is_expected_liquidity_lt_expected_liquidity_) = uint256_le(expected_liquidity_, available_liquidity_);
    // if (is_expected_liquidity_nul_ + is_expected_liquidity_lt_expected_liquidity_  != 0) {
    //     return (Uint256(0,0),);
    // }

    // //                          expected_liquidity_ - available_liquidity
    // // liquidity_utilization = -------------------------------------
    // //                              expected_liquidity_

    // let (step1_) = SafeUint256.sub_le(expected_liquidity_, available_liquidity_);
    // let (step2_) = SafeUint256.mul(step1_, Uint256(PRECISION,0));
    // let (liquidity_utilization_,_) = SafeUint256.div_rem(step2_, expected_liquidity_);

    // // withdraw_fee = * liquidity_utilization * withdraw_fee_base_
    // let (withdraw_fee_) = mul_div_down(liquidity_utilization_, withdraw_fee_, Uint256(PRECISION,0));

    // fix or LU dependant, to think about
    let (withdraw_fee_) = withdraw_fee.read();
    return (withdraw_fee_,);
}

//
// INTERNALS
//

// @notice update borrow_rate
// @param loss calculate the new borrow rate
func update_borrow_rate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    loss: Uint256
) {
    alloc_locals;
    let (expected_liquidity_) = totalAssets();
    let (new_expected_liqudity_) = SafeUint256.sub_le(expected_liquidity_, loss);
    expected_liquidity.write(new_expected_liqudity_);

    let (new_cumulative_index_) = calcLinearCumulativeIndex();
    cumulative_index.write(new_cumulative_index_);

    let (interest_rate_model_) = interest_rate_model.read();
    let (available_liquidity_) = availableLiquidity();
    let (new_borrow_rate_) = IInterestRateModel.calcBorrowRate(interest_rate_model_, new_expected_liqudity_, available_liquidity_);
    borrow_rate.write(new_borrow_rate_);

    let (block_timestamp_) = get_block_timestamp();
    last_updated_timestamp.write(block_timestamp_);
    return ();
}

// @notice Decrease ERC20 allowance manual
// @param _owner drip owner
// @param _spender spender
// @param _subtracted_value allowance amount remove
func ERC20_decrease_allowance_manual{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(_owner: felt, _spender: felt, _subtracted_value: Uint256) -> () {
    alloc_locals;
    if (_spender == _owner) {
        return ();
    }
    let (current_allowance_: Uint256) = ERC20_allowances.read(_owner, _spender);
    let (is_le_) = uint256_le(_subtracted_value, current_allowance_);
    with_attr error_message("allowance below zero") {
        assert is_le_ = 1;
    }
    let (new_allowance_) = SafeUint256.sub_le(current_allowance_, _subtracted_value);
    ERC20._approve(_owner, _spender, new_allowance_);
    return ();
}

// @notice protector borrow not frozen
func assert_borrow_not_frozen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_frozen_) = borrow_frozen.read();
    with_attr error_message("borrow frozen") {
        assert is_frozen_ = 0;
    }
    return ();
}


// @notice protector borrow frozen
func assert_borrow_frozen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_frozen_) = borrow_frozen.read();
    with_attr error_message("borrow not frozen") {
        assert is_frozen_ = 1;
    }
    return ();
}

// @notice protector repay not frozen
func assert_repay_not_frozen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_frozen_) = repay_frozen.read();
    with_attr error_message("repay frozen") {
        assert is_frozen_ = 0;
    }
    return ();
}

// @notice protector repay frozen
func assert_repay_frozen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (is_frozen_) = repay_frozen.read();
    with_attr error_message("repay not frozen") {
        assert is_frozen_ = 1;
    }
    return ();
}

func update_interest_rate_model{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_interest_rate_model: felt) {
    with_attr error_message("repay not frozen") {
        assert_not_zero(_interest_rate_model);
    }
    interest_rate_model.write(_interest_rate_model);
    update_borrow_rate(Uint256(0,0));
    NewInterestRateModel.emit(_interest_rate_model);
    return ();
}


// ERC 20 STUFF

// Getters

// @notice get name
// @return name
@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    let (name_) = ERC20.name();
    return (name_,);
}

// @notice get symbol
// @return symbol
@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    let (symbol_) = ERC20.symbol();
    return (symbol_,);
}

// @notice get totalSupply
// @return totalSupply
@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply_: Uint256) = ERC20.total_supply();
    return (totalSupply_,);
}

// @notice get decimals
// @return decimals
@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    let (decimals_) = ERC20.decimals();
    return (decimals_,);
}

// @notice get balanceOf
// @return balanceOf
@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    let (balance_: Uint256) = ERC20.balance_of(account);
    return (balance_,);
}

// @notice get allowance
// @return allowance
@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _owner: felt, _spender: felt
) -> (remaining: Uint256) {
    let (remaining_: Uint256) = ERC20.allowance(_owner, _spender);
    return (remaining_,);
}

// Externals

// @notice transfer ERC20
// @param  recipient
// @param  amount
// @return success
@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    ERC20.transfer(recipient, amount);
    return (1,);
}

// @notice transferFrom ERC20
// @param  sender
// @param  recipient
// @param  amount
// @return success
@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    ERC20.transfer_from(sender, recipient, amount);
    return (1,);
}

// @notice Approve ERC20
// @param  _spender
// @param  amount
// @return success
@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _spender: felt, amount: Uint256
) -> (success: felt) {
    ERC20.approve(_spender, amount);
    return (1,);
}

// @notice increaseAllowance ERC20
// @param  _spender
// @param  added_value
// @return success
@external
func increaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _spender: felt, added_value: Uint256
) -> (success: felt) {
    ERC20.increase_allowance(_spender, added_value);
    return (1,);
}

// @notice decreaseAllowance ERC20
// @param  _spender
// @param  subtracted_value
// @return success
@external
func decreaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _spender: felt, subtracted_value: Uint256
) -> (success: felt) {
    ERC20.decrease_allowance(_spender, subtracted_value);
    return (1,);
}
