%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Call {
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
