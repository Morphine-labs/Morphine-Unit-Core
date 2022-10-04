%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import ( get_caller_address, get_contract_address)

from contracts.interfaces.IERC3156FlashLender import IERC3156FlashLender

from contracts.interfaces.IERC3156FlashBorrower import IERC3156FlashBorrower

from openzeppelin.token.erc20.IERC20 import IERC20

from openzeppelin.security.safemath.library import SafeUint256

const SUCCESS = 1;
const FAILURE = 0;

@storage_var
func lender() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_lender : felt){
    lender.write(_lender);
    return();
}

@external
func onFlashLoan {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}( initiator_address : felt, token_address: felt, amount : Uint256, fee : Uint256, loan_type : felt) -> (return_code : felt){
    let (caller_address :felt) = get_caller_address();
    with_attr error_message("FlashBorrower : untrust initiator") {
        assert caller_address = initiator_address;
    }
    if(loan_type == 'single'){
        FlashBorrow(token_address, amount);
    } else {
        return(return_code=FAILURE);
    }
    return(return_code=SUCCESS);
}

func FlashBorrow {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (token_address : felt, amount : Uint256){
    alloc_locals;
    let (contract_address : felt) = get_contract_address();
    let (caller_address : felt)  = get_caller_address();
    let (lender_contract : felt) = lender.read();
    let (allowance_ : Uint256) = IERC20.allowance(lender_contract, lender_contract,caller_address);
    // Need to fix this by using 64*61 bit
    let (fee_ : Uint256) = SafeUint256.mul(amount, Uint256(1,0));
    let (repayement_amount : Uint256) = SafeUint256.add(amount, fee_); 
    IERC20.approve(lender_contract, caller_address, repayement_amount);
    IERC3156FlashLender.flashLoan(contract_address,caller_address, token_address, amount);
    return();
}

// You can use this function if you want to falsh loan using liquidity from differents pool
func FlashBorrowMultiple {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_address_len : felt, token_address : felt*, amount : Uint256, base_token_len : felt){
    alloc_locals;
    if(token_address_len == 0){
        return();
    }
    let actual_token : felt = [token_address];
    let (caller_address) = get_caller_address();
    let (contract_address) = get_contract_address();
    let (fee_ : Uint256) = calculate_fees_per_pool(base_token_len, amount);
    let (borrow_per_pool : Uint256) = calculate_borrow_per_pool(base_token_len, amount);
    let (repayement_amount_per_pool : Uint256) = SafeUint256.add(fee_,borrow_per_pool);
    let (lender_contract : felt) = lender.read();
    IERC20.approve(lender_contract,caller_address,repayement_amount_per_pool);
    IERC3156FlashLender.flashLoan(contract_address,caller_address,actual_token,borrow_per_pool);
    return FlashBorrowMultiple(token_address_len=token_address_len - 1, token_address=token_address + 1, amount=amount,base_token_len=base_token_len);
}

func calculate_borrow_per_pool {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(nb_token : felt, amount : Uint256) -> (price : Uint256){
    let number_token : Uint256 = Uint256(nb_token,0);
    let (amount_per_pool : Uint256, _) = SafeUint256.div_rem(amount,number_token);
    return(amount_per_pool,);
}

func _flashFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_address : felt, amount : Uint256) -> (fee : Uint256) {
    let (contract_address : felt) = get_contract_address();
    let base_fees = Uint256(1,0);
    let (total_amount : Uint256) = SafeUint256.mul(base_fees,amount);
    let (interest_amount : Uint256,_) = SafeUint256.div_rem(total_amount,Uint256(10000,0));
    return(interest_amount,);
}

func calculate_fees_per_pool {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (token_len : felt, amount : Uint256) -> (fee : Uint256) {
    let (amount_per_pool : Uint256) = calculate_borrow_per_pool(token_len, amount);
    let (fees_per_pool : Uint256) = _flashFee(token_len, amount);
    return(fees_per_pool,);
}