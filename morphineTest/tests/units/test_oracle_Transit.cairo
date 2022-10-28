%lang starknet

// Starkware dependencies
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp

// OpenZeppelin dependencies
from openzeppelin.token.erc20.IERC20 import IERC20

// Project dependencies
from morphine.interfaces.IOracleTransit import IOracleTransit

const ADMIN = 'morphine-admin';
const USER_1 = 'user-1';


// Token 
const TOKEN_NAME = 'ethereum';
const TOKEN_SYMBOL = 'ETH';
const TOKEN_DECIMALS = 18;
const TOKEN_INITIAL_SUPPLY_LO = 2*10**18;
const TOKEN_INITIAL_SUPPLY_HI = 0;

// LinearRateModel

const SLOPE1_LO = 15000;
const SLOPE1_HI = 0;
const SLOPE2_LO = 1000000; 
const SLOPE2_HI = 0; 
const BASE_RATE_LO =  0;
const BASE_RATE_HI =  0;
const OPTIMAL_RATE_LO = 800000; 
const OPTIMAL_RATE_HI = 0; 


// Registery
const TREASURY = 'morphine_treasyury';
const ORACLE_TRANSIT = 'oracle_transit';
const DRIP_HASH = 'drip_hash';

// ERC4626
const ERC4626_NAME = 'Methereum';
const ERC4626_SYMBOL = 'METH';
const EXPECTED_LIQUIDITY_LIMIT_LO = 100*10**18;
const EXPECTED_LIQUIDITY_LIMIT_HI = 0;

@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar token_contract;
    tempvar interest_rate_model_contract;
    tempvar registery_contract;
    tempvar pool_contract;

    %{
        ids.token_contract = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME, ids.TOKEN_SYMBOL, ids.TOKEN_DECIMALS, ids.TOKEN_INITIAL_SUPPLY_LO, ids.TOKEN_INITIAL_SUPPLY_HI, ids.ADMIN, ids.ADMIN]).contract_address 
        context.token_contract = ids.token_contract
        print(ids.token_contract)

        ids.interest_rate_model_contract = deploy_contract(
            "./src/morphine/pool/linearInterestRateModel.cairo", 
            [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract
        print(ids.interest_rate_model_contract)

        ids.registery_contract = deploy_contract(
            "./src/morphine/registery.cairo", 
            [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.DRIP_HASH]).contract_address 
        context.registery_contract = ids.registery_contract
        print(ids.registery_contract)

        ids.pool_contract = deploy_contract("./src/morphine/pool/pool.cairo", [ids.registery_contract, ids.token_contract, ids.ERC4626_NAME, ids.ERC4626_SYMBOL, ids.EXPECTED_LIQUIDITY_LIMIT_LO, ids.EXPECTED_LIQUIDITY_LIMIT_HI, ids.interest_rate_model_contract]).contract_address 
        context.pool_contract = ids.pool_contract    
    %}
    return();
}



@view
func test_supply_pool{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    // Get ERC20 token deployed contract instance
    let (token_) = token_instance.deployed();
    // Get StarkVest deployed contract instance
    // let (pool_) = pool_instance.deployed();



    // with starkvest:
    //     # Create vesting:
    //     # 1000 $SVT over 1 hour, with no cliff period
    //     # vested second by second, starting at timestamp: 1000
    //     let beneficiary = USER_1
    //     let cliff_delta = 0
    //     let start = 1000
    //     let duration = 3600
    //     let slice_period_seconds = 1
    //     let revocable = TRUE
    //     let amount_total = Uint256(1000, 0)
    //     %{ expect_events({"name": "VestingCreated"}) %}
    //     let (vesting_id) = starkvest_instance.create_vesting(
    //         beneficiary, cliff_delta, start, duration, slice_period_seconds, revocable, amount_total
    //     )

    //     # Set block time to 999 (1 second before vesting starts)
    //     %{ stop_warp = warp(999, ids.starkvest) %}
    //     let (releasable_amount) = starkvest_instance.releasable_amount(vesting_id)
    //     %{ stop_warp() %}
    //     assert releasable_amount = Uint256(0, 0)

    //     # Set block time to 2800 (1800 second after vesting starts)
    //     # Should have vested 50% of tokens
    //     %{ stop_warp = warp(2800, ids.starkvest) %}
    //     let (releasable_amount) = starkvest_instance.releasable_amount(vesting_id)
    //     assert releasable_amount = Uint256(500, 0)

    //     # Check balance of vesting contract before release
    //     let (starkvest_balance) = IERC20.balanceOf(token, starkvest)
    //     assert starkvest_balance = Uint256(2000, 0)

    //     # Check balance of user 1 before release
    //     let (user_1_balance) = IERC20.balanceOf(token, USER_1)
    //     assert user_1_balance = Uint256(0, 0)

    //     # Check vestings total amount before release
    //     let (vestings_total_amount) = starkvest_instance.vestings_total_amount()
    //     assert vestings_total_amount = Uint256(1000, 0)

    //     # Release 100 tokens
    //     starkvest_instance.release(vesting_id, Uint256(100, 0))
    //     let (releasable_amount) = starkvest_instance.releasable_amount(vesting_id)
    //     assert releasable_amount = Uint256(400, 0)

    //     # Check balance of vesting contract after release
    //     let (starkvest_balance) = IERC20.balanceOf(token, starkvest)
    //     assert starkvest_balance = Uint256(1900, 0)

    //     # Check balance of user 1 after release
    //     let (user_1_balance) = IERC20.balanceOf(token, USER_1)
    //     assert user_1_balance = Uint256(100, 0)

    //     # Check vestings total amount after release
    //     let (vestings_total_amount) = starkvest_instance.vestings_total_amount()
    //     assert vestings_total_amount = Uint256(900, 0)

    //     # Withdraw 1000
    //     starkvest_instance.withdraw(Uint256(1000, 0))
    //     let (starkvest_balance) = IERC20.balanceOf(token, starkvest)
    //     assert starkvest_balance = Uint256(900, 0)
    //     let (owner_balance) = IERC20.balanceOf(token, ADMIN)
    //     assert owner_balance = Uint256(999000, 0)

    //     # Revoke
    //     # The 400 remaining vested tokens should be released
    //     %{ expect_events({"name": "VestingRevoked", "data": [ids.vesting_id]}) %}
    //     %{ expect_events({"name": "TokensReleased", "data": [ids.vesting_id, 400, 0]}) %}
    //     starkvest_instance.revoke(vesting_id)
    //     %{ stop_warp() %}
    //     # Check balance of user 1 after revoke
    //     let (user_1_balance) = IERC20.balanceOf(token, USER_1)
    //     assert user_1_balance = Uint256(500, 0)        
    // end

    return ();
}

namespace pool_instance{
    func deployed() -> (starkvest_contract : felt){
        tempvar starkvest_contract;
        %{ ids.starkvest_contract = context.starkvest_contract %}
        return (starkvest_contract,);
    }

}


namespace token_instance{
    func deployed() -> (token_contract : felt){
        tempvar token_contract;
        %{ ids.token_contract = context.token_contract %}
        return (token_contract,);
    }
}