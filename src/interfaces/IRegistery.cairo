%lang starknet

@contract_interface
namespace IRegistery {
    func getGovernance() -> (governance: felt) {
    }

    func getTreasury() -> (treasuary: felt) {
    }

    func getOracle() -> (oracle: felt) {
    }

    func getPoolHash() -> (pool_hash: felt) {
    }

    func getPoolFactory() -> (pool_hash: felt) {
    }

    func getMorphinePoolHash(pool_hash_class: felt) -> (pool_hash: felt) {
    }

    func setGovernanceAddress(new_governance: felt) {
    }

    func setNewTresuaryAddress(new_tresuary: felt) {
    }

    func setOracle(new_oracle: felt) -> () {
    }

    func setPoolHash(pool_name: felt, new_pool_hash: felt) -> () {
    }

    func setMorphinePoolHash(pool_hash_class: felt, new_token_address: felt) -> () {
    }
}
