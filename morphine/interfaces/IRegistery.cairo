%lang starknet

@contract_interface
namespace IRegistery {

    func owner() -> (governance: felt) {
    }

    func allowedTokensLength() -> (allowed_tokens_length: felt) {
    }

    func getTreasury() -> (treasuary: felt) {
    }

    func poolFactory() -> (pool_factory: felt) {
    }

    func dripFactory() -> (drip_factory: felt) {
    }

    func dripConfig() -> (drip_config: felt) {
    }

    func accountFactory() -> (account_factory : felt){
    }

    func poolHash(pool_hash_class: felt) -> (pool_hash: felt) {
    }

    func dripHash() -> (drip_hash: felt) {
    }

    func dripManager() -> (drip_manager: felt) {
    }

    func dripTransit() -> (drip_transit: felt) {
    }

    func oracleTransit() -> (oracle: felt) {
    }

    


    // setters

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
