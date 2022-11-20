from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import uint256_unsigned_div_rem, uint256_mul
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

// SELECTORS 
const APPROVE_SELECTOR = 73937833738373;
const REVERT_IF_RECEIVED_LESS_THAN_SELECTOR = 7383937937833738373;
const ADD_COLLATERAL_SELECTOR = 222;
const INCREASE_DEBT_SELECTOR = 222;
const DECREASE_DEBT_SELECTOR = 222;
const ENABLE_TOKEN_SELECTOR = 222;
const DISABLE_TOKEN_SELECTOR = 222;


// UTILS
const PRECISION = 1000000;
const SECONDS_PER_YEAR = 31536000;
const ALL_ONES = 2 ** 128 - 1;

// DEFAULTS
const DEFAULT_FEE_INTEREST = 100000;
const DEFAULT_LIQUIDATION_PREMIUM = 40000;
const DEFAULT_FEE_LIQUIDATION = 20000;
const DEFAULT_FEE_LIQUIDATION_EXPIRED_PREMIUM = 30000;
const DEFAULT_FEE_LIQUIDATION_EXPIRED = 20000;

// MAX
const MAX_WITHDRAW_FEE = 10000;
const DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 5;




// CONVERSION

func uint256_permillion{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    x: Uint256, permillion: Uint256
) -> (res: Uint256) {
    let (mul, _high) = uint256_mul(x, permillion);
    let (res, _) = uint256_unsigned_div_rem(mul, Uint256(PRECISION, 0));
    return (res=res);
}
