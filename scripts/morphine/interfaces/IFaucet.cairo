%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFaucet {

    func get_token_address() -> (res: felt) {
    }

    func isAllowedForTransaction(address: felt) -> (success: felt) {
    }

    func get_allowed_time(account: felt) -> (res: felt) {
    }
}
