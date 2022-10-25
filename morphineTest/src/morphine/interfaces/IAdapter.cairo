%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IAdapter {
    func dripManager() -> (drip_manager: felt) {
    }
}
