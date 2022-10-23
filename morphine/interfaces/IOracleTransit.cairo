%lang starknet

@contract_interface
namespace IOracleTransit {
    func primitivePairId(primitive: felt) -> (pair_id: felt) {
    }

    func derivativePriceFeed(derivative: felt) -> (price_feed: felt) {
    }
}
