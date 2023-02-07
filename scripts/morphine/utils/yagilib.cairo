// SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import ALL_ONES, Uint256, uint256_check, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.token.erc20.library import ERC20, ERC20_allowances
from openzeppelin.security.safemath.library import SafeUint256

from morphine.utils.fixedpointmathlib import mul_div_up, mul_div_down

// @title Generic ERC4626 vault
// @description An ERC4626-style vault implementation.
//              Adapted from the solmate implementation: https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol
// @author Peteris <github.com/Pet3ris>

//
// EVENTS
//

@event
func Deposit(from_: felt, to: felt, amount: Uint256, shares: Uint256) {
}

@event
func Withdraw(from_: felt, to: felt, amount: Uint256, shares: Uint256) {
}

//
// STORAGE
//

@storage_var
func ERC4626_asset() -> (asset: felt) {
}

namespace ERC4626 {
    //
    // CONSTRUCTOR
    //

    // @notice: Initializer
    // @param: asset asset contract_address
    // @param: name asset name
    // @param: symbol
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        asset: felt, name: felt, symbol: felt
    ) {
        alloc_locals;
        let (decimals) = IERC20.decimals(contract_address=asset);
        ERC20.initializer(name, symbol, decimals);
        ERC4626_asset.write(asset);
        return ();
    }

    //
    // MAX ACTIONS
    //

    // @notice: max deposit
    // @notice: to address to (why it is here :-) )
    // @return: max asset Biggest uint possible in cairo(Uint256)
    func max_deposit(to: felt) -> (max_assets: Uint256) {
        return (Uint256(ALL_ONES, ALL_ONES),);
    }

    // @notice: max mint
    // @notice: to address to (why it is here :-) )
    // @return: max shares Biggest uint possible in cairo(Uint256)
    func max_mint(to: felt) -> (max_shares: Uint256) {
        return (Uint256(ALL_ONES, ALL_ONES),);
    }

    // @notice: max redeem
    // @notice: caller the function caller
    // @return: max shares balance from caller
    func max_redeem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        caller: felt
    ) -> (max_shares: Uint256) {
        let (balance) = ERC20.balance_of(caller);
        return (balance,);
    }

    //
    // INTERNAL
    //

    // @notice: decrease allowance
    // @param: owner the fund owner
    // @param: spender the spender authorized by the owner
    // @param: subtracted_value the allowance reduction wanted by the owner
    func ERC20_decrease_allowance_manual{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(owner: felt, spender: felt, subtracted_value: Uint256) -> () {
        alloc_locals;

        // This is vault logic, we place it here to avoid revoked references at callsite
        if (spender == owner) {
            return ();
        }

        // This is decrease_allowance, but edited
        with_attr error_message("ERC20: subtracted_value is not a valid Uint256") {
            uint256_check(subtracted_value);
        }

        let (current_allowance: Uint256) = ERC20_allowances.read(owner=owner, spender=spender);

        with_attr error_message("ERC20: allowance below zero") {
            let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, subtracted_value);
        }

        ERC20._approve(owner, spender, new_allowance);
        return ();
    }
}