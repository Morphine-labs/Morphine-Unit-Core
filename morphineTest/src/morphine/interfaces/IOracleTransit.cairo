%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IOracleTransit {
    func primitivePairId(primitive: felt) -> (pair_id: felt) {
    }

    func fastCheck(amount_from: Uint256, token_from: felt, amount_to: Uint256, token_to: felt) -> (collateralFrom: Uint256, collateralTo: Uint256) {
    }

    func derivativePriceFeed(derivative: felt) -> (price_feed: felt) {
    }

    func convertFromUSD(amount: Uint256, token: felt) -> (token_price: Uint256) {
    }

    func convertToUSD(amount: Uint256, token: felt) -> (token_price_usd: Uint256) {
    }
}
