%lang starknet

@contract_interface
namespace IAddressregistery {
    func get_governance() -> (governance: felt) {
    }

    func get_tresuary() -> (tresuary: felt) {
    }

    func get_oracle() -> (oracle: felt) {
    }

    func get_pool_hash(pool_name: felt) -> (pool_hash: felt) {
    }

    func get_morphine_pool_hash(pool_hash_class: felt) -> (pool_hash: felt) {
    }

    func set_new_governance_address(new_governance: felt) {
    }

    func set_new_tresuary_address(new_tresuary: felt) {
    }

    func set_oracle(new_oracle: felt) -> () {
    }

    func set_pool_hash(pool_name: felt, new_pool_hash: felt) -> () {
    }

    func set_morphine_pool_hash(pool_hash_class: felt, new_token_address: felt) -> () {
    }
}
