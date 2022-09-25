# SPDX-License-Identifier: AGPL-3.0-or-later

%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.uint256 import ALL_ONES, Uint256, uint256_check, uint256_eq, uint256_lt, uint256_eq

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.token.erc20.IERC20 import IERC20

from utils.fixedpointmathlib import mul_div_down,
from utils.safeerc20 import SafeERC20
from utils.various import mul_permillion, PRECISION

from starkware.starknet.common.syscalls import (
    get_block_number,
    get_block_timestamp,
)

// Events

@event
func Deposit(from_: felt, to: felt, amount: Uint256, shares: Uint256):
end

@event
func Withdraw(from_: felt, to: felt, amount: Uint256, shares: Uint256):
end




// Storage

@storage_var
func address_registery() -> (res : felt):
end

@storage_var
func ERC4626_asset() -> (asset: felt):
end

@storage_var
func optimal_liquidity_utilization() -> (res : felt):
end

@storage_var
func base_rate() -> (res : Uint256):
end

@storage_var
func slop1() -> (res : Uint256):
end

@storage_var
func slop2() -> (res : Uint256):
end

@storage_var
func expected_liquidity() -> (res : Uint256):
end

@storage_var
func expected_liquidity_limit() -> (res : Uint256):
end

@storage_var
func total_borrowed() -> (res : Uint256):
end

@storage_var
func cumulative_index() -> (res : Uint256):
end

@storage_var
func borrow_rate() -> (res : Uint256):
end

@storage_var
func withdraw_fee() -> (res : Uint256):
end

@storage_var
func last_updated_timestamp() -> (res : felt):
end

const SECONDS_PER_YEAR = 31536000;

// Constructor


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _address_registery: felt,
        _asset : felt,
        _name : felt,
        _symbol : felt,
        _expected_liquidity_limit: Uint256,
        _optimal_liquidity_utilization: Uint256,
        _base_rate: Uint256,
        _slop1: Uint256,
        _slop2: Uint256,
        ):

        with_attr error_message("Zero address not allowed"):
            assert_not_zero(_address_registery);
        end

        with_attr error_message("Parameter lower than 1.000.000"):
            assert_le(optimal_liquidity_utilization, PRECISION);
        end

        with_attr error_message("Parameter must be lower than 1.000.000"):
            assert_le(base_rate, PRECISION);
        end

        with_attr error_message("Parameter must be lower than 1.000.000"):
            assert_le(slop1, PRECISION);
        end

        with_attr error_message("Parameter must be lower than 1.000.000"):
            assert_le(slop2, PRECISION);
        end

        let (decimals) = IERC20.decimals(contract_address=asset)
        ERC20.initializer(name, symbol, decimals)
        ERC4626_asset.write(asset)

        address_registery.write(_address_registery);
        ERC4626.initializer(asset, name, symbol)
        optimal_liquidity_utilization.write(_optimal_liquidity_utilization);
        base_rate.write(_base_rate);
        slop1.write(_slop1);
        slop2.write(_slop2);
    return ()
end


// Actions


// Operator stuff

@external
func setWithdrawFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_withdraw_fee: Uint256) {
    let (is_allowed_amount1_) = uint256_lt(_withdraw_fee, Uint256(PRECISION,0));
    let (is_allowed_amount2_) = uint256_lt(Uint256(0,0), _withdraw_fee);
    with_attr error_message("0 <= withdrawFee <= 1.000.000"){
        assert is_allowed_amount1_ * is_allowed_amount2_ = 1;
    }
    withdraw_fee.write(_withdraw_fee);
}

@external
func freezeBorrow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_withdraw_fee: Uint256) {

}

// Lender stuff

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _assets : Uint256, _receiver : felt) -> (shares : Uint256){
    alloc_locals

    let (shares_) = previewDeposit(_assets)
    with_attr error_message("ERC4626: cannot deposit for 0 shares"):
        let (shares_is_zero) = uint256_eq(shares_, Uint256(0, 0));
        assert shares_is_zero = FALSE;
    end

    let (max_deposit_) = maxDeposit(_receiver)
    with_attr error_message("amount exceeds max deposit "):
        assert_le(_assets, max_deposit_)
    end

    with_attr error_message("Zero address not allowed"):
        assert_not_zero(_receiver)
    end

    let (asset_) = ERC4626_asset.read();
    let (caller_) = get_caller_address();
    let (this_) = get_contract_address();
    SafeERC20.transferFrom(asset_, caller_, this_, _assets);
    ERC20._mint(_receiver, shares_);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = uint256_add(expected_liquidity_, _assets);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0,0));

    Deposit.emit(caller_, _receiver, _assets, shares_)
    return ();
}


@external
func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _shares : Uint256, _receiver : felt) -> (assets : Uint256){
    alloc_locals;
    let (assets_) = previewMint(_shares);

    with_attr error_message("ERC4626: cannot mint for 0 assets"):
        let (assets_is_zero_) = uint256_eq(assets_, Uint256(0, 0));
        assert assets_is_zero_ = FALSE;
    end

    let (max_mint_) = maxMint(_receiver);
    with_attr error_message("amount exceeds max mint"){
        assert_le(_shares, max_mint_);
    }

    with_attr error_message("Zero address not allowed"):
        assert_not_zero(_receiver);
    end

    let (asset_) = ERC4626_asset.read();
    let (caller_) = get_caller_address();
    let (this_) = get_contract_address();
    SafeERC20.transferFrom(asset_, caller_, this_, assets_);
    ERC20._mint(_receiver, _shares);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = uint256_add(expected_liquidity_, assets_);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0,0));

    Deposit.emit(caller_, _receiver, assets_, _shares);
    return (assets_);
}


@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _assets : Uint256, _receiver : felt, _owner : felt) -> (shares : Uint256){
    alloc_locals;
    let (shares_) = convertToShares(_assets);
    let (withdraw_fee_) = withdraw_fee.read();
    let (treasury_fee_) = mul_permillion(_assets, withdraw_fee_);
    let (remaining_assets_) = uint256_sub(_assets, treasury_fee_);
    let (treasury_) = treasury();

    with_attr error_message("ERC4626: cannot withdraw for 0 shares"):
        let (shares_is_zero) = uint256_eq(shares_, Uint256(0, 0));
        assert shares_is_zero = FALSE;
    end

    let (max_withdraw_) = maxWithdraw(_receiver);

    with_attr error_message("amount exceeds max withdraw"){
        assert_le(_assets, max_withdraw_);
    }

    with_attr error_message("Zero address not allowed"):
        assert_not_zero(_receiver * _owner);
    end


    let (caller_) = get_caller_address();
    ERC20_decrease_allowance_manual(_owner, caller_, shares_);
    ERC20._burn(_owner, shares_);

    let (ERC4626_asset_) = ERC4626_asset.read();
    SafeERC20.transfer(ERC4626_asset_, _receiver, remaining_assets_);
    SafeERC20.transfer(ERC4626_asset_, treasury_, treasury_fee_);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = uint256_sub(expected_liquidity_, _assets);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0,0));

    Withdraw.emit(_owner, _receiver, _assets, shares_);
    return (shares);
}

@external
func redeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _shares : Uint256, _receiver : felt, owner : felt) -> (assets : Uint256){
    alloc_locals;

    let (assets_) = convertToAssets(_shares);
    let (withdraw_fee_) = withdraw_fee.read();
    let (treasury_fee_) = mul_permillion(_assets, withdraw_fee_);
    let (remaining_assets_) = uint256_sub(_assets, treasury_fee_);
    let (treasury_) = treasury();

    with_attr error_message("ERC4626: cannot reedem for 0 assets"):
        let (shares_is_zero) = uint256_eq(shares_, Uint256(0, 0));
        assert shares_is_zero = FALSE;
    end

    let (max_reedem_) = maxRedeem(_receiver);

    with_attr error_message("amount exceeds max withdraw"){
        assert_le(_shares, max_reedem_);
    }

    with_attr error_message("Zero address not allowed"):
        assert_not_zero(_receiver * _owner);
    end

    let (caller_) = get_caller_address();
    ERC20_decrease_allowance_manual(_owner, caller_, _shares);
    ERC20._burn(_owner, _shares);

    let (ERC4626_asset_) = ERC4626_asset.read();
    SafeERC20.transfer(ERC4626_asset_, _receiver, remaining_assets_);
    SafeERC20.transfer(ERC4626_asset_, treasury_, treasury_fee_);

    let (expected_liquidity_) = expected_liquidity.read();
    let (new_expected_liqudity_) = uint256_sub(expected_liquidity_, assets_);
    expected_liquidity.write(new_expected_liqudity_);
    update_borrow_rate(Uint256(0,0));

    Withdraw.emit(_owner, _receiver, assets_, _shares);
    return (assets_);
}


// Borrower stuff




//
// VIEW
//

@view
func asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (asset : felt):
    return ERC4626_asset.read()
end

@view
func treasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (treasury : felt):
    let (address_registery_) = address_registery.read();
    let (treasury_) = IAddressRegistery.treasury(address_registery_);
    return (treasury_)
end

@view
func maxDeposit(to: felt) -> (maxAssets : Uint256):
    let (expected_liquidity_) = expected_liquidity.read();
    let (expected_liquidity_limit_) = expected_liquidity_limit.read();
    let (max_deposit_) = uint256_sub(expected_liquidity_limit_, expected_liquidity_)
    return (max_deposit_)
end

@view
func maxMint(to: felt) -> (maxShares : Uint256):
    let (max_deposit_) = maxDeposit()
    let (max_mint_) = convertToShares(max_deposit_)
    return (max_mint)
end

@view
func maxWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_from : felt) -> (maxAssets : Uint256):
    let (balance_) = ERC20.balance_of(from_);
    let (max_assets_) = convertToAssets(balance_);
    let (available_liquidity_) = availableLiquidity();
    let (is_enough_liquidity_) = uint256_lt(max_assets, available_liquidity_);
    if(is_enough_liquidity_ == 1){
        return(max_assets_);
    else{
        return(available_liquidity_);
        }
end

@view
func maxRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt) -> (maxShares : Uint256):
    let (max_assets_) = maxWithdraw(caller)
    let (max_reedem_) = convertToShares(max_assets_)
    return (max_reedem_)
end
 

@view
func previewDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _assets : Uint256) -> (shares : Uint256):
    return convertToShares(assets);
end


@view
func previewMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _shares : Uint256) -> (assets : Uint256):
    return convertToAssets(_shares);
end


@view
func previewWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets : Uint256) -> (shares : Uint256):
    alloc_locals
    let (withdraw_fee_) = withdraw_fee.read();
    let (treasury_fee_) = mul_permillion(_assets, withdraw_fee_);
    let (remaining_assets_) = uint256_sub(_assets, treasury_fee_);
    return convertToShares(remaining_assets_);
end

@view
func previewRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares : Uint256) -> (assets : Uint256):
    alloc_locals;
    let (assets_) = convertToAssets(_shares);
    let (withdraw_fee_) = withdraw_fee.read();
    let (treasury_fee_) = mul_permillion(assets_, withdraw_fee_);
    let (remaining_assets_) = uint256_sub(assets_, treasury_fee_);
    return (remaining_assets_);
end

@view
func calculLinearCumulativeIndex{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (cumulativeIndex : Uint256):
    let (current_timestamp) = get_block_timestamp();
    let (last_updated_timestamp_) = last_updated_timestamp.read();
    let delta_timestamp_ = current_timestamp - last_updated_timestamp_;
    let (last_updated_cumulative_index_) = cumulative_index.read();
    let (borrow_rate_) = borrow_rate.read();
    
    //                                                          /     currentBorrowRate * timeDifference \
    //  new_cumulative_index  = last_updated_cumulative_index * | 1 + ------------------------------------ |
    //                                                          \              SECONDS_PER_YEAR          /

    let (step1_,_) = uint256_mul(delta_timestamp_, borrow_rate_);
    let (step2_,_) = uint256_div(step1_, SECONDS_PER_YEAR);
    let (step3_,_) = uint256_add(step2_, Uint256(PRECISION,0));
    let (step4_,_) = uint256_mul(step3_, last_updated_cumulative_index_);
    let (new_cumulative_index_,_) = uint256_div(step4_, PRECISION);
    return (new_cumulative_index_);
end

@view
func convertToShares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets : Uint256) -> (shares : Uint256):
    alloc_locals
    with_attr error_message("ERC4626: assets is not a valid Uint256"):
        uint256_check(assets);
    end

    let (supply_) = ERC20.total_supply();
    let (all_assets) = totalAssets();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0))
    if (supply_is_zero == TRUE{
        return (assets);
        }
    end
    let (shares_) = mul_div_down(_assets, supply_, all_assets);
    return (shares_)
end

@view
func convertToAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares : Uint256) -> (assets : Uint256):
    alloc_locals
    with_attr error_message("ERC4626: shares is not a valid Uint256"):
        uint256_check(_shares);
    end

    let (supply_) = ERC20.total_supply();
    let (all_assets_) = totalAssets();
    let (supply_is_zero) = uint256_eq(supply_, Uint256(0, 0));
    if supply_is_zero == TRUE:
        return (shares);
    end
    let (assets_) = mul_div_down(shares, all_assets_, supply_);
    return (assets_);
end


@view
func totalAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (totalManagedAssets : Uint256):
    return (Uint256(0, 0))
end

@view
func availableLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableLiquidity : Uint256){
    let (ERC4626_asset_) = ERC4626_asset.read()
    let (this_) = get_contract_address()
    let (available_liquidity_) = IERC20.balance_of(this_)
    return (available_liquidity_)
}

@view
func calculBorrowRate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (borrowRate : Uint256){
    let (available_liquidity_) = availableLiquidity();
    let (expected_liquidity_) = expected_liquidity.read();
    let (is_expected_liquidity_nul_) = uint256_eq(expected_liquidity_,Uint256(0,0));
    // prevent from sending token to the pool 
    let (is_expected_liquidity_lt_expected_liquidity_) = uint256_lt(expected_liquidity_, available_liquidity_);
    let (base_rate_) = base_rate.read();
    if (is_expected_liquidity_nul_ + is_expected_liquidity_lt_expected_liquidity_  != 0) {
        return base_rate_;
    }

    //      expected_liquidity - available_liquidity
    // U = -------------------------------------
    //             expected_liquidity

    let (step1_) = uint256_sub(expected_liquidity_, available_liquidity_);
    let (step2_) = uint256_mul(step1_, Uint256(PRECISION,0));
    let (liquidity_utilization_,_) = uint256_mul(step2_, expected_liquidity_);
    let (optimal_liquidity_utilization_) = optimal_liquidity_utilization.read();
    let (is_utilization_lt_optimal_utilization_) = uint256_lt(liquidity_utilization_, optimal_liquidity_utilization_);


    // if liquidity_utilization_ < optimal_liquidity_utilization_:
    //                                    liquidity_utilization_
    // borrow_rate = base_rate +  slop1 * -----------------------------
    //                                     optimal_liquidity_utilization_

    let (slop1_) = slop1.read();
    if(is_utilization_lt_optimal_utilization_ == 1){
        let (step1_,_) = uint256_mul(liquidity_utilization_, Uint256(PRECISION,0));
        let (step2_,_) = uint256_div(step1_, optimal_liquidity_utilization_);
        let (step3_,_) = uint256_mul(step2_, slop1_);
        let (borrow_rate_,_) = uint256_add(step3_, base_rate_);
        return (borrow_rate_);
    else{

        // if liquidity_utilization_ >= optimal_liquidity_utilization_:
        //
        //                                           liquidity_utilization_ - optimal_liquidity_utilization_
        // borrow_rate = base_rate + slop1 + slop2 * ------------------------------------------------------
        //                                              1 - optimal_liquidity_utilization

        let (slop2_) = slop2.read();
        let (step2_,_) = uint256_mul(Uint256(PRECISION,0), step1_);
        let (step3_,_) = uint256_sub(Uint256(PRECISION,0), optimal_liquidity_utilization_);
        let (step4_,_) = uint256_div(step2_, step3_);
        let (step5_,_) = uint256_mul(step4_, slop2_);
        let (step6_,_) = uint256_add(step5_, slop1_);
        let (borrow_rate_,_) = uint256_add(step6_, base_rate_);
        return(borrow_rate_);
    }
}

@view
func withdrawFee() -> (withdrawFee : Uint256):
    let (withdraw_fee_) = withdraw_fee.read();
    return (withdraw_fee_);
end


//
// INTERNALS
//

func update_borrow_rate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(loss : Uint256){
    let (new_expected_liqudity_) = uint256_sub(expected_liquidity_, loss);
    expected_liquidity.write(new_expected_liqudity_);

    let (new_cumulative_index_) = calculLinearCumulativeIndex();
    cumulative_index.write(new_cumulative_index_);

    let (new_borrow_rate_) = calculBorrowRate();
    borrow_rate.write(new_borrow_rate_);

    let (block_timestamp_) = get_block_timestamp()
    last_updated_timestamp.write(block_timestamp_);
    return ()
}

func ERC20_decrease_allowance_manual{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt, spender: felt, subtracted_value: Uint256) -> ():
        alloc_locals

        # This is vault logic, we place it here to avoid revoked references at callsite
        if spender == owner:
            return ()
        end

        # This is decrease_allowance, but edited
        with_attr error_message("ERC20: subtracted_value is not a valid Uint256"):
            uint256_check(subtracted_value)
        end

        let (current_allowance: Uint256) = ERC20_allowances.read(owner=owner, spender=spender)

        with_attr error_message("ERC20: allowance below zero"):
            let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, subtracted_value)
        end

        ERC20._approve(owner, spender, new_allowance)
        return ()
end