// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from morphine.interfaces.IERC4626 import IERC4626

/// @title ERC4626 PriceFeed
/// @author 0xSacha
/// @dev To get ERC4626 underlying values
/// @custom:experimental This is an experimental contract. 


// @notice: Calcul Underlying Values
// @param: _derivative ERC4626 Token (felt)
// @param: _amount ERC4626 Tokens Amount (felt)
// @return: underlyingsAssets_len Underlying Assets Length (felt)
// @return: underlyingsAssets Underlying Assets (felt*)
// @return: underlyingsAmount_len Underlying Amount Length (felt)
// @return: underlyingsAmount Underlying Amount (Uint256*)
@view
func calcUnderlyingValues{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _derivative: felt, _amount: Uint256
) -> (
    underlyingsAssets_len: felt,
    underlyingsAssets: felt*,
    underlyingsAmount_len: felt,
    underlyingsAmount: Uint256*,
) {
    alloc_locals;
    let (underlyingAsset_: felt) = IERC4626.asset(_derivative);
    let (underlyingsAssets_: felt*) = alloc();
    let (underlyingsAmount_: Uint256*) = alloc();
    assert [underlyingsAssets_] = underlyingAsset_;
    let (amount_: Uint256) = IERC4626.previewRedeem(_derivative, _amount);
    assert [underlyingsAmount_] = amount_;
    return (
        underlyingsAssets_len=1,
        underlyingsAssets=underlyingsAssets_,
        underlyingsAmount_len=1,
        underlyingsAmount=underlyingsAmount_,
    );
}

