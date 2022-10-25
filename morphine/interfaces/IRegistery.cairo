%lang starknet

@contract_interface
namespace IRegistery {

    func owner() -> (governance: felt) {
    }

    func getTreasury() -> (treasuary: felt) {
    }

    func dripFactory() -> (drip_factory: felt) {
    }

    func dripHash() -> (drip_hash: felt) {
    }

    func oracleTransit() -> (oracle: felt) {
    }

    // setters

    func setTreasury(new_tresuary: felt) {
    }

    func setOwner(new_owner: felt) {
    }

    func setOracleTransit(new_oracle_transit: felt) -> () {
    }

    func setDripHash(new_drip_hash: felt) -> () {
    }

    func setDripFactory(new_drip_factory: felt) -> () {
    }

}
