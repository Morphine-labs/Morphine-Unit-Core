%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IOracleTransit {
    func primitivePairId(primitive: felt) -> (pair_id: felt) {
    }

    func derivativePriceFeed(derivative: felt) -> (price_feed: felt) {
    }

    func convertFromUSD(amount: Uint256, token: felt) -> (Uint256: felt) {
    }

    func convertToUSD(amount: Uint256, token: felt) -> (token_price_usd: Uint256) {
    }
}
