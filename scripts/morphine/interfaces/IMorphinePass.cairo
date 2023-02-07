// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (token/erc721/IERC721.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMorphinePass {
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func baseURI() -> (baseURI: felt) {
    }

    func tokenByIndex(index: Uint256) -> (tokenId: Uint256) {
    }

    func tokenOfOwnerByIndex(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    }

    func setMinter(_minter: felt) {
    }

    func addDripTransit(_drip_transit: felt) {
    }

    func removeDripTransit(_drip_transit: felt) {
    }

    func mint(to: felt, amount: Uint256) {
    }

    func burn(_from: felt, amount: Uint256) {
    }

    func setBaseURI(baseURI: felt) {
    }

    func updateOwner() {
    }

}
