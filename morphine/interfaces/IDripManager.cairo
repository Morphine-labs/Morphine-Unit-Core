%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IDripManager {
   func pool(drip_manager : felt) -> (pool : felt){
   }

   func dripConfigurator() -> (drip_configurator : felt){
   } 
}