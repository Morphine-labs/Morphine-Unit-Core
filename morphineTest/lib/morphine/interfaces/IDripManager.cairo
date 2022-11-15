%lang starknet

from starkware.cairo.common.uint256 import Uint256

from morphine.interfaces.IDripTransit import Call

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


    func setFees(
        fee_interest: Uint256,
        fee_liqudidation: Uint256,
        liquidation_discount: Uint256,
        fee_liqudidation_expired: Uint256,
        liquidation_discount_expired: Uint256,) {
    }

    func addCollateral(on_belhalf_of: felt, drip: felt, token: felt, amount: Uint256) {
    }

    func closeDrip(borrower: felt, is_liquidated: felt, total_value: Uint256, payer: felt, to: felt) -> (remaining_funds: Uint256) {
    }

    func openDrip(borrowed_amount: Uint256, on_belhalf_of: felt) -> (drip: felt) {
    }

    func manageDebt(_borrower: felt, amount: Uint256, increase: felt) -> (newBorrowedAmount: Uint256){
    }

    func approveDrip(borrower: felt, target: felt, token: felt,amount: Uint256) {
    }

    func transferDripOwnership(_from : felt, _to: felt) {
    }

    func addEmergencyLiquidator(liquidator : felt) {
    }

    func removeEmergencyLiquidator(liquidator : felt) {
    }

    func checkEmergencyPausable(_caller: felt, _state: felt) -> (state: felt)  {
    }

    func fullCollateralCheck(drip: felt) {
    }

    func checkAndOptimizeEnabledTokens(drip: felt) {
    }

    func disableToken(drip: felt, token: felt) -> (was_changed: felt) {
    }

    func checkAndEnableToken(_drip: felt, _token: felt){
    }

    func updateOwner() {
    }

    // Getters


    func calcDripAccruedInterest(_drip: felt) -> (borrowedAmount: Uint256, borrowedAmountWithInterest: Uint256, borrowedAmountWithInterestAndFees: Uint256) {
    }

    func getPool() -> (pool: felt) {
    }

    func dripTransit() -> (dripTransit: felt) {
    }

    func getDrip(borrower: felt) -> (drip: felt) {
    }

    func allowedTokensLength() -> (allowed_tokens_length: felt) {
    }

    func allowedToken(id: felt) -> (allowedToken: felt) {
    }

    func dripConfigurator() -> (configurator: felt) {
    }

    func oracleTransit() -> (oracleTransit: felt) {
    }

    func enabledTokensMap(drip: felt) -> (enabledTokensMap: Uint256) {
    }

    func upgradeContracts(drip_transit: felt, oracle_transit: felt) {
    }

    func upgradeOracleTransit(oracle_transit: felt) {
    }

    func upgradeDripTransit(drip_transit: felt) {
    }

    func tokenMask(token: felt) -> (token_mask: Uint256) {
    }

    func forbiddenTokenMask() -> (forbiden_token_mask: Uint256) {
    }

    func adapterToContract(adapter: felt) -> (contract: felt) {
    }

    func contractToAdapter(contract: felt) -> (adapter: felt) {
    }

    func feeInterest() -> (fee_interest: Uint256) {
    }

    func feeLiquidation() -> (fee_liquidation: Uint256) {
    }

    func liquidationDiscount() -> (liquidation_discount: Uint256) {
    }

    func minBorrowedAmount() -> (minimum_borrowed_amount: Uint256) {
    }

    func maxBorrowedAmount() -> (maximum_borrowed_amount: Uint256) {
    }

    func liquidationThreshold(token: felt) -> (liquidationThresold: Uint256) {
    }

    
    func liquidationThresholdByMask(_token_mask: Uint256) -> (liquidation_threshold: Uint256) {
    }
    
    func liquidationThresholdById(_id: felt) -> (liquidation_threshold: Uint256) {
    }
    
    func tokenByMask(_token_mask: Uint256) -> (token: felt) {
    }
    
    func tokenById(_id: felt) -> (token: felt) {
    }

    func underlying() -> (underlying: felt) {
    }

    func getDripOrRevert(borrower: felt) -> (drip: felt) {
    }
}
