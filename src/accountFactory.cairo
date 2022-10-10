%lang starknet

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

from starkware.cairo.common.math_cmp import ( 
    is_le,
    is_nn,
    is_not_zero
)

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_lt,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from src.utils.utils import (
    felt_to_uint256,
    uint256_div,
    uint256_percent,
    uint256_mul_low,
    uint256_pow,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.token.erc20.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.pausable.library import Pausable

from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from src.Drip.IDripAccount import IDripAccount

// Storage var

@storage_var
func next_drip_account(address : felt) -> (address : felt) {
}

@storage_var
func head() -> (address: felt) {
}

@storage_var
func tail() -> (address: felt) {
}

@storage_var
func master_credit_account() -> (address : felt) {
}

@storage_var
func contract_register() -> (address: felt) {
}

// Protector

func credit_manager_only {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller_ : felt) = get_caller_address();
    let (manager_ : felt) = master_credit_account.read();
    with_attr error_message("Credit Manager: Only Credit Manager can call this function") {
        assert caller_ = manager_;
    }
    return();
}

// Constructor

func constructor {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address : felt) {
    with_attr error_message("account Factory: Address should be different than 0") {
        assert_not_zero(address);
    }
    let (master_credit : felt) = master_credit_account.read();
    IDripAccount.initialize(master_credit,address);
}