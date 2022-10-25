%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDripFactory {
    func nextDrip(_drip: felt) -> (drip: felt) {
    }

    func dripLength() -> (dripLength: felt) {
    }

    func idToDrip(_id: felt) -> (drip: felt) {
    }

    func dripToId(_drip: felt) -> (id: felt) {
    }

    func isDrip(_drip: felt) -> (state: felt) {
    }

    func dripStockLength() -> (length: felt) {
    }

    func addDrip() {
    }

    func takeDrip(_borrowed_amount: Uint256, _cumulative_index: Uint256) -> (address: felt) {
    }

    func returnDrip(_used_drip: felt) {
    }

    func takeOut(_prev: felt, _drip: felt, _to: felt) {
    }
}
