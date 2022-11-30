%lang starknet

@contract_interface
namespace IRegistery {

    func owner() -> (owner: felt) {
    }

    func getTreasury() -> (treasuary: felt) {
    }

    func dripFactory() -> (drip_factory: felt) {
    }

    func dripHash() -> (drip_hash: felt) {
    }

    func oracleTransit() -> (oracle: felt) {
    }

    
    func isPool(_pool: felt) -> (state : felt) {
    }


    func isDripManager(_drip_manager: felt) -> (state : felt) {
    }
    
    
    func idToPool(_id: felt) -> (pool : felt) {
    }
    
    
    func idToDripManager(_id: felt) -> (dripManager : felt) {
    }
    
    
    func poolsLength() -> (poolsLength : felt) {
    }
    
    
    func dripManagerLength() -> (dripManagerLength : felt) {
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

    func addPool(_pool : felt) -> () {
    }

    func addDripManager(_drip_manager : felt) -> () {
    }
}
