%lang starknet

from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_block_number,
    call_contract,
)
from starkware.cairo.common.uint256 import ALL_ONES, Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from morphine.utils.safeerc20 import SafeERC20

/// @title referral
/// @author Graff Sacha (0xSacha)
/// @dev referral contract 
/// @custom:experimental This is an experimental contract.


// Events
@event 
func newReferral(referral_address: felt, caller: felt){
}
// External

// @notice: Save refferal
// @param: referral_address referral address
@external
func addReferral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    referral_address: felt
) {
    let (caller_) = get_caller_address();
    newReferral.emit(referral_address, caller_);
    return ();
}
