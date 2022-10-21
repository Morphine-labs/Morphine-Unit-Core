%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)

from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_lt, uint256_pow2
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.IERC721 import IERC721
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from openzeppelin.security.safemath.library import SafeUint256


from morphine.utils.safeerc20 import SafeERC20
from morphine.utils.various import DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, PRECISION

from morphine.interfaces.IDripTransit import IDripTransit, Call
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IDripManager import IDripManager
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
func IncreaseBorrowedAmount(borrower: felt, amount: uint256){
}

@event 
func DecreaseBorrowedAmount(oracle: felt, amount: uint256){
}

@event 
func LiquidateCreditAccount(borrower: felt, caller: felt, to: felt, remaining_funds: Uint256){
}

@event 
func TransferDrip(from: felt, to: felt){
}

@event 
func TransferAccountAllowed(from: felt, to: felt, _state: felt){
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
func contract_to_adapter(contract: felt) -> (adapter : felt) {
}

@storage_var
func transfers_allowed(from: felt, to: felt) -> (is_allowed : felt) {
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
    _nft: felt) {
    with_attr error_message("zero address for drip manager"){
        assert_not_zero(_drip_manager);
    }
    let (drip_manager_) = IDripManager.dripManager(_drip_manager);
    let (underlying_)= IDripManager.underlying(_drip_manager);
    drip_manager.write(drip_manager_);
    underlying.write(underlying_);
    nft.write(_nft);
    if (_nft == 0){
        permissionless.write(1);
        return();
    } else{
        permissionless.write(0);
        return();
    }
);

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
    let (permissionless_) = permillion.read();

    if(permissionless_ == 0){
        let (nft_) = nft.read();
        let (nft_balance_) = IERC721.balanceOf(nft_, _on_belhalf_of);
        let (is_le_) = uint256_le(Uint256(0,0),nft_balance_);
        with_attr error_message("Get Your Pass"){
            assert is_le_ = 0;
        }
    }

    let (step1_) = SafeUint256.mul(_amount, _leverage_factor);
    let (borrowed_amount_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
    let (liquidation_threshold_) = IDripManager.liquidationThresholds(drip_manager_, underlying_);
    let (amount_ltu_) = SafeUint256.mul(_amount, liquidation_threshold_);
    let (less_ltu_) = SafeUint256.sub_lt(Uint256(PRECISION,0), liquidation_threshold_);
    let (borrow_less_ltu_) = SafeUint256.mul(borrowed_amount_, liquidation_threshold_);
    let (is_lt_) = uint256_lt(borrow_less_ltu_, amount_ltu_);
    with_attr error_message("incorrect amount"){
        assert is_lt_ = 1;
    }

    let (drip_) = IDripManager.openDrip(drip_manager_, borrowed_amount_, _on_belhalf_of);
    IDripManager.addCollateral(drip_manager_, caller_, _on_belhalf_of, underlying_, _amount);
    OpenDrip.emit(_on_belhalf_of, drip_, borrowed_amount_);
    ReentrancyGuard._end();
    return();
}

@external
func openDripMultiCall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _borrowed_amount: Uint256,
        _on_belhalf_of: felt,
        _call_len: felt,
        _call: Call*){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (permissionless_) = permillion.read();

    if(permissionless_ == 0){
        let (nft_) = nft.read();
        let (nft_balance_) = IERC721.balanceOf(nft_, _on_belhalf_of);
        let (is_le_) = uint256_le(Uint256(0,0),nft_balance_);
        with_attr error_message("Get Your Pass"){
            assert is_le_ = 0;
        }
    }

    let (drip_) = IDripManager.openDrip(drip_manager_, borrowed_amount_, _on_belhalf_of);
    OpenDrip.emit(_on_belhalf_of, drip_, borrowed_amount_);
    
    let (is_le_) = is_le(_call_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_len, _call, _on_belhalf_of, 0, 1, this_, drip_manager_);
    }
    IDripManager.fullCollateralCheck(drip_);
    ReentrancyGuard._end();
    return();
}

@external
func closeDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _to: felt,
        _call_len: felt,
        _call: Call*){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (is_le_) = is_le(_call_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_len, _call, caller_, 1, 0, this_, drip_manager_);
    }
    IDripManager.closeDrip(drip_manager_, caller_, borrowed_amount_, _on_belhalf_of);
    CloseDrip.emit(caller_, _to);
    ReentrancyGuard._end();
    return();
}

@external
func liquidateDrip{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _borrower: felt,
        _to: felt,
        _call_len: felt,
        _call: Call*){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getCreditAccountOrRevert(drip_manager_, _borrower);
    let (is_liquidatable_, total_value_) = is_drip_liquidatable(drip_);
    with_attr error_message("Can't Liquidate with such HF"){
        assert is_liquidatable_ = 1;
    }
    let (is_le_) = is_le(_call_len , 0);
    if(is_le_ == 0){
        let (this_) = get_contract_address();
        _multicall(_call_len, _call, _borrower, 1, 0, this_, drip_manager_);
    }
    let (remaining_funds_) = IDripManager.closeCreditAccount(drip_manager_, _borrower, 1, total_value_, caller_, _to);
    LiquidateCreditAccount.emit(_borrower, caller_, _to, remaining_funds_);
    ReentrancyGuard._end();
    return();
}



@external
func increaseDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
    with_attr error_message("increase debt forbidden for now"){
        assert is_increase_debt_forbidden_ = 0;
    }
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getCreditAccountOrRevert(drip_manager_, caller_);
    IDripManager.manageDebt(drip_manager_, caller_, _amount, 1);
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    IncreaseBorrowedAmount.emit(caller_, _amount);
    ReentrancyGuard._end();
    return();
}

@external
func decreaseDebt{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    let (drip_) = IDripManager.getCreditAccountOrRevert(drip_manager_, caller_);
    IDripManager.manageDebt(drip_manager_, caller_, _amount, 0);
    IDripManager.fullCollateralCheck(drip_manager_, drip_);
    DecreaseBorrowedAmount.emit(caller_, _amount);
    ReentrancyGuard._end();
    return();
}

@external
func addCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_on_belhalf_of: felt, _token: felt, _amount: Uint256){
    alloc_locals;
    ReentrancyGuard._start();
    let (drip_manager_) = drip_manager.read();
    let (caller_) = get_caller_address();
    IDripManager.addCollateral(drip_manager_, caller_, _on_belhalf_of, _token, _amount);
    AddCollateral.emit(_on_belhalf_of, _token, _amount);
    ReentrancyGuard._end();
    return();
}

@external
func multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_call_len: felt,_call: Call*){
    alloc_locals;
    ReentrancyGuard._start();
    let (is_le_) = is_le(_call_len , 0);
    if(is_le_ == 0){
        let (caller_) = get_caller_address();
        let (drip_manager_) = drip_manager.read();
        let (drip_) = IDripManager.getCreditAccountOrRevert(drip_manager_, caller_);
        let (this_) = get_contract_address();
        _multicall(_call_len, _call, _borrower, 1, 0, this_, drip_manager_);
        IDripManager.fullCollateralCheck(drip_manager_, drip_);
    }
    ReentrancyGuard._end();
    return();
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_target: felt, _token: felt, _amount: Uint256){
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
    IDripManager.approveCreditAccount(drip_manager_, caller_, _target, _token, _amount);
    ReentrancyGuard._end();
    return();
}

@external
func transferAccountOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_to: felt){
    alloc_locals;
    let (caller_) = get_caller_address();
    let (is_allowed_) = transfers_allowed(caller_, _to);
    with_attr error_message("transfer not allowed"){
        assert_not_zero(is_allowed_);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.getCreditAccountOrRevert(drip_manager_, caller_);
    let (is_liquidatable_,_) = is_drip_liquidatable(drip_);
    with_attr error_message("Transfer not allowed for liquiditable drip"){
        assert is_liquidatable_ = 0;
    }
    IDripManager.transferAccountOwnership(drip_manager_, caller_, _to);
    TransferDrip.emit(caller_, _to);
    return();
}

@external
func approveAccountTransfers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_from: felt, _state: felt){
    alloc_locals;
    let (caller_) = get_caller_address();
    transfers_allowed.write(_from, caller_, _state);
    TransferAccountAllowed.emit(_from, caller_, _state);
    return();
}

@external
func setContractToAdapter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt, _adapter: felt){
    alloc_locals;
    assert_only_drip_configurator();
    with_attr error_message("zero address"){
        assert_not_zero(_contract);
    }
    contract_to_adapter.write()_contract, _adapter;
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

// Getters

@view
func contractToAdapter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt) -> (state: felt){
    alloc_locals;
    let (adapter_) = contract_to_adapter.read(_contract);
    return(adapter_,);
}


@view
func isTokenAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) -> (state: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMasksMap(_token);
    let (forbid_token_mask_) = IDripManager.tokenMasksMap(_token);
    let (low_) = bitwise_and(fordbiden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(fordbiden_token_mask_.high, token_mask_.high);
    let (is_nul_) = uint256_eq(Uint256(0,0),Uint(low_, high_));
    let (is_bg_)= uint256_lt(Uint(0,0), forbid_token_mask_)
    if(is_nul_ * is_bg_ == 1){
        return(1,);
    } else {
        return(0,);
    }
}

@view
func calcTotalValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (total: Uint256, twv: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (oracle_transit_) = IDripManager.priceOracle(drip_manager_);
    let (enabled_tokens_) = IDripManager.enabledTokensMap(drip_manager_, _drip);
    let (count_) = IDripManager.allowedTokensCount(drip_manager_);
    let (total_USD_: Uint256, twv_USD_precision_: Uint256) = recursive_calcul_value(0, count_, _drip, enabled_tokens_, oracle_transit_, drip_manager_, Uint256(0,0), Uint256(0,0));
    let (underlying_) = underlying.read();
    let (total_) = IOracleTransit.convertFromUSD(total_USD_, underlying_);
    let (twv_precision_) = IOracleTransit.convertFromUSD(twv_USD_precision_, underlying_);
    let (twv_,_) = SafeUint256.div_rem(twv_precision_, Uint256(PRECISION,0));
    return(total_, twv_,)
}

@view
func calcDripHealthFactor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip: felt) -> (health_factor: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (_, tvw_) = calcTotalValue(_drip);
    let (_, borrowed_amount_with_interests_) = IDripManager.calcCreditAccountAccruedInterest(drip_manager_, _drip);
    let (step1_) = SafeUint256.mul(tvw_, Uint256(PRECISION,0));
    let (hf_,_) = SafeUint256.div_rem(step1_, borrowed_amount_with_interests_);
    return(hf_,)
}

@view
func hasOpenedCreditAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_borrower: felt) -> (hasOpened: felt){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (drip_) = IDripManager.creditAccounts(_borrower);
    if(drip_ == 0){
        return(0,);
    } else {
        return(1,);
    }
}



// Internals

func _multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _call_len: felt,
        _call: Call*
        _borrower: felt,
        _is_closure: felt,
        _is_increase_debt_was_called: felt){
    let (this_) = get_contract_address();
    let (drip_manager_) = drip_manager.read();
    IDripManager.transferDripOwnership(drip_manager_, _borrower, this_);
    MultiCallStarted.emit(_borrower);
    recursive_multicall(_call_len, _call, _borrower, _is_closure, _is_increase_debt_was_called, this_, drip_manager_);
    MultiCallFinished.emit();
    IDripManager.transferDripOwnership(drip_manager_, this_, _borrower);
    return();
}

func recursive_multicall{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _call_len: felt,
        _call: Call*,
        _borrower: felt,
        _is_closure: felt,
        _is_increase_debt_was_called: felt
        _this: felt,
        _drip_manager: felt){
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
            tempvar on_belhalf_of_: felt;
            if(_call[0].calldata[0] == _borrower){
                on_belhalf_of_ = _this;
            } else{
                on_belhalf_of_ = _call[0].calldata[0];
            }
            IDripManager.addCollateral(_drip_manager, caller_, on_belhalf_of_, _call[0].calldata[1], Uint256(_call[0].calldata[3],_call[0].calldata[3]));
            AddCollateral.emit(_call[0].calldata[0], _call[0].calldata[1], Uint256(_call[0].calldata[3],_call[0].calldata[3]));
            return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _is_closure, _is_increase_debt_was_called, _this, _drip_manager);
        } else{
            if(_call[0].selector == INCREASE_DEBT_SELECTOR){
                let (is_increase_debt_forbidden_) = is_increase_debt_forbidden.read();
                with_attr error_message("increase debt forbidden for now"){
                    assert is_increase_debt_forbidden_ = 0;
                }
                with_attr error_message("incorrect datalen"){
                    assert _call[0].calldata_len = 2;
                }
                IDripManager.manageDebt(_drip_manager, _this, Uint256(_call[0].calldata[0], _call[0].calldata[1]), 1);
                IncreaseBorrowedAmount.emit(_borrower, Uint256(_call[0].calldata[0], _call[0].calldata[1]));
                return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _is_closure, 1, _this, _drip_manager);
            } else {
                if(_call[0].selector == DECREASE_DEBT_SELECTOR){
                    with_attr error_message("can't decrease and increase debt in same multicall, stop trying to hack this protocol"){
                        assert _is_increase_debt_was_called = 0;
                    }
                    with_attr error_message("incorrect datalen"){
                        assert _call[0].calldata_len = 2;
                    }
                    IDripManager.manageDebt(_drip_manager, _this, Uint256(_call[0].calldata[0], _call[0].calldata[1]), 0);
                    DecreaseBorrowedAmount.emit(_borrower, Uint256(_call[0].calldata[0], _call[0].calldata[1]));
                    return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _is_closure, 0, _this, _drip_manager);
                } else{
                    with_attr error_message("Unknow method"){
                        assert 1 = 0;
                    }
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
        return recursive_multicall(_call_len - 1, _call + 3 + _call[0].calldata_len, _borrower, _is_closure, _is_increase_debt_was_called, _this, _drip_manager);
    }
}


func recursive_calcul_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _index: felt,
        _count: felt,
        _drip: felt,
        _enabled_tokens: Uint256,
        _oracle_transit: felt,
        _drip_manager: felt,
        _cumulative_total_usd: Uint256,
        _cumulative_twv_usd: Uint256){
    if(_index == _count){
        return(_cumulative_total_usd, _cumulative_twv_usd);
    }
    let (token_mask_) = uint256_pow2(Uint256(_index,0));
    let (low_) = bitwise_and(_enabled_tokens.low, token_mask_.low);
    let (high_) = bitwise_and(_enabled_tokens.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0,0), Uint256(low_, high_));
    tempvar cumulative_total_usd_temp_: Uint256;
    tempvar cumulative_twv_usd_temp_: Uint256;
    if(is_bt_ == 1){
        let (token_) = IDripManager.allowedTokens(_drip_manager, _count);
        let (balance_) = IERC20.balanceOf(token_, _drip);
        let (has_token_) = uint256_lt(Uint256(1,0), balance_);
        if(has_token_ == 1){
            let (value_) = IOracleTransit.convertToUSD(_oracle_transit, balance_, token_);
            let (new_cumulative_total_usd_) = SafeUint256.add(_cumulative_total_usd, value_);
            let (lt_) = IDripManager.liquidationThresholds(_drip_manager, token_);
            let (lt_value_) = SafeUint256.mul(value_, lt_);
            let (new_cumulative_twv_usd_) = SafeUint256.add(_cumulative_twv_usd, lt_value_);
            cumulative_total_usd_temp_.low = new_cumulative_total_usd_.low;
            cumulative_total_usd_temp_.high = new_cumulative_total_usd_.high;
            cumulative_twv_usd_temp_.low = new_cumulative_twv_usd_.low;
            cumulative_twv_usd_temp_.high = new_cumulative_twv_usd_.high;
        } else {
            cumulative_total_usd_temp_.low = _cumulative_total_usd.low;
            cumulative_total_usd_temp_.high = _cumulative_total_usd.high;
            cumulative_twv_usd_temp_.low = _cumulative_twv_usd.low;
            cumulative_twv_usd_temp_.high = _cumulative_twv_usd.high;
        }
    } else {
        cumulative_total_usd_temp_.low = _cumulative_total_usd.low;
        cumulative_total_usd_temp_.high = _cumulative_total_usd.high;
        cumulative_twv_usd_temp_.low = _cumulative_twv_usd.low;
        cumulative_twv_usd_temp_.high = _cumulative_twv_usd.high;
    }
    return recursive_calcul_value(
        _index + 1,
        _count,
        _drip,
        _enabled_tokens,
        _oracle_transit,
        _drip_manager,
        cumulative_total_usd_temp_,
        cumulative_twv_usd_temp_);
}