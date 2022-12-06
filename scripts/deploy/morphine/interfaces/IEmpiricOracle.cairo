%lang starknet

@contract_interface
namespace IEmpiricOracle {
    func get_spot_median(pair_id: felt) -> (
        price: felt,
        decimals: felt,
        last_updated_timestamp: felt,
        num_sources_aggregated: felt
    ) {
    }
    
    func set_spot_median(
    _pair_id: felt,
    _price: felt, 
    _decimals: felt, 
    _last_updated_timestamp: felt, 
    _num_sources_aggregated: felt) {
    }
}