// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (token/erc721/IERC721.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMinter {

    func isWhitelisted(_user: felt) -> (state: felt) {
    }

    func hasMinted(_user: felt) -> (state: felt) {
    }

    func nftContract() -> (nftContract: felt) {
    }

    func mint() {
    }

    func setWhitelist(address_len: felt, address: felt*) {
    }

}
