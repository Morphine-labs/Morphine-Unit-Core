%lang starknet

from starkware.cairo.common.uint256 import Uint256


@contract_interface
namespace IOracleTransit {

    func addPrimitive(token: felt, pair_id: felt) {
    }

    func addDerivative(token: felt, derivative_price_feed: felt) {
    }

    func primitivePairId(primitive: felt) -> (pair_id: felt) {
    }

    func isLiquidityToken(token: felt) -> (is_lp: felt) {
    }

    func derivativePriceFeed(derivative: felt) -> (price_feed: felt) {
    }

    func convertFromUSD(amount: Uint256, token: felt) -> (token_price: Uint256) {
    }

    func convertToUSD(amount: Uint256, token: felt) -> (token_price_usd: Uint256) {
    }

    func convert(amount: Uint256, token_from: felt, token_to: felt) -> (amount_to: Uint256) {
    }

}
