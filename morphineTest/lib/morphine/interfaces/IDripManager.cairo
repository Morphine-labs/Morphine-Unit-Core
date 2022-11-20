%lang starknet

from starkware.cairo.common.uint256 import Uint256

from morphine.interfaces.IDripTransit import Call

@contract_interface
namespace IDripManager {


    //
    // Externals
    //


    // pause

    func pause() {
    }

    func unpause() {
    }

    // Liquidation Emergency

    func checkEmergencyPausable(_caller: felt, _state: felt) -> (state: felt) {
    }

    // Drip

    func openDrip(borrowed_amount: Uint256, on_belhalf_of: felt) -> (drip: felt) {
    }

    func closeDrip(borrower: felt, type: felt, total_value: Uint256, payer: felt, to: felt) -> (remaining_funds: Uint256) {
    }

    // Drip Management

    func addCollateral(payer: felt, drip: felt, token: felt, amount: Uint256) {
    }

    func manageDebt(_borrower: felt, amount: Uint256, increase: felt) -> (newBorrowedAmount: Uint256){
    }

    func approveDrip(borrower: felt, target: felt, token: felt,amount: Uint256) {
    }

    func executeOrder(_borrower: felt, _to: felt, _selector: felt, _calldata_len: felt, _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
    }

    func checkAndEnableToken(_drip: felt, _token: felt){
    }

    func disableToken(drip: felt, token: felt) -> (was_changed: felt) {
    }

    func transferDripOwnership(_from : felt, _to: felt) {
    }

    // Security Check

    func fastCollateralCheck(_drip: felt, _token_in: felt, _token_out: felt, _balance_in_before: Uint256, _balance_out_before: Uint256) {
    }

    func fullCollateralCheck(drip: felt) {
    }

    func checkAndOptimizeEnabledTokens(drip: felt) {
    }

    // Configurator

    func addToken(token: felt) {
    }

    func setFees(fee_interest: Uint256, fee_liqudidation: Uint256, liquidation_discount: Uint256, fee_liqudidation_expired: Uint256, liquidation_discount_expired: Uint256,) {
    }

    func setLiquidationThreshold(token: felt, liquidation_threshold: Uint256) {
    }

    func setForbidMask(forbid_mask_: Uint256) {
    }

    func setMaxEnabledTokens(new_max_enabled_tokens: Uint256) {
    }

    func changeContractAllowance(adapter: felt, target: felt) {
    }

    func upgradeOracleTransit(oracle_transit: felt) {
    }

    func upgradeDripTransit(drip_transit: felt) {
    }

    func setConfigurator(drip_configurator: felt) {
    }

    func addEmergencyLiquidator(liquidator : felt) {
    }
    
    func removeEmergencyLiquidator(liquidator : felt) {
    }


    //
    // Views
    //


    // Pause

    func isPaused() -> (state: felt) {
    }

    // Token

    func underlying() -> (underlying: felt) {
    }

    func allowedTokensLength() -> (tokenLength: felt) {
    }

    func tokenMask(token: felt) -> (token_mask: Uint256) {
    }

    func enabledTokensMap(drip: felt) -> (enabledTokensMap: Uint256) {
    }

    func forbiddenTokenMask() -> (forbiden_token_mask: Uint256) {
    }

    func tokenByMask(_token_mask: Uint256) -> (token: felt) {
    }
    
    func tokenById(_id: felt) -> (token: felt) {
    }

    func liquidationThreshold(token: felt) -> (liquidationThresold: Uint256) {
    }
    
    func liquidationThresholdByMask(_token_mask: Uint256) -> (liquidation_threshold: Uint256) {
    }
    
    func liquidationThresholdById(_id: felt) -> (liquidation_threshold: Uint256) {
    }

    // Contracts

    func adapterToContract(adapter: felt) -> (contract: felt) {
    }

    func contractToAdapter(contract: felt) -> (adapter: felt) {
    }

    // Parameters

    func feeInterest() -> (fee_interest: Uint256) {
    }

    func feeLiquidation() -> (fee_liquidation: Uint256) {
    }

    func feeLiquidationExpired() -> (fee_liqudidation_expired: Uint256) {
    }

    func liquidationDiscount() -> (liquidation_discount: Uint256) {
    }

    func liquidationDiscountExpired() -> (liquidation_discount_expired: Uint256) {
    }

    // Dependencies

    func getPool() -> (pool: felt) {
    }

    func dripTransit() -> (dripTransit: felt) {
    }

    func dripConfigurator() -> (configurator: felt) {
    }

    func oracleTransit() -> (oracleTransit: felt) {
    }

    // Drip

    func getDrip(borrower: felt) -> (drip: felt) {
    }

    func getDripOrRevert(borrower: felt) -> (drip: felt) {
    }

    func dripParameters(drip: felt) -> (borrowedAmount: Uint256, cumulativeIndex: Uint256, currentCumulativeIndex: Uint256) {
    }

    // Calcul

    func calcDripAccruedInterest(_drip: felt) -> (borrowedAmount: Uint256, borrowedAmountWithInterest: Uint256, borrowedAmountWithInterestAndFees: Uint256) {
    }

    func calcClosePayments(_total_value: felt, _type: felt, _borrowed_amount: Uint256, _borrowed_amount_with_interests: Uint256) -> (amount_to_pool: Uint256, remaining_funds: Uint256, profit: Uint256, loss: Uint256) {
    }

}
