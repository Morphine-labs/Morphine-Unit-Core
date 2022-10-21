%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDripManager {
    
    // Setters 

    func setForbidMask(forbid_mask_: Uint256) {
    }

    func changeContractAllowance(adapter: felt, target: felt) {
    }
    



    // Getters 
    func getPool() -> (pool: felt) {
    }

    func dripConfigurator() -> (configurator: felt) {
    }

    func oracleTransit() -> (oracleTransit: felt){
    }

    func upgradeContracts(drip_transit: felt, oracle_transit: felt){
    }

    func tokenMask(token: felt) -> (token_mask: Uint256){
    }

    func forbidenTokenMask() -> (forbiden_token_mask: Uint256){
    }

    func adapterToContract(adapter: felt) -> (contract: felt){
    }

    func feeInterest() -> (fee_interest: felt){
    }

    func feeLiquidation() -> (fee_liquidation: felt){
    }

    func liquidationDiscount() -> (liquidation_discount: felt){
    }

    func chiThreshold() -> (chi_threshold: felt){
    }
    
    func hfCheckInterval() -> (hf_check_interval: felt){
    }

    func minBorrowedAmount() -> (minimum_borrowed_amount: felt){
    }

    func maxBorrowedAmount() -> (maximum_borrowed_amount: felt){
    }


}


