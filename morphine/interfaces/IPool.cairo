%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPool {
    func pause() {
    }

    func unpause() {
    }

    func freezeBorrow() {
    }

    func unfreezeBorrow() {
    }

    func setWithdrawFee(_base_withdraw_fee: Uint256) {
    }

    func setExpectedLiquidityLimit(_expected_liquidity_limit: Uint256) {
    }

    func deposit(_assets: Uint256, _receiver: felt) -> (shares: Uint256) {
    }

    func mint(_shares: Uint256, _receiver: felt) -> (assets: Uint256) {
    }

    func withdraw(_assets: Uint256, _receiver: felt, _owner: felt) -> (shares: Uint256) {
    }

    func redeem(_shares: Uint256, _receiver: felt, _owner: felt) -> (assets: Uint256) {
    }

    func borrow(_borrow_amount: Uint256) {
    }

    func repayDebt(_repay_amount: Uint256) {
    }

    func getRegistery() -> (registery: felt) {
    }

    func asset() -> (asset: felt) {
    }

    func treasury() -> (treasury: felt) {
    }

    func factory() -> (factory: felt) {
    }

    func maxDeposit(_to: felt) -> (maxAssets: Uint256) {
    }

    func maxMint(_to: felt) -> (maxShares: Uint256) {
    }

    func maxWithdraw(_from: felt) -> (maxAssets: Uint256) {
    }

    func maxRedeem(caller: felt) -> (maxShares: Uint256) {
    }

    func previewDeposit(_assets: Uint256) -> (shares: Uint256) {
    }

    func previewMint(_shares: Uint256) -> (assets: Uint256) {
    }

    func previewWithdraw(_assets: Uint256) -> (shares: Uint256) {
    }

    func previewRedeem(_shares: Uint256) -> (assets: Uint256) {
    }

    func calculLinearCumulativeIndex() -> (cumulativeIndex: Uint256) {
    }

    func convertToShares(_assets: Uint256) -> (shares: Uint256) {
    }

    func convertToAssets(_shares: Uint256) -> (assets: Uint256) {
    }

    func totalAssets() -> (totalManagedAssets: Uint256) {
    }

    func totalBorrowed() -> (totalBorrowed: Uint256) {
    }

    func borrowRate() -> (borrowRate: Uint256) {
    }

    func lastUpdatedTimestamp() -> (lastUpdatedTimestamp: felt) {
    }

    func expectedLiquidityLastUpdate() -> (expectedLiquidityLastUpdate: Uint256) {
    }

    func expectedLiquidityLimit() -> (lastUpdatedTimestamp: Uint256) {
    }

    func availableLiquidity() -> (availableLiquidity: Uint256) {
    }

    func calculBorrowRate() -> (borrowRate: Uint256) {
    }

    func withdrawFee() -> (withdrawFee: Uint256) {
    }

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func decimals() -> (decimals: felt) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(_owner: felt, _spender: felt) -> (remaining: Uint256) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(_spender: felt, amount: Uint256) -> (success: felt) {
    }

    func increaseAllowance(_spender: felt, added_value: Uint256) -> (success: felt) {
    }

    func decreaseAllowance(_spender: felt, subtracted_value: Uint256) -> (success: felt) {
    }
}
