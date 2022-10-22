%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDripManager {
    
    // Setters 

    func setForbidMask(forbid_mask_: Uint256) {
    }

    func changeContractAllowance(adapter: felt, target: felt) {
    }

    func setDripConfigurator(drip_configurator: felt) {
    }

    func setIncreaseDebtForbidden(state: felt) {
    }

    func setLiquidationThreshold(token: felt, liquidation_threshold: Uint256) {
    }

    func addToken(token: felt) {
    }

    func setParameters(minimum_borrowed_amount: Uint256, maximum_borrowed_amount: Uint256, fee_interest: Uint256,  fee_liqudidation: Uint256, liquidation_discount: Uint256, chi_threshold: Uint256, hf_check_interval: Uint256){
    }

    // Getters 
    func getPool() -> (pool: felt) {
    }

    func allowedTokensLength() -> (allowed_tokens_length: felt) {
    }

    func allowedToken(id: felt) -> (allowedToken: felt) {
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

    func feeInterest() -> (fee_interest: Uint256){
    }

    func feeLiquidation() -> (fee_liquidation: Uint256){
    }

    func liquidationDiscount() -> (liquidation_discount: Uint256){
    }

    func chiThreshold() -> (chi_threshold: Uint256){
    }
    
    func hfCheckInterval() -> (hf_check_interval: Uint256){
    }

    func minBorrowedAmount() -> (minimum_borrowed_amount: Uint256){
    }

    func maxBorrowedAmount() -> (maximum_borrowed_amount: Uint256){
    }

    func liquidationThreshold(token: felt) -> (liquidationThresold: Uint256){
    }


}


