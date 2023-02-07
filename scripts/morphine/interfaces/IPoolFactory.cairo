%lang starknet

struct PoolFactory {
    id: felt,
    address: felt,
    name: felt,
    symbol: felt,
    asset: felt,
}

@contract_interface
namespace IPoolFactory {
    func get_nb_pool() -> (pool_len: felt) {
    }

    func get_name(address: felt) -> (name: felt) {
    }

    func get_symbol(address: felt) -> (symbol: felt) {
    }

    func get_asset(address: felt) -> (asset: felt) {
    }

    func get_address_from_contract_class(contract_class_hash: felt) -> (address: felt) {
    }

    func get_pool_by_id(pool_id: felt) -> (pool_name: felt, pool_symbol: felt, pool_asset: felt) {
    }

    func get_pool_factory_by_id(pool_id: felt) -> (pool: PoolFactory) {
    }

    func availablePools() -> (available_pools_len: felt, available_pools: felt*) {
    }

    func isAvailableAsset(asset: felt) -> (is_available_asset: felt) {
    }

    func addPool(_address_registery: felt, _asset: felt, _name: felt, _symbol: felt) {
    }
}
