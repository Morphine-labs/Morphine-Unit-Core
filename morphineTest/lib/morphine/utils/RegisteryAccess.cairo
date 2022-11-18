// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (access/ownable/library.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from morphine.interfaces.IRegistery import IRegistery


//
// Storage
//

@storage_var
func registery_contract() -> (registery: felt) {
}

namespace RegisteryAccess {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_registery: felt) {
        registery_contract.write(_registery);
        return ();
    }

    //
    // Guards
    //

    func assert_only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (registery_) = registery_contract.read();
        let (owner_) = IRegistery.owner(registery_);
        let (caller_) = get_caller_address();
        with_attr error_message("Ownable: caller is the zero address") {
            assert_not_zero(caller_);
        }
        with_attr error_message("Ownable: caller is not the owner") {
            assert owner_ = caller_;
        }
        return ();
    }

    //
    // Public
    //

    func registery{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
        let (registery_) = registery_contract.read();
        return (registery_,);
    }
}
