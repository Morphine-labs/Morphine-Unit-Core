// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Integration {
    contract: felt,
    selector: felt,
}

@contract_interface
namespace IIntegrationManager {
    // Setters
    func setAvailableAsset(_asset: felt) {
    }

    func setAvailableIntegration(
        _contract: felt, _selector: felt, _integration: felt, _level: felt
    ) {
    }

    // #Getters

    func isIntegratedContract(contract: felt) -> (is_integrated_contract: felt) {
    }

    func isAvailableAsset(asset: felt) -> (res: felt) {
    }

    func isAvailableIntegration(contract: felt, selector: felt) -> (res: felt) {
    }

    func prelogicContract(contract: felt, selector: felt) -> (prelogic: felt) {
    }

    func availableAssets() -> (available_assets_len: felt, available_assets: felt*) {
    }

    func numberAvailableAssets() -> (number_available_assets: felt) {
    }

    func availableIntegrations() -> (
        available_integrations_len: felt, available_integrations: Integration*
    ) {
    }
}
