// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0b (token/erc721/presets/ERC721MintableBurnable.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_pow2, uint256_eq, uint256_lt
from starkware.cairo.common.math import assert_not_zero, split_felt
from starkware.starknet.common.syscalls import (
    get_contract_address,
    get_caller_address
)

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.security.safemath.library import SafeUint256

from morphine.interfaces.IRegistery import IRegistery
from morphine.interfaces.IDripTransit import IDripTransit
from morphine.interfaces.IDripManager import IDripManager

//
// Events 
//

@event 
func NewMinterSet(minter: felt){
}

@event 
func NewDripTransitAdded(drip_transit: felt){
}

@event 
func NewDripTransitRemoved(drip_transit: felt){
}

// Storage

@storage_var
func registery() -> (registery: felt) {
}

@storage_var
func supported_drip_transit(drip_transit: felt) -> (state: felt) {
}

@storage_var
func minter() -> (minter: felt) {
}

@storage_var
func base_URI() -> (minter: felt) {
}

//
// Protectors
//

func assert_only_owner_or_drip_transit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_) = get_caller_address();
    let (owner_) = Ownable.owner();
    let (is_supported_drip_transit_) = supported_drip_transit.read(caller_);
    with_attr error_message("only callable by drip transit or owner") {
        assert ((caller_ - owner_) * (is_supported_drip_transit_ - 1)) = 0;
    }
    return();
}

func assert_only_minter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    let (caller_) = get_caller_address();
    let (minter_) = Ownable.owner();
    with_attr error_message("only callable by minter") {
        assert caller_ = minter_;
    }
    return();
}

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _name: felt, _symbol: felt, _registery: felt
) {
    ERC721.initializer(_name, _symbol);
    ERC721Enumerable.initializer();
    registery.write(_registery);
    let (owner_) = IRegistery.owner(_registery);
    Ownable.initializer(owner_);
    return ();
}

//
// Getters
//

@view
func totalSupply{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC721Enumerable.total_supply();
    return (totalSupply=totalSupply);
}

@view
func tokenByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_by_index(index);
    return (tokenId=tokenId);
}

@view
func tokenOfOwnerByIndex{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId: Uint256) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId=tokenId);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    return ERC721.owner_of(tokenId);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI: felt) {
    let (token_uri_) = baseURI();
    return(token_uri_,);
}

@view
func baseURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (baseURI: felt) {
    let (baseURI_: felt) = base_URI.read();
    return (baseURI_,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}


//
// Externals
//

@external
func setMinter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _minter: felt
) {
    Ownable.assert_only_owner();
    minter.write(_minter);
    NewMinterSet.emit(_minter);
    return ();
}

@external
func addDripTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip_transit: felt
) {
    alloc_locals;
    Ownable.assert_only_owner();
    let (is_supported_drip_transit_) = supported_drip_transit.read(_drip_transit);
    with_attr error_message("drip transit already registered") {
        assert is_supported_drip_transit_ = 0;
    }
    let (drip_manager_) = IDripTransit.dripManager(_drip_transit);
    let (registery_) = registery.read();
    let (is_drip_manager_) = IRegistery.isDripManager(registery_, drip_manager_);

    let (nft_) = IDripTransit.getNft(_drip_transit);
    let (this_) = get_contract_address();
    let (is_right_nft_) = is_equal(nft_, this_);
    
    let (drip_transit_from_drip_manager_) = IDripManager.dripTransit(drip_manager_);
    let (is_right_drip_transit_) = is_equal(drip_transit_from_drip_manager_, _drip_transit);

    with_attr error_message("invalid drip transit") {
        assert_not_zero(is_drip_manager_*  is_right_nft_*is_right_drip_transit_ );
    }
    supported_drip_transit.write(_drip_transit, 1);
    NewDripTransitAdded.emit(_drip_transit);
    return ();
}

@external
func removeDripTransit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _drip_transit: felt
) {
    Ownable.assert_only_owner();
    let (is_supported_drip_transit_) = supported_drip_transit.read(_drip_transit);
    with_attr error_message("drip transit not registered") {
        assert is_supported_drip_transit_ = 1;
    }
    supported_drip_transit.write(_drip_transit, 0);
    NewDripTransitRemoved.emit(_drip_transit);
    return ();
}


@external
func approve{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    with_attr error_message("method not implemented") {
        assert 1 = 0;
    }
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    with_attr error_message("method not implemented") {
        assert 1 = 0;
    }
    return ();
}

@external
func transferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    with_attr error_message("method not implemented") {
        assert 1 = 0;
    }
    return ();
}

@external
func safeTransferFrom{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    with_attr error_message("method not implemented") {
        assert 1 = 0;
    }
    return ();
}

@external
func mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _amount: Uint256
) {
    assert_only_minter();
    let (balance_before_) = balanceOf(_to);
    recursive_mint(_to, _amount, Uint256(0,0),balance_before_);
    return ();
}

func recursive_mint{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _to: felt, _amount: Uint256, _index: Uint256,_balance_before_: Uint256
) {
    alloc_locals;
    let (is_eq_) = uint256_eq(_index, _amount);
    if(is_eq_ == 1){
        return();
    }
    let (address_uint256_) = felt_to_uint256(_to);
    let (two_pow_40_) = uint256_pow2(Uint256(40,0));
    let (mul_) = SafeUint256.mul(address_uint256_, two_pow_40_);
    let (add_) = SafeUint256.add(mul_, _index);
    let (token_id_) = SafeUint256.add(add_, _balance_before_);
    ERC721Enumerable._mint(_to, token_id_);
    let (new_index_) = SafeUint256.add(_index, Uint256(1,0));
    return recursive_mint(_to, _amount, new_index_, _balance_before_);
}

@external
func burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_from: felt, _amount: Uint256) {
    assert_only_owner_or_drip_transit();
    let (user_balance_) = balanceOf(_from);
    let (is_lt_) = uint256_lt(user_balance_, _amount);
    with_attr error_message("insufficient balance") {
        assert is_lt_ = 0;
    }
    recursive_burn(_from, _amount, Uint256(0,0), user_balance_);
    return ();
}

func recursive_burn{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
    _from: felt, _amount: Uint256, _index: Uint256,_user_balance: Uint256
) {
    alloc_locals;
    let (is_eq_) = uint256_eq(_index, _amount);
    if(is_eq_ == 1){
        return();
    }
    let (address_uint256_) = felt_to_uint256(_from);
    let (two_pow_40_) = uint256_pow2(Uint256(40,0));
    let (mul_) = SafeUint256.mul(address_uint256_, two_pow_40_);
    let (add_) = SafeUint256.add(mul_, _user_balance);
    let (sub_) = SafeUint256.sub_le(add_, _index);
    let (token_id_) = SafeUint256.sub_le(sub_, Uint256(1,0));
    ERC721Enumerable._burn(token_id_);
    let (new_index_) = SafeUint256.add(_index, Uint256(1,0));
    return recursive_burn(_from, _amount, new_index_, _user_balance);
}

@external
func setBaseURI{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(_baseURI: felt) {
    Ownable.assert_only_owner();
    base_URI.write(_baseURI);
    return ();
}

@external
func updateOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (registery_) = registery.read();
    let (owner_) = IRegistery.owner(registery_);
    Ownable.transfer_ownership(owner_);
    return ();
}

func is_equal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(a: felt, b: felt) -> (state: felt) {
    if (a == b){
        return(1,);
    } else {
        return(0,);
    }
}

func felt_to_uint256{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    felt_value : felt
) -> (uint256_value : Uint256) {
    let (high, low) = split_felt(felt_value);
    let uint256_value : Uint256 = Uint256(low, high);
    return (uint256_value,);
}