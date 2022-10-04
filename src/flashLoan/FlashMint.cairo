%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import ( get_caller_address, get_contract_address)

from contracts.interfaces.IERC3156FlashLender import IERC3156FlashLender

from contracts.interfaces.IERC3156FlashBorrower import IERC3156FlashBorrower

from openzeppelin.token.erc20.IERC20 import IERC20

from openzeppelin.security.safemath.library import SafeUint256

from openzeppelin.access.ownable.library import Ownable

@storage_var
func contract() -> (address: felt) {
}

@constructor
func constructor {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_owner : felt){
    Ownable.initializer(_owner);
    return();
}

@external
func FlashMint {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_to_snipe : felt , pool_address: felt, amount : Uint256 ) -> (bool : felt){

    // Aim of this function for the Team just be able to flash loan some token launch no fees only benefit
    // TODO : Flash Loan USDC pool or ETH pool (because they are the most common pair when a token launch)
    //      Swap USDC or ETH for new token price will go up beacuse offer go up 
    //      Sell it back for USDC or ETH
    //      Pay back the flash loan 
    //      If you manage to make some money keep the rest either transaction will revert
    return(bool=1);
}