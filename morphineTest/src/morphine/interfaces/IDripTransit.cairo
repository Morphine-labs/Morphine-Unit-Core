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

    // getters

    func contractToAdapter(contract: felt) -> (adapter: felt) {
    }
}
