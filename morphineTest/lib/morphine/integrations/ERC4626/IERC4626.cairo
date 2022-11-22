// SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IYearnV2Like {

    //
    // HOLDINGS
    //

    func asset() -> (assetTokenAddress: felt) {
    }

    func totalAssets() -> (totalManagedAssets: Uint256) {
    }

    func convertToShares(assets: Uint256) -> (shares: Uint256) {
    }

    func convertToAssets(shares: felt) -> (assets: Uint256) {
    }

    //
    // DEPOSIT
    //

    func maxDeposit(to: felt) -> (maxAssets: Uint256) {
    }

    func previewDeposit(assets: Uint256) -> (shares: Uint256) {
    }

    func deposit(assets: Uint256, receiver: felt) -> (shares: Uint256) {
    }

    //
    // MINT
    //

    func maxMint(to: felt) -> (maxShares: Uint256) {
    }

    func previewMint(shares: Uint256) -> (assets: Uint256) {
    }

    func mint(shares: Uint256, receiver: felt) -> (assets: Uint256) {
    }

    //
    // WITHDRAW
    //

    func maxWithdraw(from_: felt) -> (maxAssets: Uint256) {
    }

    func previewWithdraw(assets: Uint256) -> (shares: Uint256) {
    }

    func withdraw(assets: Uint256, receiver: felt, owner: felt) -> (shares: Uint256) {
    }

    //
    // REDEEM
    //

    func maxRedeem(caller: felt) -> (maxShares: Uint256) {
    }

    func previewRedeem(shares: Uint256) -> (assets: Uint256) {
    }

    func redeem(shares: Uint256, receiver: felt, owner: felt) -> (assets: Uint256) {
    }
}