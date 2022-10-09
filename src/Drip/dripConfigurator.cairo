%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    call_contract,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from src.utils.safeerc20 import SafeERC20
from src.utils.various import ALL_ONES
from src.Extensions.IIntegrationManager import IIntegrationManager
from src.Drip.dripManager import CreditManagerOpts
from openzeppelin.token.erc20.IERC20 import IERC20


// Storage

@storage_var
func is_allowed_contract(contract: felt) -> (is_allowed_contract : felt){
}

@storage_var
func allowed_contract_len(contract: felt) -> (is_allowed_contract : felt){
}

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
func integration_manager() -> (contract : felt) {
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

//Constructor

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _drip_manager: felt,
    _dripFacade: felt,
    _poolFactory: felt,
    _integration_manager : felt,
    _opts : CreditManagerOpts) {
    drip_manager.write(_drip_manager);
    drip_facade.write(_dripFacade);
    pool_factory.write(_poolFactory);
    integration_manager.write(_integration_manager);
    /// Sets limits, fees and fastCheck parameters for credit manager
        // _setParams(
        //     opts.minBorrowedAmount,
        //     opts.maxBorrowedAmount,
        //     DEFAULT_FEE_INTEREST,
        //     DEFAULT_FEE_LIQUIDATION,
        //     PERCENTAGE_FACTOR - DEFAULT_LIQUIDATION_PREMIUM,
        //     DEFAULT_CHI_THRESHOLD,
        //     DEFAULT_HF_CHECK_INTERVAL
        // ); // F:[CC-1]
        //_addTokenToAllowedList(token); // F:[CC-1]

        // creditManager.upgradeContracts(
        //     address(_creditFacade),
        //     address(creditManager.priceOracle())
        // ); // F:[CC-1]

    return();
}

@external
func setLiquidationThreshold {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token: felt, threshold: Uint256) {
    configurator_only();
    let (IM_ : felt) = integration_manager.read();
    let (is_available_asset_) = IIntegrationManager.isAvailableAsset(IM_,token);
    with_attr error_message("Asset is not support yet"){
        assert is_available_asset_ = 1;
    }
    liquidationThreshold.write(token, threshold);
    return();
}

@external
func approveToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _token: felt,
        _contract: felt) {
    assert_only_drip_manager();
    IERC20.approve(_token, _contract, Uint256(ALL_ONES,ALL_ONES));
    return();
}

@external
func cancelAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _token: felt,
        _contract: felt) {
    assert_only_drip_manager();
    IERC20.approve(_token, _contract, Uint256(0,0));
    return();
}

@external
func safeTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _token: felt,
        _to: felt,
        _amount: Uint256) {
    assert_only_drip_manager();
    SafeERC20.transfer(_token, _to, _amount);
    return();
}

@external
func execute{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        _to: felt,
        _selector: felt,
        _calldata_len: felt,
        _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
    assert_only_drip_manager();
    let (retdata_len: felt, retdata: felt*) = call_contract(_to,_selector, _calldata_len, _calldata);
    return(retdata_len, retdata);
}

@external
func addTokenToList{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token: felt
) {
    let (IM_ : felt) = integration_manager.read();
    IIntegrationManager.setAvailableAsset(IM_, token);
    return();
}

func addAllowContract {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_contract : felt, _address_adapter : felt, _integration : felt, _level : felt){
    configurator_only();
    let (IM_ : felt) = integration_manager.read();
    let (parameter_issues) = _contract -  0 * address_adapter - 0;
    with_attr error_message("The address of the contract or the adapter is not valid"){
        assert parameter_issues = 0;
    }
    let (drip_manager_) = drip_manager.read();
    let (drip_facade_) = drip_facade.read();
    let (manager_issues) = drip_manager_ - _contract * drip_manager_ - address_adapter;
    let (facades_issues) = drip_facade_ - _contract * drip_facade_ - address_adapter;
    let (drip_issues_) = manager_issues - 0 * facades_issues - 0;
    with_attr error_message("The contract or the adapter is either the drip manager or the drip facade"){
        assert drip_issues_ = 0;
    }
    IIntegrationManager.setAvailableIntegration(IM_, _contract, _address_adapter, _integration, _level);
    return();
}

func setLimits {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(min : Uint256, max : Uint256){
    let (contract_address_) = get_contract_address();
    return();
}

/// @dev Sets fees for creditManager
/// @param _feeInterest Percent which protocol charges additionally for interest rate
/// @param _feeLiquidation Cut for totalValue which should be paid by Liquidator to the pool
/// @param _liquidationPremium Discount for totalValue which becomes premium for liquidator
// function setFees(
//     uint256 _feeInterest,
//     uint256 _feeLiquidation,
//     uint256 _liquidationPremium
// )
//     external
//     configuratorOnly // F:[CC-2]
// {
//     // Checks that feeInterest and (liquidationPremium + feeLiquidation) in range [0..10000]
//     if (
//         _feeInterest >= PERCENTAGE_FACTOR ||
//         (_liquidationPremium + _feeLiquidation) >= PERCENTAGE_FACTOR
//     ) revert IncorrectFeesException(); // FT:[CC-22]

//     _setParams(
//         creditManager.minBorrowedAmount(),
//         creditManager.maxBorrowedAmount(),
//         _feeInterest,
//         _feeLiquidation,
//         PERCENTAGE_FACTOR - _liquidationPremium,
//         creditManager.chiThreshold(),
//         creditManager.hfCheckInterval()
//     ); // FT:[CC-24,25]

//     emit FeesUpdated(_feeInterest, _feeLiquidation, _liquidationPremium); // FT:[CC-25]
// }

// //
// // CONTRACT UPGRADES
// //

// // It upgrades priceOracle which addess is taken from addressProvider
// function upgradePriceOracle()
//     external
//     configuratorOnly // F:[CC-2]
// {
//     address priceOracle = addressProvider.getPriceOracle();
//     creditManager.upgradeContracts(
//         creditManager.creditFacade(),
//         priceOracle
//     ); // F:[CC-27]
//     emit PriceOracleUpgraded(priceOracle); // F:[CC-27]
// }

// // It upgrades creditFacade
// function upgradeCreditFacade(address _creditFacade)
//     external
//     configuratorOnly // F:[CC-2]
// {
//     creditManager.upgradeContracts(
//         _creditFacade,
//         address(creditManager.priceOracle())
//     ); // F:[CC-28]
//     emit CreditFacadeUpgraded(_creditFacade); // F:[CC-28]
// }

// function upgradeConfigurator(address _creditConfigurator)
//     external
//     configuratorOnly // F:[CC-2]
// {
//     creditManager.setConfigurator(_creditConfigurator);
    }