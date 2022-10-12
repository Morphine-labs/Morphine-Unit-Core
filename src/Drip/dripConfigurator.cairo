%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)

from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_lt
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from starkware.cairo.common.math import assert_not_zero
from src.utils.safeerc20 import SafeERC20
from src.utils.various import ALL_ONES, DEFAULT_FEE_INTEREST, DEFAULT_LIQUIDATION_PREMIUM, DEFAULT_CHI_THRESHOLD, DEFAULT_HF_CHECK_INTERVAL, PRECISION
from src.Extensions.IIntegrationManager import IIntegrationManager
from openzeppelin.token.erc20.IERC20 import IERC20
from src.interfaces.IPool import IPool


// Events


@event 
func TokenAllowed(token: felt){
}

@event 
func TokenForbidden(token: felt){
}

@event 
func ContractAllowed(token: felt){
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
func PriceOracleUpgraded(oracle: felt){
}

@event 
func CreditFacadeUpgraded(credit_facade: felt){
}





// Storage

@storage_var
func drip_manager() -> (address : felt) {
}

@storage_var
func drip_facade() -> (address : felt) {
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
func configurator_only(){
    let (caller_) = get_caller_address();
    let (contract_address_) = get_contract_address();
    with_attr error_message("Only the configurator can call this function"){
        assert caller_ = contract_address_;
    }
}

func assert_only_drip_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_) = get_caller_address();
    let (drip_manager_) = drip_manager.read();
    with_attr error_message("Drip: only callable by drip manger") {
        assert caller_ = drip_manager_;
    }
    return();
}

struct AllowedToken {
    address: felt; // Address of token
    liquidation_threshold: Uint256; // LT for token in range 0..10,000 which represents 0-100%
}

//Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _drip_manager: felt,
    _dripFacade: felt,
    _minimum_borrowed_amount: Uint256, // minimal amount for drip 
    _maximum_borrowed_amount: Uint256, // maximum amount for drip 
    _allowed_tokens_len: felt,
    _allowed_tokens: AllowedToken*, // allowed tokens list
    ) {
    drip_manager.write(_drip_manager);
    drip_facade.write(_dripFacade);
    let (pool_) = IDripManager.pool(_drip_manager);
    let (underlying_) = IPool.asset(pool_);
    let (registery_) = IPool.addressProvider();
    underlying.write();
    registery.write();

    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount,0),Uint256(DEFAULT_FEE_INTEREST,0),Uint256(DEFAULT_FEE_LIQUIDATION,0), Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM,0), Uint256(DEFAULT_CHI_THRESHOLD,0), Uint256(DEFAULT_HF_CHECK_INTERVAL,0));
    allow_token_list(_allowed_tokens_len, _allowed_tokens);
    let (oracle_) = IDripManager.priceOracle(_drip_manager);
    IDripManager.upgradeContracts(_drip_manager, _dripFacade, _dripFacade);
    return();
);


// TOKEN MANAGEMENT

@external
func addTokenToAllowedList{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt){
    configurator_only();
    add_token_to_allowed_list();
    return();
}

@external
func setLiquidationThreshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt, _liquidation_threshold: Uint256){
    configurator_only();
    set_liquidation_threshold();
    return();
}

@external
func allowToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt){
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMasksMap(drip_manager_, _token);
    let (fordbiden_token_mask_) = IDripManager.forbidenTokenMask(drip_manager_);
    let (is_eq1_) = uint256_eq(Uint256(0,0));
    let (is_eq2_) = uint256_eq(Uint256(1,0));
    with_attr error_message("zero address for token"){
        assert_not_zero(is_eq1_ * is_eq2_);
    }
    let (low_) = bitwise_and(fordbiden_token_mask_.low, token_mask_.low);
    let (high_) = bitwise_and(fordbiden_token_mask_.high, token_mask_.high);
    let (is_bt_) = uint256_lt(Uint256(0,0), Uint256(low_, high_));
    if (is_bt_ == 1){
        let (low_) = bitwise_xor(fordbiden_token_mask_.low, token_mask_.low);
        let (high_) = bitwise_xor(fordbiden_token_mask_.high, token_mask_.high);
        IDripManager.setForbidMask(drip_manager_, Uint256(low_, high_));
        tokenAllowed.emit(_token);
    }
    return();
}

@external
func forbidToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt){
    alloc_locals;
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    let (token_mask_) = IDripManager.tokenMasksMap(drip_manager_, _token);
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
        tokenAllowed.emit(_token);
    }
    return();
}

 // CONTRACTS & ADAPTERS MANAGEMENT

@external
func allowContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt, _adapter: felt){
    alloc_locals;
    configurator_only();
    with_attr error_message("zero address for contract or adapter"){
        assert_not_zero(_contract * _adapter);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_facade_) = drip_facade.read();
    with_attr error_message("drip manager or drip facade exeption"){
        assert_not_zero((_contract - drip_manager_)*(_contract - drip_facade_)*(_adapter - drip_manager_)*(_adapter - drip_facade_));
    }
    let (contract_from_adapter_) = IDripManager.adapterToContract(drip_manager_, _adapter);
    let (adapter_from_contract_) = IDripManager.contractToAdapter(drip_manager_, _contract);
    with_attr error_message("adapter used twice"){
        assert_not_zero(contract_from_adapter_ * adapter_from_contract_);
    }
    let (drip_manager_from_adapter_) = IAdapter.dripManager(_adapter);
    with_attr error_message("wrong drip manager from adapter"){
        assert_not_zero(contract_from_adapter_ * adapter_from_contract_);
    }
    IDripFacade.setContractToAdapter(drip_facade_, _contract, _adapter);
    IDripManager.changeContractAllowance(drip_manager_, _contract, _adapter);

    let (allowed_contract_length_) = allowed_contract_length.read();
    id_to_allowed_contract.write(allowed_contract_length_, _contract);
    allowed_contract_to_id.write(_contract, allowed_contract_length_);
    allowed_contract_length.write(allowed_contract_length_ + 1);

    ContractAllowed.emit(_contract);
    return();
}

@external
func forbidContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract: felt){
    alloc_locals;
    configurator_only();
    with_attr error_message("zero address for contract"){
        assert_not_zero(_contract);
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_facade_) = drip_facade.read();

    let (adapter_) = IDripFacade.contractToAdapter(drip_facade_, );
    with_attr error_message("adapter not connected"){
        assert_not_zero(adapter_);
    }

    IDripManager.changeContractAllowance(drip_manager_, _contract, 0);
    IDripFacade.setContractToAdapter(drip_facade_, 0, _contract);

    let (allowed_contract_length_) = allowed_contract_length.read();
    let (id_to_remove_) = allowed_contract_to_id.read(_contract);
    let (last_allowed_contract_) = id_to_allowed_contract(allowed_contract_length_ - 1);
    id_to_allowed_contract.write(id_to_remove_, last_allowed_contract_);
    allowed_contract_to_id(allowed_contract_length_ - 1, 0);
    allowed_contract_to_id(last_allowed_contract_, id_to_remove_);
    allowed_contract_length_.write(allowed_contract_length_ - 1);
    ContractForbidden.emit(_contract);
    return();
}

@external
func setLimits{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    alloc_locals;
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    let (fee_interest_) = IDripManager.feeInterest(drip_manager_);
    let (fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);
    let (liquidation_discount_) = IDripManager.liquidationDiscount(drip_manager_);
    let (chi_threshold_) = IDripManager.chiThreshold(drip_manager_);
    let (hf_check_interval_) = IDripManager.hfCheckInterval(drip_manager_);
    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount, fee_interest_, fee_liqudidation_, liquidation_discount_, chi_threshold_, hf_check_interval_);
    LimitsUpdated(_minimum_borrowed_amount, _maximum_borrowed_amount);
    return();
}

@external
func setFastCheckParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_chi_threshold: Uint256, _hf_check_interval: Uint256){
    alloc_locals;
    configurator_only();
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
    configurator_only();
    let (is_bt1_) = uint256_le(Uint256(PRECISION,0), _fee_interest);
    let (sum_) = safeUint256.add(_liquidation_premium, _fee_liquidation);
    let (is_bt2_) = uint256_le(Uint256(PRECISION,0), sum_);
    with_attr error_message("incorrect fees"){
        assert_not_zero(is_bt1_ * is_bt2_);
    }
    let (liquidation_discount_) = safeUint256.sub_le(Uint256(PRECISION,0), _liquidation_premium);

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
func upgradePriceOracle{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    let (registery_) = registery.read();
    let (oracle_) = IRegistery.getPriceOracle(registery_);
    let (drip_facade_) = drip_facade.read();
    IDripManager.upgradeContracts(drip_manager_, drip_facade_, oracle_);
    PriceOracleUpgraded.emit(oracle_);
    return();
}

@external
func upgradeDripFacade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_drip_facade_: felt){
    alloc_locals;
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    let (registery_) = registery.read();
    let (oracle_) = IRegistery.getPriceOracle(registery_);
    IDripManager.upgradeContracts(drip_manager_, _drip_facade_, oracle_);
    CreditFacadeUpgraded.emit(_drip_facade_);
    return();
}

@external
func upgradeConfigurator{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_configurator: felt){
    alloc_locals;
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    IDripManager.setConfigurator(drip_manager_, _configurator);
    return();
}

@external
func setIncreaseDebtForbidden{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_mode: felt){
    alloc_locals;
    configurator_only();
    let (drip_manager_) = drip_manager.read();
    IDripManager.setIncreaseDebtForbidden(drip_manager_, _mode);
    return();
}

@external
func IdToAllowedContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: felt) -> (allowedContract: felt){
    alloc_locals;
    let (allowed_contract_) = id_to_allowed_contract.read(id);
    return(allowed_contract_);
}

@external
func allowedContractsLength{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(id: felt) -> (allowedContractsLength: felt){
    alloc_locals;
    let (allowed_contract_length_) = allowed_contract_length.read();
    return(allowed_contract_length_);
}


// Internals

func allow_token_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_allowed_tokens_len: felt, _allowed_tokens: AllowedToken){
    if(_allowed_tokens_len == 0){
        return();
    }
    add_token_to_allowed_list(_allowed_tokens[0].address);
    set_liquidation_threshold(_allowed_tokens[0].address, _allowed_tokens[0].liquidation_threshold);
    return(_allowed_tokens_len - 1, _allowed_tokens + AllowedToken.SIZE);
}

func add_token_to_allowed_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt){
    
    with_attr error_message("zero address for token"){
        assert_not_zero(_token);
    }
    //TODO: Check ERC20 contract
    // try call balanceOf ? 

    let (drip_manager_)= drip_manager.read();
    let (oracle_) = IDripManager.oracle();
    let (has_price_feed_) = IOracle.hasPriceFeed(oracle_);
    with_attr error_message("no price feed for token"){
        assert_not_zero(has_price_feed_);
    }

    IDripManager.addToken(_token);
    TokenAllowed.emit(_token);
    return();
}

func set_liquidation_threshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt, _liquidation_threshold: Uint256){
    let (underlying_) = underlying.read();
    with_attr error_message("zero address for token"){
        assert_not_zero(underlying_ - _token);
    }

    let (drip_manager_) = drip_manager.read();
    let (underlying_liquidation_threshold_) = IDripManager.liquidationThreshold(drip_manager_, underlying_);
    let (is_lt1_) = uint256_lt(Uint256(0,0), _liquidation_threshold);
    let (is_lt2_) = uint256_lt(_liquidation_threshold, underlying_liquidation_threshold_);
    with_attr error_message("incorrect liquidation threshold for token"){
        assert_not_zero(is_lt1_ * is_lt2_);
    }

    IDripManager.setLiquidationThreshold(_token, _liquidation_threshold);
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
    let (drip_manager_) = drip_manager.read();
    let (underlying_) = underlying.read();
    let (lt_underlying_) = IDripManager.liquidationThresholds(drip_manager_, underlying_);
    let (new_lt_underlying_) = safeUint256.sub_le(_liquidation_discount, _fee_liquidation);
    let (is_eq_) = uint256_eq(lt_underlying_, new_lt_underlying_);
    if(is_eq_ == 0){
        update_liquidation_threshold(new_lt_underlying_);
    }
    let (current_chi_threshold_) = IDripManager.chiThreshold(drip_manager_);
    let (current_hf_check_interval_) = IDripManager.hfCheckInterval(drip_manager_);
    let (current_fee_liqudidation_) = IDripManager.feeLiquidation(drip_manager_);
    let (is_eq1_) = uint256_eq(_chi_threshold, current_chi_threshold_);
    let (is_eq2_) = uint256_eq(_hf_check_interval, current_hf_check_interval_);
    let (is_eq3_) = uint256_eq(_fee_liquidation, current_fee_liqudidation_);
    
    if(is_eq1_ * is_eq2_ * is_eq3_){
        check_fast_check_parameters_coverage(_chi_threshold, _hf_check_interval, _fee_liquidation);
    }
    IDripFacade.setParameters(_minimum_borrowed_amount, _maximum_borrowed_amount, _fee_interest, _fee_liquidation, _liquidation_discount, _chi_threshold, _hf_check_interval);
    return();
}

func update_liquidation_threshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_lt_underlying: Uint256){
    let (underlying_) = underlying.read();
    let (drip_manager_) = drip_manager.read();
    IDripManager.setLiquidationThreshold(underlying_, _lt_underlying);
    let (length_) = IDripManager.allowedTokensCount(drip_manager_);
    loop_liquidation_threshold(length_, drip_manager_, _lt_underlying);
    return();
}

func loop_liquidation_threshold{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_len: felt, _drip_manager: felt,_lt_underlying: Uint256){
    if(_len == 0){
        return();
    }
    let (token_) = IDripManager.allowedTokens(_drip_manager, _len - 1);
    let (lt_token_) = IDripManager.liquidationThreshold(_drip_manager, token_);
    let (is_lt_) = uint256_lt(_lt_underlying, lt_token_);
    if(is_lt_ == 1){
        IDripManager.setLiquidationThreshold(_drip_manager, token_, _lt_underlying);
    } 
    return loop_liquidation_threshold(_len - 1, _lt_underlying);
}

func check_fast_check_parameters_coverage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_chi_threshold: Uint256, _hf_check_interval: Uint256, _fee_liquidation: Uint256){
    if(_len == 0){
        return();
    }
    let (step1_) = calcul_max_possible_drop();
    let (max_possible_drop_) = safeUint256.sub_le(step1_, Uint256(PRECISION,0));
    let (is_lt_) = uint256_lt(_fee_liquidation, max_possible_drop_);
    with_attr error_message("zero address for token"){
        assert is_lt_ = 1;
    }
    return ();
}

func calcul_max_possible_drop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_percentage: Uint256, _times: Uint256) -> (max_possible_drop: Uint256){
    let (is_eq_) = uint256_eq(Uint256(PRECISION,0), _percentage);
    if (is_eq_ == 1) {
        return(Uint256(PRECISION,0));
    }
    let (step1_) = loop_percent(_percentage, _times);
    let (new_value_) = safeUint256.div_rem(step1_, Uint256(PRECISION,0));
    return (new_value_);
}

func loop_percent{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_percentage: Uint256, _times: Uint256) -> (max_possible_drop: Uint256){
    let (is_le_) = uint256_le(_times, Uint256(1,0));
    if (is_le_ == 1) {
        let (initial_value_) = safeUint256.mul(_percentage, Uint256(PRECISION,0));
        return(initial_value_);
    }
    let (previous_value_) = loop_percent();
    let (step1_) = safeUint256.mul(_percentage, previous_value_); 
    let (new_value_) = safeUint256.div_rem(step1_, Uint256(PRECISION,0));
    return(new_value_);
}