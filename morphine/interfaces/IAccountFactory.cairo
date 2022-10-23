%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAccountFactory {
    func get_stock_len() -> (len: felt) {
    }

    func get_drip_from_address(address: felt) -> (drip: felt) {
    }

    func get_drip_from_id(drip_id: felt) -> (drip: felt) {
    }

    func availableDripAccounts() -> (drip_accounts_len: felt, drip_accounts: felt*) {
    }

    func addDripAccount() -> (address: felt) {
    }

    func removeDripAccount(_borrowed_amount: Uint256, _cumulative_index: Uint256) -> (
        address: felt
    ) {
    }

    func setAvailableDripAccount(address: felt) {
    }

    func removeAvailableDripAccount(address: felt) {
    }
}
