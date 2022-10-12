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

    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount,0),Uint256(DEFAULT_FEE_INTEREST,0),Uint256(DEFAULT_FEE_LIQUIDATION,0), Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM,0), Uint256(DEFAULT_CHI_THRESHOLD,0), Uint256(DEFAULT_HF_CHECK_INTERVAL,0));
    allow_token_list(_allowed_tokens_len, _allowed_tokens);
    let (oracle_) = IDripManager.priceOracle(_drip_manager);
    IDripManager.upgradeContracts(_drip_manager, _dripFacade, _dripFacade);
    return();
    );



// @external
// func addTokenToList{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     token: felt
// ) {
//     let (IM_ : felt) = integration_manager.read();
//     IIntegrationManager.setAvailableAsset(IM_, token);
//     return();
// }

// func addAllowContract {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract : felt, _address_adapter : felt, _integration : felt, _level : felt){
//     configurator_only();
//     let (IM_ : felt) = integration_manager.read();
//     let (parameter_issues) = _contract -  0 * address_adapter - 0;
//     with_attr error_message("The address of the contract or the adapter is not valid"){
//         assert parameter_issues = 0;
//     }
//     let (drip_manager_) = drip_manager.read();
//     let (drip_facade_) = drip_facade.read();
//     let (manager_issues) = drip_manager_ - _contract * drip_manager_ - address_adapter;
//     let (facades_issues) = drip_facade_ - _contract * drip_facade_ - address_adapter;
//     let (drip_issues_) = manager_issues - 0 * facades_issues - 0;
//     with_attr error_message("The contract or the adapter is either the drip manager or the drip facade"){
//         assert drip_issues_ = 0;
//     }
//     IIntegrationManager.setAvailableIntegration(IM_, _contract, _address_adapter, _integration, _level);
//     return();
// }

// func setLimits {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(min : Uint256, max : Uint256){
//     let (contract_address_) = get_contract_address();
//     return();
// }


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
    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount,0),Uint256(DEFAULT_FEE_INTEREST,0),Uint256(DEFAULT_FEE_LIQUIDATION,0), Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM,0), Uint256(DEFAULT_CHI_THRESHOLD,0), Uint256(DEFAULT_HF_CHECK_INTERVAL,0));
    LimitsUpdated(_minimum_borrowed_amount, _maximum_borrowed_amount);
    return();
}

@external
func setFastCheckParameters{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    alloc_locals;
    configurator_only();
    set_parameters(_minimum_borrowed_amount, _maximum_borrowed_amount,0),Uint256(DEFAULT_FEE_INTEREST,0),Uint256(DEFAULT_FEE_LIQUIDATION,0), Uint256(PRECISION - DEFAULT_LIQUIDATION_PREMIUM,0), Uint256(DEFAULT_CHI_THRESHOLD,0), Uint256(DEFAULT_HF_CHECK_INTERVAL,0));
    LimitsUpdated(_minimum_borrowed_amount, _maximum_borrowed_amount);
    return();
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