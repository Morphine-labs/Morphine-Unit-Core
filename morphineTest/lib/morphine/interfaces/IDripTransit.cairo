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

@contract_interface
namespace IDripTransit {
    // setters

    func setContractToAdapter(contract: felt, adapter: felt) {
    }

    func setMaxBorrowedAmountPerBlock(max_borrowed_amount_per_block: Uint256) {
    }

    func setDripLimits(minimum_borrowed_amount: Uint256, maximum_borrowed_amount: Uint256) {
    }

    func setExpirationDate(expiration_date: felt) {
    }

    func setIncreaseDebtForbidden(state: felt) {
    }



    // getters

    func dripManager() -> (drip_manager: felt) {
    }       

    func maxBorrowedAmountPerBlock() -> (max_borrowed_amount_per_block: Uint256) {
    }

    func isIncreaseDebtForbidden() -> (is_increase_debt_forbidden: felt) {
    }

    func expirationDate() -> (expiration_date: felt) {
    }

    func isExpirable() -> (state: felt) {
    }   

    func limits() -> (minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256) {
    }         


}
