%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Call {
    to: felt,
    selector: felt,
    calldata_len: felt,
    calldata: felt*,
}

// Tmp struct introduced while we wait for Cairo
// to support passing `[AccountCall]` to __execute__
struct AccountCallArray {
    to: felt,
    selector: felt,
    data_offset: felt,
    data_len: felt,
}

struct tokenAndBalance {
    token: felt,
    balance: Uint256,
}

@contract_interface
namespace IDripTransit {


    // 
    // Externals
    //


    // Drip

    func openDrip(_amount: Uint256, _on_belhalf_of: felt, _leverage_factor: Uint256){
    }

    func openDripMultiCall(_borrowed_amount: Uint256, _on_belhalf_of: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
    }

    func closeDrip(_to: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
    }

    func liquidateDrip(_borrower: felt, _to: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
    }

    func liquidateExpiredDrip(_borrower: felt, _to: felt, _call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
    }

    // Drip Management

    func increaseDebt(_amount: Uint256){
    }

    func decreaseDebt(_amount: Uint256){
    }

    func addCollateral(_on_belhalf_of: felt, _token: felt, _amount: Uint256){
    }

    func multicall(_call_array_len: felt, _call_array: AccountCallArray*, _calldata_len: felt, _calldata: felt*){
    }

    func approve(_target: felt, _token: felt, _amount: Uint256){
    }

    func transferDripOwnership(_to: felt){
    }

    func approveDripTransfers(_from: felt, _state: felt){
    }

    // Configurator

    func setIncreaseDebtForbidden(state: felt) {
    }

    func setMaxBorrowedAmountPerBlock(max_borrowed_amount_per_block: Uint256) {
    }

    func setDripLimits(minimum_borrowed_amount: Uint256, maximum_borrowed_amount: Uint256) {
    }

    func setExpirationDate(expiration_date: felt) {
    }


    //
    // Views
    //

    // Dependencies

    func dripManager() -> (drip_manager: felt) {
    }  

    func getNft() -> (nft: felt) {
    }       

    // Expiration

    func isExpired() -> (state: felt) {
    }  

    // Calcul

    func calcTotalValue(_drip: felt) -> (total: Uint256, twv: Uint256){
    }

    func calcDripHealthFactor(_drip: felt) -> (health_factor: Uint256){
    }

    // Control

    func hasOpenedDrip(borrower: felt) -> (state: felt) {
    }  

    func isTokenAllowed(token: felt) -> (state: felt) {
    }  

    // Parameters

    func isIncreaseDebtForbidden() -> (is_increase_debt_forbidden: felt) {
    }
     
    func maxBorrowedAmountPerBlock() -> (max_borrowed_amount_per_block: Uint256) {
    }

    func expirationDate() -> (expiration_date: felt) {
    }

    func isExpirable() -> (state: felt) {
    }   

    func limits() -> (minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256) {
    }         

}
