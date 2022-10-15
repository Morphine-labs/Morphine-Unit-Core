%lang starknet

@contract_interface
namespace IRegistery {
    func governance() -> (governance: felt) {
    }

    func treasury() -> (treasuary: felt) {
    }

    func oracle() -> (oracle: felt) {
    }

    func poolFactory() -> (pool_factory: felt) {
    }

    func dripFactory() -> (drip_factory: felt) {
    }

    func accountFactory() -> (account_factory : felt){
    }

    func owner() -> (owner: felt) {
    }

    func poolHash(pool_hash_class: felt) -> (pool_hash: felt) {
    }

    func dripHash() -> (drip_hash: felt) {
    }

    func dripManager() -> (drip_manager: felt) {
    }


    func integrationManager(pool_hash_class: felt) -> (pool_hash: felt) {
    }

    func setGovernanceAddress(new_governance: felt) {
    }

    func setNewTresuaryAddress(new_tresuary: felt) {
    }

    func setOracle(new_oracle: felt) -> () {
    }

    func setPoolHash(pool_name: felt, new_pool_hash: felt) -> () {
    }

    func setPoolFactory(pool_factory: felt) -> () {
    }

    func setDripFactory(drip_factory: felt) -> () {
    }

    func setMorphinePoolHash(pool_hash_class: felt, new_token_address: felt) -> () {
    }

    func setIntegrationManager(pool_hash_class: felt, new_token_address: felt) -> () {
    }
}
