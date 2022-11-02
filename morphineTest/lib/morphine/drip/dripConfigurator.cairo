%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)

from starkware.cairo.common.uint256 import ALL_ONES, Uint256, uint256_eq, uint256_lt, uint256_le
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.security.safemath.library import SafeUint256

from morphine.utils.safeerc20 import SafeERC20
from morphine.utils.various import DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, PRECISION, DEFAULT_FEE_LIQUIDATION

from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDripManager import IDripManager
from morphine.interfaces.IDripTransit import IDripTransit
from morphine.interfaces.IDripConfigurator import IDripConfigurator, AllowedToken
from morphine.interfaces.IAdapter import IAdapter
from morphine.interfaces.IPool import IPool
from morphine.interfaces.IOracleTransit import IOracleTransit




// Events

@event 
func TokenAllowed(token: felt){
}

@event 
func TokenForbidden(token: felt){
}

@event 
func ContractAllowed(contract: felt){
}

@event 
func ContractForbidden(contract: felt){
}

@event 
func LimitsUpdated(minimum_borrowed_amount: Uint256, maximum_borrowed_amount: Uint256){
}

@event 
func FastCheckParametersUpdated(chi_threshold: Uint256, hf_check_interval: Uint256){
}

@event 
func FeesUpdated(fee_interest: Uint256, fee_liquidation: Uint256, liquidation_premium: Uint256){
}

@event 
func OracleTransitUpgraded(oracle: felt){
}

@event 
func DripTransitUpgraded(drip_transit: felt){
}

@event 
func TokenLiquidationThresholdUpdated(token: felt, liquidation_threshold: Uint256){
}



// Storage

@storage_var
func drip_manager() -> (address : felt) {
}

@storage_var
func drip_transit() -> (address : felt) {
}

@storage_var
func pool_factory() -> (address: felt) {
}

@storage_var
func liquidation_threshold(token_address : felt) -> (res: felt) {
}

@storage_var
func id_to_allowed_contract(id : felt) -> (contract: felt) {
}

@storage_var
func allowed_contract_to_id(contract : felt) -> (id: felt) {
}

@storage_var
func allowed_contract_length() -> (length: felt) {
}

@storage_var
func is_allowed_contract(contract: felt) -> (is_allowed_contract : felt){
}

@storage_var
func underlying() -> (underlying : felt){
}

@storage_var
func registery() -> (registery : felt){
}


// Protector

func assert_only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_) = get_caller_address();
    let (drip_manager_) = drip_manager.read();
    with_attr error_message("Drip: only callable by drip manger") {
        assert caller_ = drip_manager_;
    }
    return();
}

//Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _drip_manager: felt,
    _drip_transit: felt,
    _minimum_borrowed_amount: Uint256, // minimal amount for drip 
    _maximum_borrowed_amount: Uint256, // maximum amount for drip 
    _allowed_tokens_len: felt,
    _allowed_tokens: AllowedToken*) {
    drip_manager.write(_drip_manager);
    drip_transit.write(_drip_transit);
    let (pool_) = IDripManager.getPool(_drip_manager);
    let (underlying_) = IPool.asset(pool_);
    let (registery_) = IPool.getRegistery(pool_);
    underlying.write(underlying_);
    registery.write(registery_);
    let (owner_) = IRegistery.owner(registery_);
    Ownable.initializer(owner_);
    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount,Uint256(DEFAULT_FEE_INTEREST,0),Uint256(DEFAULT_FEE_LIQUIDATION,0), Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM,0), Uint256(DEFAULT_CHI_THRESHOLD,0), Uint256(DEFAULT_HF_CHECK_INTERVAL,0));
    allow_token_list(_allowed_tokens_len, _allowed_tokens);
    let (oracle_transit_) = IDripManager.oracleTransit(_drip_manager);
    IDripManager.upgradeContracts(_drip_manager, _drip_transit, oracle_transit_);
    return();
}


// TOKEN MANAGEMENT

@external
func addTokenToAllowedList{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt){
    Ownable.assert_only_owner();
    add_token_to_allowed_list(_token);
    return();
}

@external
func setLiquidationThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt, _liquidation_threshold: Uint256){
    Ownable.assert_only_owner();
    set_liquidation_threshold(_token, _liquidation_threshold);
    return();
}

@external
func allowToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_token: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMask(drip_manager_, _token);
    let (fordbiden_token_mask_) = IDripManager.forbidenTokenMask(drip_manager_);
    let (is_eq1_) = uint256_eq(Uint256(0,0), token_mask_);
    let (is_eq2_) = uint256_eq(Uint256(1,0), token_mask_);
    with_attr error_message("token not allowed "){
        assert_not_zero(is_eq1_ * is_eq2_);
    }
    let (low_) = bitwise_and(fordbiden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(fordbiden_token_mask_.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0,0), Uint256(low_, high_));
    if (is_bt_ == 1){
        let (low_) = bitwise_xor(fordbiden_token_mask_.low, token_mask_.low);
        let (high_) = bitwise_xor(fordbiden_token_mask_.high, token_mask_.high);
        IDripManager.setForbidMask(drip_manager_, Uint256(low_, high_));
        TokenAllowed.emit(_token);
        return();
    }
    return();
}

@external
func forbidToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(_token: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMask(drip_manager_, _token);
    let (fordbiden_token_mask_) = IDripManager.forbidenTokenMask(drip_manager_);
    let (is_eq1_) = uint256_eq(Uint256(0,0),token_mask_);
    let (is_eq2_) = uint256_eq(Uint256(1,0),token_mask_);
    with_attr error_message("zero address for token"){
        assert_not_zero(is_eq1_ * is_eq2_);
    }
    let (low_) = bitwise_and(fordbiden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(fordbiden_token_mask_.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0,0), Uint256(low_, high_));
    if (is_bt_ == 1){
        let (low_) = bitwise_or(fordbiden_token_mask_.low, token_mask_.low);
        let (high_) = bitwise_or(fordbiden_token_mask_.high, token_mask_.high);
        IDripManager.setForbidMask(drip_manager_, Uint256(low_, high_));
        TokenAllowed.emit(_token);
        return();
    }
    return();
}

 // CONTRACTS & ADAPTERS MANAGEMENT

@external
func allowContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt, _adapter: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    with_attr error_message("zero address for contract or adapter"){
        assert_not_zero(_contract * _adapter);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_transit_) = drip_transit.read();
    with_attr error_message("drip manager or drip transit exeption"){
        assert_not_zero((_contract - drip_manager_)*(_contract - drip_transit_)*(_adapter - drip_manager_)*(_adapter - drip_transit_));
    }
    let (contract_from_adapter_) = IDripManager.adapterToContract(drip_manager_, _adapter);
    let (adapter_from_contract_) = IDripTransit.contractToAdapter(drip_transit_, _contract);
    with_attr error_message("adapter used twice"){
        assert_not_zero(contract_from_adapter_ * adapter_from_contract_);
    }
    let (drip_manager_from_adapter_) = IAdapter.dripManager(_adapter);
    with_attr error_message("wrong drip manager from adapter"){
        assert_not_zero(contract_from_adapter_ * adapter_from_contract_);
    }
    IDripTransit.setContractToAdapter(drip_transit_, _contract, _adapter);
    IDripManager.changeContractAllowance(drip_manager_, _contract, _adapter);

    let (allowed_contract_length_) = allowed_contract_length.read();
    id_to_allowed_contract.write(allowed_contract_length_, _contract);
    allowed_contract_to_id.write(_contract, allowed_contract_length_);
    allowed_contract_length.write(allowed_contract_length_ + 1);
    is_allowed_contract.write(1);
    ContractAllowed.emit(_contract);
    return();
}

@external
func forbidContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    with_attr error_message("zero address for contract"){
        assert_not_zero(_contract);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_transit_) = drip_transit.read();

    let (adapter_) = IDripTransit.contractToAdapter(drip_transit_, _contract);
    with_attr error_message("adapter not connected"){
        assert_not_zero(adapter_);
    }

    IDripManager.changeContractAllowance(drip_manager_, _contract, 0);
    IDripTransit.setContractToAdapter(drip_transit_, 0, _contract);

    let (allowed_contract_length_) = allowed_contract_length.read();
    let (id_to_remove_) = allowed_contract_to_id.read(_contract);
    let (last_allowed_contract_) = id_to_allowed_contract.read(allowed_contract_length_ - 1);
    id_to_allowed_contract.write(id_to_remove_, last_allowed_contract_);
    allowed_contract_to_id.write(allowed_contract_length_ - 1, 0);
    allowed_contract_to_id.write(last_allowed_contract_, id_to_remove_);
    allowed_contract_length.write(allowed_contract_length_ - 1);
    id_to_allowed_contract.write(allowed_contract_length_ - 1, 0);
    is_allowed_contract.write(0);
    ContractForbidden.emit(_contract);
    return();
}

@external
func setLimits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    let (fee_interest_) = IDripManager.feeInterest(drip_manager_);
    let (fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);
    let (liquidation_discount_) = IDripManager.liquidationDiscount(drip_manager_);
    let (chi_threshold_) = IDripManager.chiThreshold(drip_manager_);
    let (hf_check_interval_) = IDripManager.hfCheckInterval(drip_manager_);
    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount, fee_interest_, fee_liqudidation_, liquidation_discount_, chi_threshold_, hf_check_interval_);
    LimitsUpdated.emit(_minimum_borrowed_amount, _maximum_borrowed_amount);
    return();
}

@external
func setFastCheckParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_chi_threshold: Uint256, _hf_check_interval: Uint256){
    alloc_locals;
    Ownable.assert_only_owner();
    let (is_bt_) = uint256_lt(Uint256(PRECISION,0), _chi_threshold);
    with_attr error_message("chi threshold too big"){
        assert_not_zero(is_bt_);
    }
    let (drip_manager_) = drip_manager.read();
    let (minimum_borrowed_amount_) = IDripManager.minBorrowedAmount(drip_manager_);
    let (maximum_borrowed_amount_) = IDripManager.maxBorrowedAmount(drip_manager_);
    let (fee_interest_) = IDripManager.feeInterest(drip_manager_);
    let (fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);
    let (liquidation_discount_) = IDripManager.liquidationDiscount(drip_manager_);
    set_parameters(minimum_borrowed_amount_, maximum_borrowed_amount_, fee_interest_, fee_liqudidation_, liquidation_discount_, _chi_threshold, _hf_check_interval);    
    FastCheckParametersUpdated.emit(_chi_threshold, _hf_check_interval);
    return();
}

@external
func setFees{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_fee_interest: Uint256, _fee_liquidation: Uint256, _liquidation_premium: Uint256){
    alloc_locals;
    Ownable.assert_only_owner();
    let (is_bt1_) = uint256_le(Uint256(PRECISION,0), _fee_interest);
    let (sum_) = SafeUint256.add(_liquidation_premium, _fee_liquidation);
    let (is_bt2_) = uint256_le(Uint256(PRECISION,0), sum_);
    with_attr error_message("incorrect fees"){
        assert_not_zero(is_bt1_ * is_bt2_);
    }
    let (liquidation_discount_) = SafeUint256.sub_le(Uint256(PRECISION,0), _liquidation_premium);

    let (drip_manager_) = drip_manager.read();
    let (minimum_borrowed_amount_) = IDripManager.minBorrowedAmount(drip_manager_);
    let (maximum_borrowed_amount_) = IDripManager.maxBorrowedAmount(drip_manager_);
    let (chi_threshold_) = IDripManager.chiThreshold(drip_manager_);
    let (hf_check_interval_) = IDripManager.hfCheckInterval(drip_manager_);
    set_parameters(minimum_borrowed_amount_, maximum_borrowed_amount_, _fee_interest, _fee_liquidation, liquidation_discount_, chi_threshold_, hf_check_interval_);    
    FeesUpdated.emit(_fee_interest, _fee_liquidation, _liquidation_premium);
    return();
}

@external
func upgradeOracleTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    let (registery_) = registery.read();
    let (oracle_transit_) = IRegistery.oracleTransit(registery_);
    let (drip_transit_) = drip_transit.read();
    IDripManager.upgradeContracts(drip_manager_, drip_transit_, oracle_transit_);
    OracleTransitUpgraded.emit(oracle_transit_);
    return();
}

@external
func upgradeDripTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_transit: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    let (registery_) = registery.read();
    let (oracle_) = IRegistery.oracleTransit(registery_);
    IDripManager.upgradeContracts(drip_manager_, _drip_transit, oracle_);
    DripTransitUpgraded.emit(_drip_transit);
    return();
}

@external
func upgradeConfigurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_configurator: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    IDripManager.setDripConfigurator(drip_manager_, _drip_configurator);
    return();
}

@external
func setIncreaseDebtForbidden{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_state: felt){
    alloc_locals;
    Ownable.assert_only_owner();
    let (drip_manager_) = drip_manager.read();
    IDripManager.setIncreaseDebtForbidden(drip_manager_, _state);
    return();
}

@view
func idToAllowedContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: felt) -> (allowedContract: felt){
    alloc_locals;
    let (allowed_contract_) = id_to_allowed_contract.read(id);
    return(allowed_contract_,);
}

@view
func allowedContractToId{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_allowed_contract: felt) -> (id: felt){
    alloc_locals;
    let (id_) = allowed_contract_to_id.read(_allowed_contract);
    return(id_,);
}

@view
func allowedContractsLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: felt) -> (allowedContractsLength: felt){
    alloc_locals;
    let (allowed_contract_length_) = allowed_contract_length.read();
    return(allowed_contract_length_,);
}

@view
func isAllowedContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt) -> (state: felt){
    alloc_locals;
    let (state_) = is_allowed_contract.read(_contract);
    return(state_,);
}


// Internals

func allow_token_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_allowed_tokens_len: felt, _allowed_tokens: AllowedToken*){
    alloc_locals;
    if(_allowed_tokens_len == 0){
        return();
    }
    add_token_to_allowed_list(_allowed_tokens[0].address);
    set_liquidation_threshold(_allowed_tokens[0].address, _allowed_tokens[0].liquidation_threshold);
    return allow_token_list(_allowed_tokens_len - 1, _allowed_tokens + AllowedToken.SIZE);
}

func add_token_to_allowed_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt){
    
    with_attr error_message("zero address for token"){
        assert_not_zero(_token);
    }
    //TODO: Check ERC20 contract
    // try call balanceOf ? 

    let (drip_manager_)= drip_manager.read();
    let (oracle_transit_) = IDripManager.oracleTransit(drip_manager_);
    let (derivative_price_feed_) = IOracleTransit.derivativePriceFeed(oracle_transit_, _token);
    let (pair_id_) = IOracleTransit.primitivePairId(oracle_transit_, _token);
    with_attr error_message("no price feed for token"){
        assert_not_zero(derivative_price_feed_ + pair_id_);
    }
    IDripManager.addToken(drip_manager_, _token);
    TokenAllowed.emit(_token);
    return();
}

func set_liquidation_threshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt, _liquidation_threshold: Uint256){
    let (underlying_) = underlying.read();
    with_attr error_message("underlying is token"){
        assert_not_zero(underlying_ - _token);
    }

    let (drip_manager_) = drip_manager.read();
    let (underlying_liquidation_threshold_) = IDripManager.liquidationThreshold(drip_manager_, underlying_);
    let (is_lt1_) = uint256_lt(Uint256(0,0), _liquidation_threshold);
    let (is_lt2_) = uint256_lt(_liquidation_threshold, underlying_liquidation_threshold_);
    with_attr error_message("incorrect liquidation threshold for token"){
        assert_not_zero(is_lt1_ * is_lt2_);
    }

    IDripManager.setLiquidationThreshold(drip_manager_, _token, _liquidation_threshold);
    TokenLiquidationThresholdUpdated.emit(_token, _liquidation_threshold);
    return();
}

func set_parameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _minimum_borrowed_amount: Uint256, 
        _maximum_borrowed_amount: Uint256,
        _fee_interest: Uint256,
        _fee_liquidation: Uint256,
        _liquidation_discount: Uint256,
        _chi_threshold: Uint256,
        _hf_check_interval: Uint256){
    alloc_locals;
    let (drip_manager_) = drip_manager.read();
    let (underlying_) = underlying.read();
    let (lt_underlying_) = IDripManager.liquidationThreshold(drip_manager_, underlying_);
    let (current_chi_threshold_) = IDripManager.chiThreshold(drip_manager_);
    let (current_hf_check_interval_) = IDripManager.hfCheckInterval(drip_manager_);
    let (current_fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);

    let (new_lt_underlying_) = SafeUint256.sub_le(_liquidation_discount, _fee_liquidation);
    let (is_eq_) = uint256_eq(lt_underlying_, new_lt_underlying_);
    let (is_eq1_) = uint256_eq(_chi_threshold, current_chi_threshold_);
    let (is_eq2_) = uint256_eq(_hf_check_interval, current_hf_check_interval_);
    let (is_eq3_) = uint256_eq(_fee_liquidation, current_fee_liqudidation_);
    if(is_eq_ == 0){
        update_liquidation_threshold(new_lt_underlying_);
        tempvar syscall_ptr= syscall_ptr;
        tempvar pedersen_ptr= pedersen_ptr;
        tempvar range_check_ptr= range_check_ptr;
    } else {
        tempvar syscall_ptr= syscall_ptr;
        tempvar pedersen_ptr= pedersen_ptr;
        tempvar range_check_ptr= range_check_ptr;
    }
    
    if(is_eq1_ * is_eq2_ * is_eq3_ == 0){
        check_fast_check_parameters_coverage(_chi_threshold, _hf_check_interval, _fee_liquidation);
        tempvar syscall_ptr= syscall_ptr;
        tempvar pedersen_ptr= pedersen_ptr;
        tempvar range_check_ptr= range_check_ptr;
    } else {
        tempvar syscall_ptr= syscall_ptr;
        tempvar pedersen_ptr= pedersen_ptr;
        tempvar range_check_ptr= range_check_ptr;
    }
    IDripManager.setParameters(drip_manager_, _minimum_borrowed_amount, _maximum_borrowed_amount, _fee_interest, _fee_liquidation, _liquidation_discount, _chi_threshold, _hf_check_interval);
    return();
}

func update_liquidation_threshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_lt_underlying: Uint256){
    let (underlying_) = underlying.read();
    let (drip_manager_) = drip_manager.read();
    IDripManager.setLiquidationThreshold(drip_manager_, underlying_, _lt_underlying);
    let (length_) = IDripManager.allowedTokensLength(drip_manager_);
    loop_liquidation_threshold(length_, drip_manager_, _lt_underlying);
    return();
}

func loop_liquidation_threshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_len: felt, _drip_manager: felt,_lt_underlying: Uint256){
    if(_len == 0){
        return();
    }
    let (token_) = IDripManager.allowedToken(_drip_manager, _len - 1);
    let (lt_token_) = IDripManager.liquidationThreshold(_drip_manager, token_);
    let (is_lt_) = uint256_lt(_lt_underlying, lt_token_);
    if(is_lt_ == 1){
        IDripManager.setLiquidationThreshold(_drip_manager, token_, _lt_underlying);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    return loop_liquidation_threshold(_len - 1,  _drip_manager, _lt_underlying);
}

func check_fast_check_parameters_coverage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_chi_threshold: Uint256, _hf_check_interval: Uint256, _fee_liquidation: Uint256){
    let (step1_) = calcul_max_possible_drop(_chi_threshold, _hf_check_interval);
    let (max_possible_drop_) = SafeUint256.sub_le(Uint256(PRECISION,0), step1_);
    let (is_lt_) = uint256_lt(_fee_liquidation, max_possible_drop_);
    with_attr error_message("zero address for token"){
        assert is_lt_ = 1;
    }
    return ();
}

func calcul_max_possible_drop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_percentage: Uint256, _times: Uint256) -> (max_possible_drop: Uint256){
    let (is_eq_) = uint256_eq(Uint256(PRECISION,0), _percentage);
    if (is_eq_ == 1) {
        return(Uint256(PRECISION,0),);
    }
    let (step1_) = loop_percent(_percentage, _times);
    let (new_value_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
    return (new_value_,);
}

func loop_percent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_percentage: Uint256, _times: Uint256) -> (max_possible_drop: Uint256){
    let (is_eq_) = uint256_le(_times, Uint256(0,0));
    if (is_eq_ == 1) {
        let (initial_value_) = SafeUint256.mul(_percentage, Uint256(PRECISION,0));
        return(initial_value_,);
    }
    let (time_less_) = SafeUint256.sub_le(_times, Uint256(1,0));
    let (previous_value_) = loop_percent(_percentage, time_less_);
    let (step1_) = SafeUint256.mul(_percentage, previous_value_); 
    let (new_value_,_) = SafeUint256.div_rem(step1_, Uint256(PRECISION,0));
    return (new_value_,);
}