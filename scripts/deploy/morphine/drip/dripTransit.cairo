%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_block_number,
    get_caller_address,
    call_contract,
    get_contract_address
)

from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_lt, uint256_pow2, uint256_le
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.security.safemath.library import SafeUint256
from morphine.utils.safeerc20 import SafeERC20
from morphine.utils.various import PRECISION, REVERT_IF_RECEIVED_LESS_THAN_SELECTOR, ADD_COLLATERAL_SELECTOR, INCREASE_DEBT_SELECTOR, DECREASE_DEBT_SELECTOR, ENABLE_TOKEN_SELECTOR, DISABLE_TOKEN_SELECTOR
from morphine.interfaces.IDripTransit import Call, AccountCallArray,tokenAndBalance
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IDripConfigurator import IDripConfigurator
from morphine.interfaces.IOracleTransit import IOracleTransit
from morphine.interfaces.IMorphinePass import IMorphinePass

/// @title Drip Transit
/// @author Graff Sacha (0xSacha)
/// @dev Contract Used to interact with the Drip Infrastructure
/// @custom:experimental This is an experimental contract.


//
// Events
//

@event 
func OpenDrip(owner: felt, drip: felt, borrowed_amount: Uint256){
}

@event 
func CloseDrip(caller: felt, to: felt){
}

@event 
func MultiCallStarted(borrower: felt){
}

@event 
func MultiCallFinished(){
}

@event 
func AddCollateral(on_belhalf_of: felt, token: felt, amount: Uint256){
}

@event 
func IncreaseBorrowedAmount(borrower: felt, amount: Uint256){
}

@event 
func DecreaseBorrowedAmount(borrower: felt, amount: Uint256){
}

@event 
func LiquidateDrip(borrower: felt, caller: felt, to: felt, remaining_funds: Uint256){
}

@event 
func LiquidateExpiredDrip(borrower: felt, caller: felt, to: felt, remaining_funds: Uint256){
}

@event 
func TransferDrip(_from : felt, to: felt){
}

@event 
func TransferDripAllowed(_from: felt, to: felt, _state: felt){
}

@event 
func TokenEnabled(_from: felt, token: felt){
}

@event 
func TokenDisabled(_from: felt, token: felt){
}



// Storage

@storage_var
func drip_manager() -> (address : felt) {
}

@storage_var
func underlying() -> (address : felt) {
}

@storage_var
func expirable() -> (state : felt) {
}

@storage_var
func expiration_date() -> (expiration_date : felt) {
}

@storage_var
func max_borrowed_amount_per_block() -> (max_borrowed_amount_per_block : Uint256) {
}

@storage_var
func minimum_borrowed_amount() -> (minimum_borrowed_amount : Uint256) {
}

@storage_var
func maximum_borrowed_amount() -> (maximum_borrowed_amount : Uint256) {
}

@storage_var
func last_block_saved() -> (block : felt) {
}

@storage_var
func last_limit_saved() -> (limit : Uint256) {
}

@storage_var
func transfers_allowed(_from: felt, to: felt) -> (is_allowed : felt) {
}

@storage_var
func is_increase_debt_forbidden() -> (is_increase_debt_forbidden: felt) {
}

@storage_var
func nft() -> (address: felt) {
}

// Protectors


// @notice: assert_only_drip_configurator 
// @dev: Check if Caller is Drip Configurator
func assert_only_drip_configurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() {
        let (caller_) = get_caller_address();
        let (drip_manager_) = drip_manager.read();
        let (drip_configurator_) = IDripManager.dripConfigurator(drip_manager_);
        with_attr error_message("caller is not drip configurator") {
            assert caller_ = drip_configurator_;
        }
        return ();
    }



//Constructor

// @notice: Drip Transit Constructor 
// @param: _drip_manager Drip Manager (felt)
// @param: _nft NFT Pass, 0 means permisionless (felt)
// @param: _expirable 1 if Drip Expirable, 0 else (felt)
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
    _drip_manager: felt,
    _nft: felt,
    _expirable: felt) {
    with_attr error_message("zero address"){
        assert_not_zero(_drip_manager);
    }
    let (underlying_)= IDripManager.underlying(_drip_manager);
    drip_manager.write(_drip_manager);
    underlying.write(underlying_);
    expirable.write(_expirable);
    nft.write(_nft);
    return();
}

// 
// Externals
//


// Drip

// @notice: Open Drip
// @param: _amount Collareral Amount (Uint256)
// @param: _on_belhalf_of Open Drip On Belhalf Of User (felt)
// @param: _leverage_factor Leverage Factor Collateral (Uint256)
@external
func openDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _amount: Uint256,
        _on_belhalf_of: felt,
        _leverage_factor: Uint256){
    alloc_locals;
    ReentrancyGuard.start();
    revert_if_open_drip_not_allowed(_on_belhalf_of);
    let (step1_) = SafeUint256.mul(_amount, _leverage_factor);
    let (borrowed_amount_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
    check_and_update_borrowed_block_limit(borrowed_amount_);
    revert_if_out_borrowed_limits(borrowed_amount_);

    let (drip_manager_) = drip_manager.read();
    let (liquidation_threshold_) = IDripManager.liquidationThresholdById(drip_manager_, 0);
    let (amount_ltu_) = SafeUint256.mul(_amount, liquidation_threshold_);
    let (less_ltu_) = SafeUint256.sub_lt(Uint256(PRECISION,0), liquidation_threshold_);
    let (borrow_less_ltu_) = SafeUint256.mul(borrowed_amount_, less_ltu_);
    let (is_lt_) = uint256_lt(borrow_less_ltu_, amount_ltu_);
    // check leverage <= LT / (1 - LT)
    with_attr error_message("wrong leverage factor"){
        assert is_lt_ = 1;
    }

    let (drip_) = IDripManager.openDrip(drip_manager_, borrowed_amount_, _on_belhalf_of);
    OpenDrip.emit(_on_belhalf_of, drip_, borrowed_amount_);
    let (underlying_) = underlying.read();
    add_collateral(_on_belhalf_of, drip_, underlying_, _amount);
    ReentrancyGuard.end();
    return();
}

// @notice: Open Drip Multi Call
// @param: _borrowed_amount Borrowed Amount (Uint256)
// @param: _on_belhalf_of Open Drip On Belhalf Of User (felt)
// @param: _call_array_len Call Array Length (felt)
// @param: _call_array Call Array (AccountCallArray*)
// @param: _calldata_len Call Data Length (felt)
// @param: _calldata_len Call Data (felt*)
@external
func openDripMultiCall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _borrowed_amount: Uint256,
        _on_belhalf_of: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard.start();
    revert_if_open_drip_not_allowed(_on_belhalf_of);
    check_and_update_borrowed_block_limit(_borrowed_amount);
    revert_if_out_borrowed_limits(_borrowed_amount);
    
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.openDrip(drip_manager_, _borrowed_amount, _on_belhalf_of);
    OpenDrip.emit(_on_belhalf_of, drip_, _borrowed_amount);
    
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, _on_belhalf_of, drip_, 0, 1);
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
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    ReentrancyGuard.end();
    return();
}

// @notice: Close Drip
// @param: _to Assets Receiver (felt)
// @param: _call_array_len Call Array Length (felt)
// @param: _call_array Call Array (AccountCallArray*)
// @param: _calldata_len Call Data Length (felt)
// @param: _calldata_len Call Data (felt*)
@external
func closeDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _to: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);

    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, caller_, drip_, 1, 0);
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

    IDripManager.closeDrip(drip_manager_, caller_, 0,  Uint256(0,0),caller_, _to);
    CloseDrip.emit(caller_, _to);
    ReentrancyGuard.end();
    return();
}

// @notice: Liquidate Drip
// @param: _borrower Borrower To Liquidate (felt)
// @param: _to Assets Receiver (felt)
// @param: _call_array_len Call Array Length (felt)
// @param: _call_array Call Array (AccountCallArray*)
// @param: _calldata_len Call Data Length (felt)
// @param: _calldata_len Call Data (felt*)
@external
func liquidateDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _borrower: felt,
        _to: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, _borrower);
    with_attr error_message("zero address"){
        assert_not_zero(_to);
    }

    let (is_liquidatable_, total_value_) = is_drip_liquidatable(drip_);
    with_attr error_message("can not Liquidate with such HF"){
        assert is_liquidatable_ = 1;
    }

    let (emergency_liquidation_) = check_if_emergency_liquidator(1);

    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, _borrower, drip_, 1, 0);
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
    if(emergency_liquidation_ == 1){
        check_if_emergency_liquidator(0);
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
    
    let (caller_) = get_caller_address();
    let (remaining_funds_) = IDripManager.closeDrip(drip_manager_, _borrower, 1, total_value_, caller_, _to);
    LiquidateDrip.emit(_borrower, caller_, _to, remaining_funds_);
    ReentrancyGuard.end();
    return();
}

// @notice: Liquidate Expired Drip
// @param: _borrower Borrower To Liquidate (felt)
// @param: _to Assets Receiver (felt)
// @param: _call_array_len Call Array Length (felt)
// @param: _call_array Call Array (AccountCallArray*)
// @param: _calldata_len Call Data Length (felt)
// @param: _calldata_len Call Data (felt*)
@external
func liquidateExpiredDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _borrower: felt,
        _to: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, _borrower);
    with_attr error_message("zero address"){
        assert_not_zero(_to);
    }

    let (is_expired_) = isExpired();
    with_attr error_message("can not liquidate non expired drip"){
        assert_not_zero(is_expired_);
    }

    let (emergency_liquidation_) = check_if_emergency_liquidator(1);
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, _borrower, drip_, 1, 0);
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

    if(emergency_liquidation_ == 1){
        check_if_emergency_liquidator(0);
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

    let (_, total_value_) = is_drip_liquidatable(drip_);
    let (caller_) = get_caller_address();
    let (remaining_funds_) = IDripManager.closeDrip(drip_manager_, _borrower, 2, total_value_, caller_, _to);
    LiquidateExpiredDrip.emit(_borrower, caller_, _to, remaining_funds_);
    ReentrancyGuard.end();
    return();
}

// Drip Management

// @notice: Increase Debt
// @param: _amount Debt Amount To Increase (Uint256)
@external
func increaseDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_amount: Uint256){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    increase_debt(caller_, drip_, _amount);
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    ReentrancyGuard.end();
    return();
}

// @notice: Decrease Debt
// @param: _amount Debt Amount To Decrease (Uint256)
@external
func decreaseDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_amount: Uint256){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    decrease_debt(caller_, drip_, _amount);
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    ReentrancyGuard.end();
    return();
}

// @notice: Add Collateral
// @param: _on_belhalf_of Add Collateral On Belhalf Of User (felt)
// @param: _token Token in which one is added the collateral (felt)
// @param: _amount Amount of Collateral Token (Uint256)
@external
func addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_on_belhalf_of: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, _on_belhalf_of);
    add_collateral(_on_belhalf_of, drip_, _token, _amount);
    IDripManager.checkAndOptimizeEnabledTokens(drip_manager_, drip_);
    ReentrancyGuard.end();
    return();
}


// @notice: multicall
// @param: _call_array_len Call Array Length (felt)
// @param: _call_array Call Array (AccountCallArray*)
// @param: _calldata_len Call Data Length (felt)
// @param: _calldata_len Call Data (felt*)
@external
func multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, caller_, drip_, 0, 0);
        IDripManager.fullCollateralCheck(drip_manager_, drip_);
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
    ReentrancyGuard.end();
    return();
}


// @notice: Enable Token
// @param: _token Token To Enable (felt)
@external
func enableToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_token: felt){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    enable_token(caller_, drip_, _token);
    IDripManager.checkAndOptimizeEnabledTokens(drip_manager_, drip_);
    ReentrancyGuard.end();
    return();
}

// @notice: Approve 
// @param: _target Contract To Give Token Allowance (felt)
// @param: _token Token To Approve (felt)
// @param: _amount of Token To Approve (Uint256)
@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_target: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    ReentrancyGuard.start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (adapter_) = IDripManager.contractToAdapter(drip_manager_, _target);
    with_attr error_message("target is not adapter"){
        assert_not_zero(adapter_);
    }
    IDripManager.approveDrip(drip_manager_, caller_, _target, _token, _amount);
    ReentrancyGuard.end();
    return();
}

// @notice: Transfer Ownership 
// @param: _to User To Transfer Drip Ownership (felt)
@external
func transferDripOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_to: felt){
    alloc_locals;
    let (nft_) = nft.read();
    let (is_zero_) = is_equal(nft_, 0);
    with_attr error_message("not permisonless error"){
        assert is_zero_ = 1;
    }
    let (caller_) = get_caller_address();
    let (is_allowed_) = transfers_allowed.read(caller_, _to);
    with_attr error_message("transfer not allowed"){
        assert_not_zero(is_allowed_);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (is_liquidatable_,_) = is_drip_liquidatable(drip_);
    with_attr error_message("transfer not allowed for liquiditable drip"){
        assert is_liquidatable_ = 0;
    }
    IDripManager.transferDripOwnership(drip_manager_, caller_, _to);
    TransferDrip.emit(caller_, _to);
    return();
}

// @notice: Approve Drip Transfer
// @param: _from User Allowed to addCollateral/open drip on belhalf of the caller (felt)
// @param: _state 1 if allowed, 0 else (felt)
@external
func approveDripTransfers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_from: felt, _state: felt){
    alloc_locals;
    let (caller_) = get_caller_address();
    transfers_allowed.write(_from, caller_, _state);
    TransferDripAllowed.emit(_from, caller_, _state);
    return();
}


// Configurator

// @notice: Set Increase Debt Forbidden
// @dev: Forbid or Allow increase debt, and open drip
// @param: _state 1 to forbid, 0 to allow (felt)
@external
func setIncreaseDebtForbidden{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_state: felt){
    alloc_locals;
    assert_only_drip_configurator();
    is_increase_debt_forbidden.write(_state);
    return();
}


// @notice: Set Max Borrowed Amount Per Block
// @dev: Permisionless case only, to avoid Flash Loan Attack
// @param: _max_borrowed_amount_per_block Max Borrowed Amount Per Block (Uint256)
@external
func setMaxBorrowedAmountPerBlock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_max_borrowed_amount_per_block: Uint256){
    alloc_locals;
    assert_only_drip_configurator();
    max_borrowed_amount_per_block.write(_max_borrowed_amount_per_block);
    return();
}

// @notice: Set Drip Limits
// @dev: Set Maximum and Minimum borrowed amount per Drip
// @param: _minimum_borrowed_amount Min Borrowed Amount (Uint256)
// @param: _maximum_borrowed_amount Max Borrowed Amount (Uint256)
@external
func setDripLimits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    alloc_locals;
    assert_only_drip_configurator();
    minimum_borrowed_amount.write(_minimum_borrowed_amount);
    maximum_borrowed_amount.write(_maximum_borrowed_amount);
    return();
}

// @notice: Set Expiration Date
// @dev: Effective only if drip transit expirable
// @param: _expiration_date Expiration Date (felt)
@external
func setExpirationDate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_expiration_date: felt){
    alloc_locals;
    assert_only_drip_configurator();
    expiration_date.write(_expiration_date);
    return();
}


//
// Views
//

// Dependencies

// @notice: Drip Manager
// @dev: Important when set new drip transit to the drip infra
// @return: dripManager Drip Manager (felt)
@view
func dripManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (dripManager: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    return(drip_manager_,);
}

// @notice: Get NFT
// @return: nft NFT Pass (felt)
@view
func getNft{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (nft: felt){
    alloc_locals;
    let (nft_) = nft.read();
    return(nft_,);
}

// Expiration

// @notice: Is Expired
// @return: state 1 if expired, 0 if live (felt)
@view
func isExpired{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (state: felt){
    alloc_locals;
    let (is_expirable_) = expirable.read();
    let (block_timestamp_) = get_block_timestamp();
    let (expiration_date_) = expiration_date.read();
    let (is_expired_) = uint256_le(Uint256(expiration_date_,0), Uint256(block_timestamp_, 0));
    if(is_expirable_ * is_expired_ == 0){
        return(0,);
    } else {
        return(1,);
    }
}

// Calcul

// @notice: Calcul Total Value
// @param: _drip Drip To Calculate Total Value (felt)
// @return: total Total Value (Uint256)
// @return: twv Total Weighted Value (Uint256)
@view
func calcTotalValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr : BitwiseBuiltin*}(_drip: felt) -> (total: Uint256, twv: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (oracle_transit_) = IDripManager.oracleTransit(drip_manager_);
    let (enabled_tokens_) = IDripManager.enabledTokensMap(drip_manager_, _drip);
    let (total_USD_: Uint256, twv_USD_precision_: Uint256) = recursive_calcul_value(0, _drip, enabled_tokens_, oracle_transit_, drip_manager_, Uint256(0,0), Uint256(0,0));
    let (underlying_) = underlying.read();
    let (total_) = IOracleTransit.convertFromUSD(oracle_transit_, total_USD_, underlying_);
    let (twv_precision_) = IOracleTransit.convertFromUSD(oracle_transit_, twv_USD_precision_, underlying_);
    let (twv_,_) = SafeUint256.div_rem(twv_precision_, Uint256(PRECISION,0));
    return(total_, twv_,);
}


// @notice: Calcul Drip Health Factor
// @param: _drip Drip To Calculate Health Factor (felt)
// @return: health_factor Drip Health Factor (Uint256)
@view
func calcDripHealthFactor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr : BitwiseBuiltin*}(_drip: felt) -> (health_factor: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (oracle_transit_) = IDripManager.oracleTransit(drip_manager_);
    let (tv_, tvw_) = calcTotalValue(_drip);
    let (_, _, borrowed_amount_with_interests_and_fees_) = IDripManager.calcDripAccruedInterest(drip_manager_, _drip);
    let (step1_) = SafeUint256.mul(tvw_, Uint256(PRECISION,0));
    let (hf_,_) = SafeUint256.div_rem(step1_, borrowed_amount_with_interests_and_fees_);
    return(hf_,);
}

// Control

// @notice: Has Opened Drip
// @param: _borrower Borrower (felt)
// @return: state 1 if Borrower opened drip, 0 else (felt)
@view
func hasOpenedDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_borrower: felt) -> (state: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDrip(drip_manager_, _borrower);
    if(drip_ == 0){
        return(0,);
    } else {
        return(1,);
    }
}

// @notice: Is Token Allowed
// @param: _token Token To Check (felt)
// @return: state 1 if Token allowed, 0 else (felt)
@view
func isTokenAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_token: felt) -> (state: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMask(drip_manager_, _token);
    let (forbidden_token_mask_) = IDripManager.forbiddenTokenMask(drip_manager_);
    let (low_) = bitwise_and(forbidden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(forbidden_token_mask_.high, token_mask_.high);
    let (is_nul_) = uint256_eq(Uint256(0,0),Uint256(low_, high_));
    let (is_bg_)= uint256_lt(Uint256(0,0), forbidden_token_mask_);
    if(is_nul_ * is_bg_ == 1){
        return(1,);
    } else {
        return(0,);
    }
}

// Parameters

// @notice: Is Increase Debt Forbidden
// @return: state 1 Increase Debt Forbidden, 0 else (felt)
@view
func isIncreaseDebtForbidden{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (state: felt){
    alloc_locals;
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    return(is_increase_debt_forbidden_,);
}

// @notice: Max Borrowed Amount Per Block
// @return: max_borrowed_amount_per_block_ Max Borrowed Amount Per Block (Uint256)
@view
func maxBorrowedAmountPerBlock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (max_borrowed_amount_per_block_: Uint256){
    alloc_locals;
    let (max_borrowed_amount_per_block_) = max_borrowed_amount_per_block.read();
    return(max_borrowed_amount_per_block_,);
}

// @notice: Expiration Date
// @return: expiration_date Expiration Date (felt)
@view
func expirationDate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (expiration_date: felt){
    alloc_locals;
    let (expiration_date_) = expiration_date.read();
    return(expiration_date_,);
}

// @notice: Is Expirable 
// @return: state 1 if expirable, 0 else (felt)
@view
func isExpirable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (state: felt){
    alloc_locals;
    let (is_expirable) = expirable.read();
    return(is_expirable,);
}

// @notice: Limits
// @return: minimum_borrowed_amount Minimum Borrowed Amount (Uint256)
// @return: max_borrowed_amount Maximum Borrowed Amount (Uint256)
@view
func limits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256){
    alloc_locals;
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_expirable) = expirable.read();
    return(minimum_borrowed_amount_, maximum_borrowed_amount_,);
}

// @notice: Last Limit Saved
// @dev: Used to calculate cumulative borowed amount per block
// @return: last_limit_saved Last Limit Saved (Uint256)
@view
func lastLimitSaved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (last_limit_saved: Uint256){
    alloc_locals;
    let (last_limit_saved_) = last_limit_saved.read();
    return(last_limit_saved_,);
}

// @notice: Last Block Saved
// @dev: Used to calculate cumulative borowed amount per block
// @return: last_block_saved Last Block Saved (felt)
@view
func lastBlockSaved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}() -> (last_block_saved: felt){
    alloc_locals;
    let (last_block_saved_) = last_block_saved.read();
    return(last_block_saved_,);
}

// @notice: Is Transfer Allowed
// @dev: Used to calculate cumulative borowed amount per block
// @param: _from User that can potentially transfer drip to to (felt)
// @param: _from User that can potentially receive drip from from (felt)
// @return: state 1 if transfer allowed,0 else (felt)
@view
func isTransferAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_from: felt, _to: felt) -> (state : felt){
    alloc_locals;
    let (is_tranfer_allowed_) = transfers_allowed.read(_from, _to);
    return(is_tranfer_allowed_,);
}



// Internals

// @notice: _multicall
// @param: _call_array_len Call Array Length (felt)
// @param: _call_array Call Array (AccountCallArray*)
// @param: _call_data Call Data (felt*)
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _is_closure Is Closing Drip (felt)
// @param: _is_increase_debt_was_called Is Increase Debt Was Called, for open drip multicall (felt)
func _multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _call_data: felt*,
        _borrower: felt,
        _drip: felt,
        _is_closure: felt,
        _is_increase_debt_was_called: felt){
    alloc_locals;
    let (this_) = get_contract_address();
    let (drip_manager_) = drip_manager.read();
    IDripManager.transferDripOwnership(drip_manager_, _borrower, this_);
    MultiCallStarted.emit(_borrower);
    let (calls: Call*) = alloc();
     _from_call_array_to_call(_call_array_len, _call_array, _call_data, calls);
    let (expected_balances: tokenAndBalance*) = alloc();
    let (expected_balances_len) = recursive_multicall(_call_array_len, calls, _borrower, _drip,_is_closure, _is_increase_debt_was_called, this_, drip_manager_, 0, expected_balances);
    check_expected_balances(expected_balances_len, expected_balances, _drip);
    MultiCallFinished.emit();
    IDripManager.transferDripOwnership(drip_manager_, this_, _borrower);
    return();
}

// @notice: recursive_multicall
// @param: _call_len Call Length (felt)
// @param: _call Call (Call*)
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _is_closure Is Closing Drip (felt)
// @param: _is_increase_debt_was_called Is Increase Debt Was Called, for open drip multicall (felt)
// @param: _this Drip Transit Address (felt)
// @param: _expected_balances_len Expected Balances Length (felt)
// @param: _expected_balances Expected Balances (tokenAndBalance*)
// @return: token_and_balances_len Token And Balances Length (felt)
func recursive_multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        _call_len: felt,
        _call: Call*,
        _borrower: felt,
        _drip: felt,
        _is_closure: felt,
        _is_increase_debt_was_called: felt,
        _this: felt,
        _drip_manager: felt,
        _expected_balances_len: felt,
        _expected_balances: tokenAndBalance*)
        -> (token_and_balances_len: felt){
    alloc_locals;
    if(_call_len == 0){
        return(_expected_balances_len,);
    }
    if(_call[0].to == _this){
        if(_is_closure == 1){
            let (is_method_slippage_controle_) = is_equal(REVERT_IF_RECEIVED_LESS_THAN_SELECTOR, _call[0].selector);
            with_attr error_message("no call allowed while closing drip"){
                assert is_method_slippage_controle_ = 1;
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
            tempvar bitwise_ptr = bitwise_ptr;
        }
        let (is_increase_debt_was_called_, expected_balances_len, expected_balances) = call_drip_facade(_call[0], _drip_manager, _borrower, _drip, _is_increase_debt_was_called, _expected_balances_len, _expected_balances);
        return recursive_multicall(_call_len - 1, _call + Call.SIZE, _borrower, _drip, _is_closure, is_increase_debt_was_called_, _this, _drip_manager, expected_balances_len, expected_balances);
    } else {
        let (contract_) = IDripManager.adapterToContract(_drip_manager, _call[0].to);
        with_attr error_message("forbidden call"){
            assert_not_zero((_call[0].to - _drip_manager)*contract_);
        }
        // let (retdata_len: felt, retdata: felt*) = 
        call_contract(_call[0].to, _call[0].selector, _call[0].calldata_len, _call[0].calldata);
        return recursive_multicall(_call_len - 1, _call + Call.SIZE, _borrower, _drip, _is_closure, _is_increase_debt_was_called, _this, _drip_manager, _expected_balances_len, _expected_balances);
    }
}

// @notice: call_drip_facade
// @dev: Called if a call in the multicall concerns drip transit
// @param: _call Call (Call)
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _is_increase_debt_was_called Is Increase Debt Was Called (felt)
// @param: _expected_balances_len Expected Balances Length (felt)
// @param: _expected_balances Expected Balances (tokenAndBalance*)
// @return: is_increase_debt_was_called 1 If Increase Debt Was Called (felt)
// @return: expected_balances_len Expected Balances Length (felt)
// @return: expected_balances Expected Balances (tokenAndBalance*)
func call_drip_facade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
        _call: Call,
        _drip_manager: felt,
        _borrower: felt,
        _drip: felt,
        _is_increase_debt_was_called: felt,
        _expected_balances_len: felt,
        _expected_balances: tokenAndBalance*) ->
        (is_increase_debt_was_called: felt, expected_balances_len: felt, expected_balances: tokenAndBalance*){
    alloc_locals;
    if(_call.selector == ADD_COLLATERAL_SELECTOR){
        let (caller_) = get_caller_address();
        with_attr error_message("incorrect datalen"){
            assert _call.calldata_len = 4;
        }
        
        if(_call.calldata[0] == _borrower){
            add_collateral(_call.calldata[0], _drip,_call.calldata[1], Uint256(_call.calldata[2],_call.calldata[3]));
            return(_is_increase_debt_was_called, _expected_balances_len, _expected_balances,);
        } else{
            let (drip_from_on_belhalf_of_) = IDripManager.getDripOrRevert(_drip_manager, _call.calldata[0]);
            add_collateral(_call.calldata[0], drip_from_on_belhalf_of_,_call.calldata[1], Uint256(_call.calldata[2],_call.calldata[3]));
            return(_is_increase_debt_was_called, _expected_balances_len, _expected_balances,);
        }
    } else{
        if(_call.selector == INCREASE_DEBT_SELECTOR){
            with_attr error_message("incorrect datalen"){
                assert _call.calldata_len = 2;
            }
            increase_debt(_borrower, _drip, Uint256(_call.calldata[0], _call.calldata[1]));
            return(1, _expected_balances_len, _expected_balances,);
        } else {
            if(_call.selector == DECREASE_DEBT_SELECTOR){
                with_attr error_message("can not decrease and increase debt"){
                    assert _is_increase_debt_was_called = 0;
                }
                with_attr error_message("incorrect datalen"){
                    assert _call.calldata_len = 2;
                }
                decrease_debt(_borrower, _drip, Uint256(_call.calldata[0], _call.calldata[1]));
                return(_is_increase_debt_was_called, _expected_balances_len, _expected_balances,);
            } else{
                if(_call.selector == REVERT_IF_RECEIVED_LESS_THAN_SELECTOR){
                    with_attr error_message("expected balance already set"){
                        assert _expected_balances_len = 0;
                    } 
                    let (expected_balances_len) = set_expected_balances(_expected_balances_len, _expected_balances, _call.calldata_len, _call.calldata, _drip);
                    return(_is_increase_debt_was_called, expected_balances_len, _expected_balances,);
                } else {
                    if(_call.selector == ENABLE_TOKEN_SELECTOR){
                        with_attr error_message("incorrect datalen"){
                            assert _call.calldata_len = 1;
                        }  
                        enable_token(_borrower, _drip, _call.calldata[0]);
                        return(_is_increase_debt_was_called, _expected_balances_len, _expected_balances,);
                    } else {
                        if(_call.selector == DISABLE_TOKEN_SELECTOR){
                            with_attr error_message("incorrect datalen"){
                                assert _call.calldata_len = 1;
                            }  
                            disable_token(_borrower, _drip, _call.calldata[0]);
                            return(_is_increase_debt_was_called, _expected_balances_len, _expected_balances,);
                        } else {
                            with_attr error_message("unknown selector"){
                                assert 0 = 7;
                            } 
                            return(_is_increase_debt_was_called, _expected_balances_len, _expected_balances,);
                        }
                    }
                }
            }
        }
    } 
}

// @notice: set_expected_balances
// @dev: Function used to set slippage
// @param: _expected_balances_len Expected Balances Length (felt)
// @param: _expected_balances Expected Balances (tokenAndBalance*)
// @param: _calldata_len Call Data Length (felt)
// @param: _calldata_len Call Data (felt*)
// @param: _drip Drip (felt)
// @return: expected_balances_len Expected Balances Length (felt)
func set_expected_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr: BitwiseBuiltin*}(
        _expected_balances_len: felt,
        _expected_balances: tokenAndBalance*,
        _calldata_len: felt,
        _calldata: felt*,
        _drip: felt) -> (expected_balances_len: felt){
    alloc_locals;
    if(_calldata_len == 0){
        return(_expected_balances_len,);
    }
    let (drip_balance_) =  IERC20.balanceOf(_calldata[0], _drip);
    let (new_expected_balance_) = SafeUint256.add(Uint256(_calldata[1], _calldata[2]), drip_balance_);
    assert _expected_balances[_expected_balances_len] = tokenAndBalance(_calldata[0], new_expected_balance_);
    return set_expected_balances(_expected_balances_len + 1, _expected_balances, _calldata_len - 3, _calldata + 3, _drip);
}


// @notice: check_expected_balances
// @dev: Function used to check slippage
// @param: _expected_balances_len Expected Balances Length (felt)
// @param: _expected_balances Expected Balances (tokenAndBalance*)
// @param: _drip Drip (felt)
func check_expected_balances{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr: BitwiseBuiltin*}(
        _expected_balances_len: felt,
        _expected_balances: tokenAndBalance*,
        _drip: felt){
    alloc_locals;
    if(_expected_balances_len == 0){
        return();
    }
    let (drip_balance_) =  IERC20.balanceOf(_expected_balances[0].token, _drip);
    let (is_lt_) = uint256_lt(drip_balance_, _expected_balances[0].balance);
    with_attr error_message("slippage error"){
        assert is_lt_ = 0;
    }
    return check_expected_balances(_expected_balances_len + 1, _expected_balances, _drip);
}

// @notice: recursive_calcul_value
// @dev: Loop on Drip Holdings to calculate total value
// @param: _index Token Indew (felt)
// @param: _drip Drip (felt)
// @param: _enabled_tokens Enabled Tokens Mask (Uint256)
// @param: _oracle_transit Oracle Transit (felt)
// @param: _drip_manager Drip Manager (felt)
// @param: _cumulative_total_usd Cumulative Total Value USD (Uint256)
// @param: _cumulative_twv_usd Cumulative Total Weighted Value USD (Uint256)
// @return: total_usd Total Value USD (Uint256)
// @return: twv Total Weighted Value USD (Uint256)
func recursive_calcul_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr: BitwiseBuiltin*}(
        _index: felt,
        _drip: felt,
        _enabled_tokens: Uint256,
        _oracle_transit: felt,
        _drip_manager: felt,
        _cumulative_total_usd: Uint256,
        _cumulative_twv_usd: Uint256) -> (total_usd: Uint256, twv: Uint256){
    alloc_locals;
    let (token_mask_) = uint256_pow2(Uint256(_index,0));
    let (is_lt_) = uint256_lt(_enabled_tokens, token_mask_);
    if(is_lt_ == 1){
        return(_cumulative_total_usd, _cumulative_twv_usd);
    }
    let (low_) = bitwise_and(_enabled_tokens.low, token_mask_.low);
    let (high_) = bitwise_and(_enabled_tokens.high, token_mask_.high);
    let (is_lt_) = uint256_lt(Uint256(0,0), Uint256(low_, high_));
    if(is_lt_ == 1){
        let (token_) = IDripManager.tokenByMask(_drip_manager, token_mask_);
        let (balance_) = IERC20.balanceOf(token_, _drip);
        let (has_token_) = uint256_lt(Uint256(1,0), balance_);
        if(has_token_ == 1){
            let (value_) = IOracleTransit.convertToUSD(_oracle_transit, balance_, token_);
            let (new_cumulative_total_usd_) = SafeUint256.add(_cumulative_total_usd, value_);
            let (liquidation_threshold_) = IDripManager.liquidationThresholdByMask(_drip_manager, token_mask_);
            let (lt_value_) = SafeUint256.mul(value_, liquidation_threshold_);
            let (new_cumulative_twv_usd_) = SafeUint256.add(_cumulative_twv_usd, lt_value_);
            return recursive_calcul_value(
                _index + 1,
                _drip,
                _enabled_tokens,
                _oracle_transit,
                _drip_manager,
                new_cumulative_total_usd_,
                new_cumulative_twv_usd_);
        } else {
            return recursive_calcul_value(
                _index + 1,
                _drip,
                _enabled_tokens,
                _oracle_transit,
                _drip_manager,
                _cumulative_total_usd,
                _cumulative_twv_usd);
        }
    } else {
        return recursive_calcul_value(
            _index + 1,
            _drip,
            _enabled_tokens,
            _oracle_transit,
            _drip_manager,
            _cumulative_total_usd,
            _cumulative_twv_usd);
    }
}


// @notice: Is Drip Liquiditable
// @param: _drip Drip (felt)
// @return: is_liquidatable 1 if drip liquiditable, 0 else (felt)
// @return: total_value Total Value (Uint256)
func is_drip_liquidatable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_drip: felt) -> (is_liquidatable: felt, total_value: Uint256){
    let (total_value_, tvw_) = calcTotalValue(_drip);
    let (drip_manager_) = drip_manager.read();
    let (_, _, borrowed_amount_with_interests_and_fees_) = IDripManager.calcDripAccruedInterest(drip_manager_ , _drip);
    let (is_lt_) = uint256_lt(tvw_, borrowed_amount_with_interests_and_fees_);
    if (is_lt_ == 1) {
        return(1, total_value_);
    } else {
        return(0, total_value_); 
    }
}

// @notice: increase_debt
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _amount Debt Amount To Increase (Uint256)
func increase_debt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrower: felt, _drip: felt, _amount: Uint256){
    alloc_locals;
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    with_attr error_message("increase debt forbidden"){
        assert is_increase_debt_forbidden_ = 0;
    }
    check_and_update_borrowed_block_limit(_amount);
    check_forbidden_tokens(_drip);
    let (drip_manager_) = drip_manager.read();
    let (new_borrowed_amount_) = IDripManager.manageDebt(drip_manager_, _drip, _amount, 1);
    revert_if_out_borrowed_limits(new_borrowed_amount_);
    IncreaseBorrowedAmount.emit(_borrower, _amount);
    return();
}

// @notice: check_forbidden_tokens
// @param: _drip Drip (felt)
func check_forbidden_tokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_drip: felt) {
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (enabled_tokens_) = IDripManager.enabledTokensMap(drip_manager_, _drip);
    let (forbidden_token_mask_) = IDripManager.forbiddenTokenMask(drip_manager_);
    let (low_) = bitwise_and(enabled_tokens_.low, forbidden_token_mask_.low);
    let (high_) = bitwise_and(enabled_tokens_.high, forbidden_token_mask_.high);
    let (is_lt_) = uint256_lt(Uint256(0, 0), Uint256(low_, high_));
    with_attr error_message("action prohibited with forbidden tokens"){
        assert is_lt_ = 0;
    }
    return();
}

// @notice: decrease_debt
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _amount Debt Amount To Decrease (Uint256)
func decrease_debt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrower: felt, _drip: felt, _amount: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (new_borrowed_amount_) = IDripManager.manageDebt(drip_manager_, _drip, _amount, 0);
    revert_if_out_borrowed_limits(new_borrowed_amount_);
    DecreaseBorrowedAmount.emit(_borrower, _amount);
    return();
}


// @notice: decrease_debt
// @dev: check borrow per block limit is respected, and update limit
// @param: _amount Amount of borrow (Uint256)
func check_and_update_borrowed_block_limit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_amount: Uint256){
    alloc_locals;
    let (nft_) = nft.read();
    let (is_zero_) = is_equal(0, nft_);
    if(is_zero_ == 1){
        let (max_borrowed_amount_per_block_) = max_borrowed_amount_per_block.read();
        let (last_block_) = last_block_saved.read();
        let (last_limit_) = last_limit_saved.read();
        let (new_limit_) = SafeUint256.add(_amount, last_limit_);
        let (block_number_) = get_block_number();
        tempvar temp_new_limit_: Uint256;
        if(block_number_ == last_block_){
            temp_new_limit_.low = new_limit_.low;
            temp_new_limit_.high = new_limit_.high;
        } else {
            temp_new_limit_.low = _amount.low;
            temp_new_limit_.high = _amount.high;
        }
        let (is_lt_) = uint256_lt(max_borrowed_amount_per_block_, temp_new_limit_);
        with_attr error_message("borrowed per block limit"){
            assert is_lt_ = 0;
        }
        last_block_saved.write(block_number_);
        last_limit_saved.write(temp_new_limit_);
        return(); 
    } 
    return();
}

// @notice: enable_token
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _token Token to enable (felt)
func enable_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrower: felt, _drip: felt, _token: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    IDripManager.checkAndEnableToken(drip_manager_, _drip, _token);
    TokenEnabled.emit(_borrower, _token);
    return();
}

// @notice: disable_token
// @param: _borrower Borrower (felt)
// @param: _drip Drip (felt)
// @param: _token Token to disable (felt)
func disable_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrower: felt, _drip: felt, _token: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (has_changed_) = IDripManager.disableToken(drip_manager_, _drip, _token);
    if(has_changed_ == 1){
        TokenDisabled.emit(_borrower, _token);
        return();
    }
    return();
}


// @notice: revert_if_open_drip_not_allowed
// @dev: Check several conditions to open drip
// @param: _on_belhalf_of On Belhald Of (felt)
func revert_if_open_drip_not_allowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_on_belhalf_of: felt){
    alloc_locals;
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    with_attr error_message("increase debt forbidden") {
        assert is_increase_debt_forbidden_ = 0;
    }
    let (is_expired_) = isExpired();
    with_attr error_message("drip transit expired") {
        assert is_expired_ = 0;
    }

    let (nft_) = nft.read();
    let (is_zero_) = is_equal(0, nft_);

    if(is_zero_ == 0){
        let (caller_) = get_caller_address();
        with_attr error_message("opening drip for other foribdden"){
            assert caller_ = _on_belhalf_of;
        }
        IMorphinePass.burn(nft_, _on_belhalf_of, Uint256(1,0));
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;
    }
    revert_if_action_on_drip_not_allowed(_on_belhalf_of);
    return();
}

// @notice: revert_if_out_borrowed_limits
// @dev: Check Drip respects Borrow Limit
// @param: _borrowed_amount Borrowed Amount (felt)
func revert_if_out_borrowed_limits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrowed_amount: Uint256){
    alloc_locals;
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_allowed_borrowed_amount1_) = uint256_le(minimum_borrowed_amount_, _borrowed_amount);
    let (is_allowed_borrowed_amount2_) = uint256_le(_borrowed_amount, maximum_borrowed_amount_);
    with_attr error_message("borrow amount out of limit") {
        assert_not_zero(is_allowed_borrowed_amount1_ * is_allowed_borrowed_amount2_);
    }
    return();
}

// @notice: add_collateral
// @param: _on_belhalf_of On Belhald Of (felt)
// @param: _drip Drip (felt)
// @param: _token Token in which one will be added collateral (felt)
// @param: _amount Collateral Amount (Uint256)
func add_collateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_on_belhalf_of: felt, _drip: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    revert_if_action_on_drip_not_allowed(_on_belhalf_of);
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    IDripManager.addCollateral(drip_manager_, caller_, _drip, _token, _amount);
    AddCollateral.emit(_on_belhalf_of, _token, _amount);
    return();
}

// @notice: revert_if_action_on_drip_not_allowed
// @param: _on_belhalf_of On Belhald Of (felt)
func revert_if_action_on_drip_not_allowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_on_belhalf_of: felt){
    alloc_locals;
    let (caller_) = get_caller_address();
    if(caller_ == _on_belhalf_of){
        return();
    } else {
        let (is_tranfer_allowed_) = transfers_allowed.read(caller_, _on_belhalf_of);
        with_attr error_message("drip transfer not allowed"){ 
            assert_not_zero(is_tranfer_allowed_);
        }
        return();
    }
}

// @notice: check_if_emergency_liquidator
// @param: _state 1 before liquidation, 0 after (felt)
// @return: state 1 if paused, 0 else (felt)
func check_if_emergency_liquidator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_state: felt) -> (state: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (state_) = IDripManager.checkEmergencyPausable(drip_manager_, caller_, _state);
    return(state_,);
}


// @notice: _from_call_array_to_call
// @dev; Used to parse Call
// @param: call_array_len Call Array Length (felt)
// @param: call_array Call Array (AccountCallArray*)
// @param: calldata Call Data (felt*)
// @param:  calls Call (Call*)
 func _from_call_array_to_call{syscall_ptr: felt*}(
        call_array_len: felt, call_array: AccountCallArray*, calldata: felt*, calls: Call*
    ) {
        // if no more calls
        if (call_array_len == 0) {
            return ();
        }

        // parse the current call
        assert [calls] = Call(
            to=[call_array].to,
            selector=[call_array].selector,
            calldata_len=[call_array].data_len,
            calldata=calldata + [call_array].data_offset
            );
        // parse the remaining calls recursively
        _from_call_array_to_call(
            call_array_len - 1, call_array + AccountCallArray.SIZE, calldata, calls + Call.SIZE
        );
        return ();
    }



// @notice: is_equal
// @param: _a first arg (felt)
// @param: _b second arg (felt)
// @return: state 1 if equal, 0 else (felt)
func is_equal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(a: felt, b: felt) -> (state: felt) {
    if (a == b){
        return(1,);
    } else {
        return(0,);
    }
}