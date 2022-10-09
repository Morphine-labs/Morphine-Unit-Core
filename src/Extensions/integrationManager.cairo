%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
)

from src.Extensions.IIntegrationManager import IIntegrationManager
from src.IRegistery import IRegistery

struct Integration {
    contract: felt,
    selector: felt,
}

@storage_var
func registery() -> (res: felt) {
}

// # Integration

@storage_var
func available_integrations_length() -> (available_integrations_length: felt) {
}

@storage_var
func id_to_available_integration(id: felt) -> (integration: Integration) {
}

@storage_var
func is_available_integration(integration: Integration) -> (is_available_integration: felt) {
}

@storage_var
func integration_to_prelogic(integration: Integration) -> (prelogic: felt) {
}

@storage_var
func is_integrated_contract(contract: felt) -> (res: felt) {
}

// # Asset

@storage_var
func available_assets_length() -> (available_assets_length: felt) {
}

@storage_var
func id_to_available_asset(id: felt) -> (available_asset: felt) {
}

@storage_var
func is_available_asset(assetAddress: felt) -> (is_asset_available: felt) {
}


//
// Modifiers
//

func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (registery_contract) = registery.read();
    let (owner : felt) = IRegistery.owner(registery_contract);
    let (caller) = get_caller_address();
    with_attr error_message("Ownable: caller is the zero address") {
        assert_not_zero(caller);
    }
    with_attr error_message("Ownable: caller is not the owner") {
        assert owner = caller;
    }
    return ();
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _registery: felt
) {
    registery.write(_registery);
    return ();
}

//
// Getters
//

@view
func isAvailableAsset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    asset: felt
) -> (is_available_asset: felt) {
    let (is_available_asset_) = is_available_asset.read(asset);
    return (is_available_asset_,);
}

@view
func isAvailableIntegration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt
) -> (is_available_integration: felt) {
    let (is_available_integration_) = is_available_integration.read(
        Integration(contract, selector)
    );
    return (is_available_integration_,);
}

@view
func isIntegratedContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt
) -> (is_integrated_contract: felt) {
    let (is_integrated_contract_) = is_integrated_contract.read(contract);
    return (is_integrated_contract_,);
}

@view
func prelogicContract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt
) -> (prelogic: felt) {
    let (prelogic_) = integration_to_prelogic.read(Integration(contract, selector));
    return (prelogic_,);
}

@view
func availableAssets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    available_assets_len: felt, available_assets: felt*
) {
    alloc_locals;
    let (available_assets_len: felt) = available_assets_length.read();
    let (local available_assets: felt*) = alloc();
    complete_available_assets_tab(available_assets_len, available_assets);
    return (available_assets_len, available_assets);
}

@view
func availableIntegrations{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    available_integrations_len: felt, available_integrations: Integration*
) {
    alloc_locals;
    let (available_integrations_len: felt) = available_integrations_length.read();
    let (local available_integrations: Integration*) = alloc();
    complete_available_integrations_tab(available_integrations_len, available_integrations);
    return (available_integrations_len, available_integrations);
}

@view
func numberAvailableAssets{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    available_assets_len: felt
) {
    let (available_assets_len: felt,_) = availableAssets();
    return (available_assets_len,);
}

//
// Setters
//

@external
func setAvailableAsset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    asset: felt
) {
    assert_only_owner();
    let (is_available_asset_: felt) = is_available_asset.read(asset);
    if (is_available_asset_ == 1) {
        return ();
    } else {
        is_available_asset.write(asset, 1);
        let (available_assets_lenght_: felt) = available_assets_length.read();
        id_to_available_asset.write(available_assets_lenght_, asset);
        available_assets_length.write(available_assets_lenght_ + 1);
        return ();
    }
}

@external
func setAvailableIntegration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contract: felt, selector: felt, integration: felt, level: felt
) {
    assert_only_owner();
    let (is_available_integration_: felt) = is_available_integration.read(
        Integration(contract, selector)
    );
    if (is_available_integration_ == 1) {
        return ();
    } else {
        is_integrated_contract.write(contract, 1);
        is_available_integration.write(Integration(contract, selector), 1);
        integration_to_prelogic.write(Integration(contract, selector), integration);
        let (available_integrations_length_: felt) = available_integrations_length.read();
        id_to_available_integration.write(
            available_integrations_length_, Integration(contract, selector)
        );
        available_integrations_length.write(available_integrations_length_ + 1);
        return ();
    }
}

// # Internal
func complete_available_assets_tab{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    available_assets_len: felt, available_assets: felt*
) -> () {
    if (available_assets_len == 0) {
        return ();
    }
    let (asset_: felt) = id_to_available_asset.read(available_assets_len - 1);
    assert available_assets[0] = asset_;
    return complete_available_assets_tab(
        available_assets_len=available_assets_len - 1, available_assets=available_assets + 1
    );
}

func complete_available_integrations_tab{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(available_integrations_len: felt, available_integrations: Integration*) -> () {
    if (available_integrations_len == 0) {
        return ();
    }
    let (integration_: Integration) = id_to_available_integration.read(
        available_integrations_len - 1
    );
    assert available_integrations[0] = integration_;
    return complete_available_integrations_tab(
        available_integrations_len=available_integrations_len - 1,
        available_integrations=available_integrations + Integration.SIZE,
    );
}
