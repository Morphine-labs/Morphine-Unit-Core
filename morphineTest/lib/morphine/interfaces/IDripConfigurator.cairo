%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct AllowedToken {
    address: felt,  // Address of token
    liquidation_threshold: Uint256,  // LT for token in range 0..1,000,000 which represents 0-100%
}

@contract_interface
namespace IDripConfigurator {

    // Setters
    func addTokenToAllowedList(_token: felt){
    }

    func setLiquidationThreshold(_token: felt, _liquidation_threshold: Uint256){
    }

    func allowToken(_token: felt){
    }

    func forbidToken(_token: felt){
    }

    func allowContract(_contract: felt, _adapter: felt){
    }

    func forbidContract(_contract: felt){
    }

    func setLimits(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256){
    }

    func setFastCheckParameters(_chi_threshold: Uint256, _hf_check_interval: Uint256){
    }

    func setFees(_fee_interest: Uint256, _fee_liquidation: Uint256, _liquidation_premium: Uint256){
    }

    func upgradeOracleTransit(){
    }

    func upgradeDripTransit(_drip_transit: felt){
    }

    func upgradeConfigurator(_drip_configurator: felt){
    }

    func setIncreaseDebtForbidden(_state: felt){
    }

    // Getters

    func idToAllowedContract(id: felt) -> (allowedContract: felt){
    }

    func allowedContractsLength(id: felt) -> (allowedContractsLength: felt){
    }

    func allowedContractToId(_allowed_contract: felt) -> (id: felt){
    }

    func isAllowedContract(_contract: felt) -> (state: felt){
    }
}
