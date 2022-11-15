%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
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
from morphine.utils.various import DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, PRECISION

from morphine.interfaces.IDripTransit import IDripTransit, Call, AccountCallArray
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IDripConfigurator import IDripConfigurator
from morphine.interfaces.IOracleTransit import IOracleTransit


// Events

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
func DecreaseBorrowedAmount(oracle: felt, amount: Uint256){
}

@event 
func LiquidateDrip(borrower: felt, caller: felt, to: felt, remaining_funds: Uint256){
}

@event 
func TransferDrip(_from : felt, to: felt){
}

@event 
func TransferDripAllowed(_from: felt, to: felt, _state: felt){
}


// Storage

const ADD_COLLATERAL_SELECTOR = 222;
const INCREASE_DEBT_SELECTOR = 222;
const DECREASE_DEBT_SELECTOR = 222;


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
func permissionless() -> (address: felt) {
}

@storage_var
func nft() -> (address: felt) {
}

// Protectors


func assert_only_drip_configurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (caller_) = get_caller_address();
        let (drip_manager_) = drip_manager.read();
        let (drip_configurator_) = IDripManager.dripConfigurator(drip_manager_);
        with_attr error_message("caller is not drip configurator") {
            assert caller_ = drip_configurator_;
        }
        return ();
    }



//Constructor
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
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
    if (_nft == 0){
        permissionless.write(1);
        return();
    } else{
        permissionless.write(0);
        return();
    }
}

// TOKEN MANAGEMENT

@external
func openDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _amount: Uint256,
        _on_belhalf_of: felt,
        _leverage_factor: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (caller_) = get_caller_address();
    let (drip_manager_) = drip_manager.read();
    let (underlying_) = underlying.read();
    let (permissionless_) = permissionless.read();

    if(permissionless_ == 0){
        let (nft_) = nft.read();
        let (nft_balance_) = IERC721.balanceOf(nft_, _on_belhalf_of);
        let (is_le_) = uint256_le(Uint256(0,0),nft_balance_);
        with_attr error_message("Get Your Pass"){
            assert is_le_ = 0;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (step1_) = SafeUint256.mul(_amount, _leverage_factor);
    let (borrowed_amount_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
    let (liquidation_threshold_) = IDripManager.liquidationThreshold(drip_manager_, underlying_);
    let (amount_ltu_) = SafeUint256.mul(_amount, liquidation_threshold_);
    let (less_ltu_) = SafeUint256.sub_lt(Uint256(PRECISION,0), liquidation_threshold_);
    let (borrow_less_ltu_) = SafeUint256.mul(borrowed_amount_, liquidation_threshold_);
    let (is_lt_) = uint256_lt(borrow_less_ltu_, amount_ltu_);
    with_attr error_message("incorrect amount"){
        assert is_lt_ = 1;
    }

    let (drip_) = IDripManager.openDrip(drip_manager_, borrowed_amount_, _on_belhalf_of);
    OpenDrip.emit(_on_belhalf_of, drip_, borrowed_amount_);
    add_collateral(_on_belhalf_of, drip_, underlying_, _amount);
    ReentrancyGuard._end();
    return();
}

@external
func openDripMultiCall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _borrowed_amount: Uint256,
        _on_belhalf_of: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (permissionless_) = permissionless.read();

    if(permissionless_ == 0){
        let (nft_) = nft.read();
        let (nft_balance_) = IERC721.balanceOf(nft_, _on_belhalf_of);
        let (is_le_) = uint256_le(Uint256(0,0),nft_balance_);
        with_attr error_message("Get Your Pass"){
            assert is_le_ = 0;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (drip_) = IDripManager.openDrip(drip_manager_, _borrowed_amount, _on_belhalf_of);
    OpenDrip.emit(_on_belhalf_of, drip_, _borrowed_amount);
    
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, _on_belhalf_of, 0, 1);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    ReentrancyGuard._end();
    return();
}

@external
func closeDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _to: felt,
        _on_belhalf_of: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, caller_, 1, 0);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    IDripManager.closeDrip(drip_manager_, caller_, 0,  Uint256(0,0),caller_, _on_belhalf_of);
    CloseDrip.emit(caller_, _to);
    ReentrancyGuard._end();
    return();
}

@external
func liquidateDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(
        _borrower: felt,
        _to: felt,
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, _borrower);
    let (is_liquidatable_, total_value_) = is_drip_liquidatable(drip_);
    with_attr error_message("Can't Liquidate with such HF"){
        assert is_liquidatable_ = 1;
    }
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, _borrower, 1, 0);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    let (remaining_funds_) = IDripManager.closeDrip(drip_manager_, _borrower, 1, total_value_, caller_, _to);
    LiquidateDrip.emit(_borrower, caller_, _to, remaining_funds_);
    ReentrancyGuard._end();
    return();
}


@external
func increaseDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    increase_debt(caller_, drip_, _amount);
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    ReentrancyGuard._end();
    return();
}

@external
func decreaseDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    decrease_debt(caller_, drip_, _amount);
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    ReentrancyGuard._end();
    return();
}

@external
func addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_on_belhalf_of: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, _on_belhalf_of);
    add_collateral(_on_belhalf_of, drip_, _token, _amount);
    ReentrancyGuard._end();
    return();
}


@external
func multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _borrower : felt, 
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _calldata_len: felt,
        _calldata: felt*){
    alloc_locals;
    ReentrancyGuard._start();
    let is_le_ = is_le(_call_array_len , 0);
    if(is_le_ == 0){
        let (caller_) = get_caller_address();
        let (drip_manager_) = drip_manager.read();
        let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
        let (this_) = get_contract_address();
        _multicall(_call_array_len, _call_array, _calldata, _borrower, 0, 0);
        IDripManager.fullCollateralCheck(drip_manager_, drip_);
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    ReentrancyGuard._end();
    return();
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_target: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (adapter_) = contract_to_adapter.read(_target);
    with_attr error_message("Target is not adapter"){
        assert_not_zero(adapter_);
    }
    let (is_token_allowed_) = isTokenAllowed(_token);
    with_attr error_message("Token not allowed"){
        assert_not_zero(is_token_allowed_);
    }
    IDripManager.approveDrip(drip_manager_, caller_, _target, _token, _amount);
    ReentrancyGuard._end();
    return();
}

@external
func transferDripOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_to: felt){
    alloc_locals;
    let (caller_) = get_caller_address();
    let (is_allowed_) = transfers_allowed.read(caller_, _to);
    with_attr error_message("transfer not allowed"){
        assert_not_zero(is_allowed_);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, caller_);
    let (is_liquidatable_,_) = is_drip_liquidatable(drip_);
    with_attr error_message("Transfer not allowed for liquiditable drip"){
        assert is_liquidatable_ = 0;
    }
    IDripManager.transferDripOwnership(drip_manager_, caller_, _to);
    TransferDrip.emit(caller_, _to);
    return();
}

@external
func approveDripTransfers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_from: felt, _state: felt){
    alloc_locals;
    let (caller_) = get_caller_address();
    transfers_allowed.write(_from, caller_, _state);
    TransferDripAllowed.emit(_from, caller_, _state);
    return();
}

@external
func setContractToAdapter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt, _adapter: felt){
    alloc_locals;
    assert_only_drip_configurator();
    with_attr error_message("zero address"){
        assert_not_zero(_contract);
    }
    contract_to_adapter.write(_contract, _adapter);
    return();
}

@external
func setIncreaseDebtForbidden{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_state: felt){
    alloc_locals;
    assert_only_drip_configurator();
    is_increase_debt_forbidden.write(_state);
    return();
}

@external
func setPermisionless{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_state: felt){
    alloc_locals;
    assert_only_drip_configurator();
    permissionless.write(_state);
    return();
}

@external
func setMaxBorrowedAmountPerBlock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_max_borrowed_amount_per_block: Uint256){
    alloc_locals;
    assert_only_drip_configurator();
    max_borrowed_amount_per_block.write(_max_borrowed_amount_per_block);
    return();
}

@external
func setDripLimits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    alloc_locals;
    assert_only_drip_configurator();
    minimum_borrowed_amount.write(_minimum_borrowed_amount);
    maximum_borrowed_amount.write(_maximum_borrowed_amount);
    return();
}

@external
func setExpirationDate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_expiration_date: felt){
    alloc_locals;
    assert_only_drip_configurator();
    expiration_date.write(_expiration_date);
    return();
}




// Getters

@view
func dripManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (dripManager: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    return(drip_manager_,);
}

@view
func isExpired{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (state: felt){
    alloc_locals;
    let (is_expirable_) = is_expirable.read();
    let (block_timestamp_) = get_block_timestamp();
    let (expiration_date_) = expiration_date.read();
    let (is_expired_) = uint256_le(Uint256(expiration_date_,0), Uint256(block_timestamp_, 0));
    if(is_expirable_ * is_expired_ == 0){
        return(0,)
    } else {
        return(1,)
    }
}

@view
func isTokenAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_token: felt) -> (state: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMask(drip_manager_, _token);
    let (forbiden_token_mask_) = IDripManager.forbidenTokenMask(drip_manager_);
    let (low_) = bitwise_and(forbiden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(forbiden_token_mask_.high, token_mask_.high);
    let (is_nul_) = uint256_eq(Uint256(0,0),Uint256(low_, high_));
    let (is_bg_)= uint256_lt(Uint256(0,0), forbiden_token_mask_);
    if(is_nul_ * is_bg_ == 1){
        return(1,);
    } else {
        return(0,);
    }
}

@view
func calcTotalValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr : BitwiseBuiltin*}(_drip: felt) -> (total: Uint256, twv: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (oracle_transit_) = IDripManager.oracleTransit(drip_manager_);
    let (enabled_tokens_) = IDripManager.enabledTokensMap(drip_manager_, _drip);
    let (allowed_contract_length_) = IDripManager.allowedTokensLength(drip_manager_);
    let (total_USD_: Uint256, twv_USD_precision_: Uint256) = recursive_calcul_value(0, allowed_contract_length_, _drip, enabled_tokens_, oracle_transit_, drip_manager_, Uint256(0,0), Uint256(0,0));
    let (underlying_) = underlying.read();
    let (total_) = IOracleTransit.convertFromUSD(oracle_transit_, total_USD_, underlying_);
    let (twv_precision_) = IOracleTransit.convertFromUSD(oracle_transit_, twv_USD_precision_, underlying_);
    let (twv_,_) = SafeUint256.div_rem(twv_precision_, Uint256(PRECISION,0));
    return(total_, twv_,);
}

@view
func calcDripHealthFactor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr : BitwiseBuiltin*}(_drip: felt) -> (health_factor: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (_, tvw_) = calcTotalValue(_drip);
    let (_, borrowed_amount_with_interests_) = IDripManager.calcDripAccruedInterest(drip_manager_, _drip);
    let (step1_) = SafeUint256.mul(tvw_, Uint256(PRECISION,0));
    let (hf_,_) = SafeUint256.div_rem(step1_, borrowed_amount_with_interests_);
    return(hf_,);
}

@view
func hasOpenedDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_borrower: felt) -> (hasOpened: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getDrip(drip_manager_, _borrower);
    if(drip_ == 0){
        return(0,);
    } else {
        return(1,);
    }
}

@view
func maxBorrowedAmountPerBlock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (max_borrowed_amount_per_block_: Uint256){
    alloc_locals;
    let (max_borrowed_amount_per_block_) = max_borrowed_amount_per_block.read();
    return(max_borrowed_amount_per_block_,);
}

@view
func isIncreaseDebtForbidden{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (is_increase_debt_forbidden: felt){
    alloc_locals;
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    return(is_increase_debt_forbidden_,);
}

@view
func expirationDate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (expiration_date: felt){
    alloc_locals;
    let (expiration_date_) = expiration_date.read();
    return(expiration_date_,);
}

@view
func isExpirable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (expirable: felt){
    alloc_locals;
    let (is_expirable) = expirable.read();
    return(is_expirable,);
}

@view
func limits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256){
    alloc_locals;
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_expirable) = expirable.read();
    return(minimum_borrowed_amount_, maximum_borrowed_amount_,);
}


// Internals

func _multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _call_array_len: felt,
        _call_array: AccountCallArray*,
        _call_data: felt*,
        _borrower: felt,
        _is_closure: felt,
        _is_increase_debt_was_called: felt){
    alloc_locals;
    let (this_) = get_contract_address();
    let (drip_manager_) = drip_manager.read();

     // TMP: Convert `AccountCallArray` to 'Call'.
     let (calls: Call*) = alloc();
     _from_call_array_to_call(_call_array_len, _call_array, _call_data, calls);

    IDripManager.transferDripOwnership(drip_manager_, _borrower, this_);
    MultiCallStarted.emit(_borrower);
    let (drip_) = IDripManager.getDripOrRevert(drip_manager_, _borrower);
    recursive_multicall(_call_array_len, calls, _borrower, drip_,_is_closure, _is_increase_debt_was_called, this_, drip_manager_);
    MultiCallFinished.emit();
    IDripManager.transferDripOwnership(drip_manager_, this_, _borrower);
    return();
}

func recursive_multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _call_len: felt,
        _call: Call*,
        _borrower: felt,
        _drip: felt,
        _is_closure: felt,
        _is_increase_debt_was_called: felt,
        _this: felt,
        _drip_manager: felt){
    alloc_locals;
    if(_call_len == 0){
        return();
    }
    if(_call[0].to == _this){
        with_attr error_message("no call allowed on this contract while closure"){
            assert _is_closure = 0;
        }
        if(_call[0].selector == ADD_COLLATERAL_SELECTOR){
            let (caller_) = get_caller_address();
            with_attr error_message("incorrect datalen"){
                assert _call[0].calldata_len = 4;
            }
            tempvar temp_drip: felt;
            if(_call[0].calldata[0] == _borrower){
                temp_drip = _drip;
            } else{
                let (drip_from_on_belhalf_of_) = IDripManager.getDripOrRevert(_call[0].calldata[0]);
                temp_drip = drip_from_on_belhalf_of_;
            }
            add_collateral(_call[0].calldata[0], temp_drip,_call[0].calldata[1], Uint256(_call[0].calldata[2],_call[0].calldata[3]));
            return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _drip,_is_closure, _is_increase_debt_was_called, _this, _drip_manager);
        } else{
            if(_call[0].selector == INCREASE_DEBT_SELECTOR){
                with_attr error_message("incorrect datalen"){
                    assert _call[0].calldata_len = 2;
                }
                increase_debt(_borrower, _drip, Uint256(_call[0].calldata[0], _call[0].calldata[1]));
                return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _drip, _is_closure, 1, _this, _drip_manager);
            } else {
                if(_call[0].selector == DECREASE_DEBT_SELECTOR){
                    with_attr error_message("can not decrease and increase debt in multicalll"){
                        assert _is_increase_debt_was_called = 0;
                    }
                    with_attr error_message("incorrect datalen"){
                        assert _call[0].calldata_len = 2;
                    }
                    decrease_debt(_borrower, _drip, Uint256(_call[0].calldata[0], _call[0].calldata[1]));
                    return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _drip,_is_closure, 0, _this, _drip_manager);
                } else{
                    with_attr error_message("Unknow method"){
                        assert 1 = 0;
                    }
                    return();
                }
            }
        } 
    } else {
        with_attr error_message("forbiden call to credit manager, stop trying to hack this protocol"){
            assert_not_zero(_call[0].to - _drip_manager);
        }
        let (contract_) = IDripManager.adapterToContract(_drip_manager, _call[0].to);
        with_attr error_message("Target is not adapter"){
            assert_not_zero(contract_);
        }
        let (retdata_len: felt, retdata: felt*) = call_contract(_call[0].to, _call[0].selector, _call[0].calldata_len, _call[0].calldata);
        return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _drip, _is_closure, _is_increase_debt_was_called, _this, _drip_manager);
    }
}


func recursive_calcul_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr,  bitwise_ptr: BitwiseBuiltin*}(
        _index: felt,
        _count: felt,
        _drip: felt,
        _enabled_tokens: Uint256,
        _oracle_transit: felt,
        _drip_manager: felt,
        _cumulative_total_usd: Uint256,
        _cumulative_twv_usd: Uint256) -> (total_usd: Uint256, twv: Uint256){
    alloc_locals;
    if(_index == _count){
        return(_cumulative_total_usd, _cumulative_twv_usd);
    }
    let (token_mask_) = uint256_pow2(Uint256(_index,0));
    let (low_) = bitwise_and(_enabled_tokens.low, token_mask_.low);
    let (high_) = bitwise_and(_enabled_tokens.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0,0), Uint256(low_, high_));
    if(is_bt_ == 1){
        let (token_) = IDripManager.allowedToken(_drip_manager, _count);
        let (balance_) = IERC20.balanceOf(token_, _drip);
        let (has_token_) = uint256_lt(Uint256(1,0), balance_);
        if(has_token_ == 1){
            let (value_) = IOracleTransit.convertToUSD(_oracle_transit, balance_, token_);
            let (new_cumulative_total_usd_) = SafeUint256.add(_cumulative_total_usd, value_);
            let (lt_) = IDripManager.liquidationThreshold(_drip_manager, token_);
            let (lt_value_) = SafeUint256.mul(value_, lt_);
            let (new_cumulative_twv_usd_) = SafeUint256.add(_cumulative_twv_usd, lt_value_);
            return recursive_calcul_value(
                _index + 1,
                _count,
                _drip,
                _enabled_tokens,
                _oracle_transit,
                _drip_manager,
                new_cumulative_total_usd_,
                new_cumulative_twv_usd_);
        } else {
            return recursive_calcul_value(
                _index + 1,
                _count,
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
            _count,
            _drip,
            _enabled_tokens,
            _oracle_transit,
            _drip_manager,
            _cumulative_total_usd,
            _cumulative_twv_usd);
    }
}

func is_drip_liquidatable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_drip: felt) -> (is_liquidatable: felt, total_value: Uint256){
    let (total_value_, tvw_) = calcTotalValue(_drip);
    let (drip_manager_) = drip_manager.read();
    let (_, borrowed_amount_accrued_interest_) = IDripManager.calcDripAccruedInterest(drip_manager_ , _drip);
    let (is_lt_) = uint256_lt(tvw_, borrowed_amount_accrued_interest_);
    if (is_lt_ == 1) {
        return(1, total_value_);
    } else {
        return(0, total_value_); 
    }
}

func increase_debt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrower: felt, _drip: felt, _amount: Uint256){
    alloc_locals;
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    with_attr error_message("increase debt forbidden"){
        assert is_increase_debt_forbidden_ = 0;
    }
    check_and_update_borrowed_block_limit(_amount);
    check_forbidden_tokens(_drip);
    let (new_borrowed_amount_) = IDripManager.manageDebt(drip_manager_, drip_, _amount, 1);
    revert_if_out_borrowed_limits(new_borrowed_amount_);
    IncreaseBorrowedAmount.emit(caller_, _amount);
    return();
}

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

func decrease_debt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrower: felt, _drip: felt, _amount: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (new_borrowed_amount_) = IDripManager.manageDebt(drip_manager_, drip_, _amount, 0);
    revert_if_out_borrowed_limits(new_borrowed_amount_);
    DecreaseBorrowedAmount.emit(caller_, _amount);
    return();
}

func check_and_update_borrowed_block_limit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_amount: Uint256){
    alloc_locals;
    let (permissionless_) = permissionless.read();
    if(permissionless_ == 1){
        let (max_borrowed_amount_per_block_) = max_borrowed_amount_per_block.read();
        let (last_block_) = last_block_saved.read();
        let (last_limit_) = last_limit_saved.read();
        let (block_number_) = get_block_number();
        tempvar temp_new_limit_: Uint256;
        if(block_number_ == last_block_){
            let (new_limit_) = SafeUint256.add(_amount, last_limit_);
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

func revert_if_open_drip_not_allowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_on_belhalf_of: felt){
    alloc_locals;
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    with_attr error_message("increase debt forbidden") {
        assert_not_zero(is_increase_debt_forbidden_);
    }
    let (is_expired_) = isExpired();
    with_attr error_message("Drip Transit Expired") {
        assert_not_zero(is_increase_debt_forbidden_);
    }


    if(permissionless_ == 0){
        
        let (nft_) = nft.read();
        let (nft_balance_) = IERC721.balanceOf(nft_, _on_belhalf_of);
        let (is_le_) = uint256_le(Uint256(0,0),nft_balance_);
        with_attr error_message("Get Your Pass"){
            assert is_le_ = 0;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (is_expirable_) = 
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_allowed_borrowed_amount1_) = uint256_lt(minimum_borrowed_amount_, _borrowed_amount);
    let (is_allowed_borrowed_amount2_) = uint256_lt(_borrowed_amount, maximum_borrowed_amount_);
    with_attr error_message("borrow amount out of limit") {
        assert_not_zero(is_allowed_borrowed_amount1_ * is_allowed_borrowed_amount2_);
    }
    return();
}


func revert_if_out_borrowed_limits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(_borrowed_amount: Uint256){
    alloc_locals;
    let (minimum_borrowed_amount_) = minimum_borrowed_amount.read();
    let (maximum_borrowed_amount_) = maximum_borrowed_amount.read();
    let (is_allowed_borrowed_amount1_) = uint256_lt(minimum_borrowed_amount_, _borrowed_amount);
    let (is_allowed_borrowed_amount2_) = uint256_lt(_borrowed_amount, maximum_borrowed_amount_);
    with_attr error_message("borrow amount out of limit") {
        assert_not_zero(is_allowed_borrowed_amount1_ * is_allowed_borrowed_amount2_);
    }
    return();
}


func add_collateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_on_belhalf_of: felt, _drip: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    revert_if_action_on_drip_not_allowed(_on_belhalf_of);
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    IDripManager.addCollateral(drip_manager_, caller_, drip_, _token, _amount);
    AddCollateral.emit(_on_belhalf_of, _token, _amount);
    return();
}

func revert_if_action_on_drip_not_allowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_on_belhalf_of: felt){
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

