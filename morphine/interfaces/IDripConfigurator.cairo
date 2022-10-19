%lang starknet

from starkware.cairo.common.uint256 import Uint256


struct AllowedToken {
    address: felt, // Address of token
    liquidation_threshold: Uint256, // LT for token in range 0..1,000,000 which represents 0-100%
}



@contract_interface
namespace IDripConfigurator {

    func initialize(_factory: felt) {
    }

    func cumulative_index_open() -> (cumulative_index_open : Uint256) {
    }

    func since() -> (since : felt) {
    }

    func total_borrowed_amount() -> (total_borrowed : Uint256){
    }

    func connectTo(_drip_manager : felt, _borrowed_amount : Uint256, _cumulative_index : Uint256) {
    }

    func updateParameters(_borrowed_amount: Uint256, _cumulative_index: Uint256) {
    }

    func approveToken(_token: felt,_contract: felt) {
    }

    func cancelAllowance(_token: felt,_contract: felt) {
    }

    func safeTransfer(_token: felt, _to: felt, _amount: Uint256) {
    }

    func execute(
            _to: felt,
            _selector: felt,
            _calldata_len: felt,
            _calldata: felt*) -> (retdata_len: felt, retdata: felt*) {
    }
}






