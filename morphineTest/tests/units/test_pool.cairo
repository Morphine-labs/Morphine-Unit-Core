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
from morphine.interfaces.IPool import IPool

const ADMIN = 'morphine-admin';
const USER_1 = 'user-1';


// Token 
const TOKEN_NAME = 'dai';
const TOKEN_SYMBOL = 'DAI';
const TOKEN_DECIMALS = 6;
const TOKEN_INITIAL_SUPPLY_LO = 20000*10**6;
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

// Pool
const ERC4626_NAME = 'Mdai';
const ERC4626_SYMBOL = 'MDAI';
const EXPECTED_LIQUIDITY_LIMIT_LO = 10000*10**6;
const EXPECTED_LIQUIDITY_LIMIT_HI = 0;

@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    tempvar dai;
    tempvar interest_rate_model_contract;
    tempvar registery_contract;
    tempvar pool;

    %{
        ids.dai = deploy_contract("./tests/mocks/erc20.cairo", [ids.TOKEN_NAME, ids.TOKEN_SYMBOL, ids.TOKEN_DECIMALS, ids.TOKEN_INITIAL_SUPPLY_LO, ids.TOKEN_INITIAL_SUPPLY_HI, ids.ADMIN, ids.ADMIN]).contract_address 
        context.dai = ids.dai

        ids.interest_rate_model_contract = deploy_contract(
            "./src/morphine/pool/linearInterestRateModel.cairo", 
            [ids.OPTIMAL_RATE_LO, ids.OPTIMAL_RATE_HI, ids.SLOPE1_LO, ids.SLOPE1_HI, ids.SLOPE2_LO, ids.SLOPE2_HI, ids.BASE_RATE_LO, ids.BASE_RATE_HI]).contract_address 
        context.interest_rate_model_contract = ids.interest_rate_model_contract

        ids.registery_contract = deploy_contract(
            "./src/morphine/registery.cairo", 
            [ids.ADMIN, ids.TREASURY, ids.ORACLE_TRANSIT, ids.DRIP_HASH]).contract_address 
        context.registery_contract = ids.registery_contract

        ids.pool = deploy_contract("./src/morphine/pool/pool.cairo", [ids.registery_contract, ids.dai, ids.ERC4626_NAME, ids.ERC4626_SYMBOL, ids.EXPECTED_LIQUIDITY_LIMIT_LO, ids.EXPECTED_LIQUIDITY_LIMIT_HI, ids.interest_rate_model_contract]).contract_address 
        context.pool = ids.pool    
    %}
    return();
}


// OWNER STUFF

@view
func test_pause_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.pause();
    return ();
}

@view
func test_pause_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();


    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_events({"name": "Paused", "data": [ids.ADMIN],"from_address": ids.pool_}) %}
    pool_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_paused_) = pool_instance.isPaused();
    assert is_paused_ = 1;
    return ();
}

@view
func test_pause_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.pause();
    %{ expect_revert(error_message="Pausable: paused") %}
    pool_instance.pause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_unpause_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.unpause();
    return ();
}

@view
func test_unpause_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_events({"name": "Unpaused", "data": [ids.ADMIN],"from_address": ids.pool_}) %}
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.pause();
    pool_instance.unpause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_paused_) = pool_instance.isPaused();
    assert is_paused_ = 0;
    return ();
}

@view
func test_unpause_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="Pausable: not paused") %}
    pool_instance.unpause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_withdraw_fee_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.setWithdrawFee(Uint256(10000,0));
    return ();
}

@view
func test_withdraw_fee_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="0 <= withdrawFee <= 10.000") %}
    pool_instance.setWithdrawFee(Uint256(100000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_withdraw_fee_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_events({"name": "NewWithdrawFee", "data": [10000, 0],"from_address": ids.pool_}) %}
    pool_instance.setWithdrawFee(Uint256(10000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (withdraw_fee_) = pool_instance.withdrawFee();
    assert withdraw_fee_ = Uint256(10000,0);
    return ();
}

@view
func test_epected_liquidity_limit_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.setExpectedLiquidityLimit(Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0));
    return ();
}

@view
func test_epected_liquidity_limit_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_events({"name": "NewExpectedLiquidityLimit", "data": [ids.EXPECTED_LIQUIDITY_LIMIT_LO,0], "from_address": ids.pool_}) %}
    pool_instance.setExpectedLiquidityLimit(Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (expected_liquidity_limit_) = pool_instance.expectedLiquidityLimit();
    assert expected_liquidity_limit_ = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0);
    return ();
}

@view
func test_freeze_borrow_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.freezeBorrow();
    return ();
}

@view
func test_freeze_borrow_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_events({"name": "BorrowFrozen","from_address": ids.pool_}) %}
    pool_instance.freezeBorrow();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_borrow_frozen_) = pool_instance.isBorrowFrozen();
    assert is_borrow_frozen_ = 1;
    return ();
}

@view
func test_freeze_borrow_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.freezeBorrow();
    %{ expect_revert(error_message="borrow frozen") %}
    pool_instance.freezeBorrow();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_unfreeze_borrow_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.unfreezeBorrow();
    return ();
}

@view
func test_unfreeze_borrow_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_events({"name": "BorrowUnfrozen","from_address": ids.pool_}) %}
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.freezeBorrow();
    pool_instance.unfreezeBorrow();
    let (is_borrow_frozen_) = pool_instance.isBorrowFrozen();
    assert is_borrow_frozen_ = 0;
    return ();
}

@view
func test_unfreeze_borrow_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.freezeBorrow();
    %{ expect_revert(error_message="borrow frozen") %}
    pool_instance.freezeBorrow();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_freeze_repay_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.freezeRepay();
    return ();
}

@view
func test_freeze_repay_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_events({"name": "RepayFrozen","from_address": ids.pool_}) %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.freezeRepay();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_repay_frozen_) = pool_instance.isRepayFrozen();
    assert is_repay_frozen_ = 1;
    return ();
}

@view
func test_freeze_repay_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.freezeRepay();
    %{ expect_revert(error_message="repay frozen") %}
    pool_instance.freezeRepay();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_unfreeze_repay_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    pool_instance.unfreezeRepay();
    return ();
}

@view
func test_unfreeze_repay_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    %{ expect_events({"name": "RepayUnfrozen","from_address": ids.pool_}) %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.freezeRepay();
    pool_instance.unfreezeRepay();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    let (is_repay_frozen_) = pool_instance.isRepayFrozen();
    assert is_repay_frozen_ = 0;
    return ();
}

@view
func test_unfreeze_repay_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="repay not frozen") %}
    pool_instance.unfreezeRepay();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

// SUPPLY STUFF

@view
func test_deposit_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.pause();
    %{ expect_revert(error_message="Pausable: paused") %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
    pool_instance.unpause();
    %{ [stop_prank() for a in stop_pranks] %}
    return ();
}

@view
func test_deposit_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="cannot deposit for 0 shares") %}
    let (shares_)  = pool_instance.deposit(Uint256(0,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_deposit_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="amount exceeds max deposit") %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_deposit_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="zero address not allowed") %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), 0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_deposit_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ expect_events({"name": "Deposit", "data": [ids.ADMIN, ids.ADMIN, 1000000000, 0, 1000000000, 0], "from_address": ids.pool_}) %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    assert shares_ = Uint256(1000000000,0);

    let (balance_) = IERC20.balanceOf(pool_, ADMIN);
    assert balance_ = Uint256(1000000000,0);
    return ();
}

@view
func test_preview_deposit_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    let (shares_) = pool_instance.previewDeposit(Uint256(1000000000,0));
    assert shares_ = Uint256(1000000000,0);
    return ();
}

@view
func test_max_deposit_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    // Before deposit
    let (max_deposit_) = pool_instance.maxDeposit(ADMIN);
    assert max_deposit_ = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0);

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    assert shares_ = Uint256(1000000000,0);

    // Before deposit
    let (max_deposit_) = pool_instance.maxDeposit(ADMIN);
    assert max_deposit_ = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO - 1000000000,0);
    return ();
}


@view
func test_mint_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.pause();
    %{ expect_revert(error_message="Pausable: paused") %}
    let (shares_)  = pool_instance.mint(Uint256(1000000000,0), ADMIN);
    pool_instance.unpause();
    %{ [stop_prank() for a in stop_pranks] %}
    return ();
}

@view
func test_mint_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="cannot mint for 0 assets") %}
    let (shares_)  = pool_instance.mint(Uint256(0,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_mint_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="amount exceeds max mint") %}
    let (shares_)  = pool_instance.mint(Uint256(1000000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_mint_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="zero address not allowed") %}
    let (shares_)  = pool_instance.mint(Uint256(1000000000,0), 0);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_mint_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ expect_events({"name": "Deposit", "data": [ids.ADMIN, ids.ADMIN, 1000000000, 0, 1000000000, 0], "from_address": ids.pool_}) %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (assets_)  = pool_instance.mint(Uint256(1000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    assert assets_ = Uint256(1000000000,0);
    let (balance_) = IERC20.balanceOf(pool_, ADMIN);
    assert balance_ = Uint256(1000000000,0);
    return ();
}

@view
func test_preview_mint_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    let (assets_) = pool_instance.previewMint(Uint256(1000000000,0));
    assert assets_ = Uint256(1000000000,0);
    return ();
}

@view
func test_max_mint_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    // Before deposit
    let (max_mint_) = pool_instance.maxDeposit(ADMIN);
    assert max_mint_ = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0);

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (shares_)  = pool_instance.mint(Uint256(1000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    assert shares_ = Uint256(1000000000,0);

    // Before deposit
    let (max_mint_) = pool_instance.maxDeposit(ADMIN);
    assert max_mint_ = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO - 1000000000,0);
    return ();  
}

@view
func test_max_withdraw_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    // Before deposit
    let (max_withdraw_) = pool_instance.maxWithdraw(ADMIN);
    assert max_withdraw_ = Uint256(0,0);

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    // after deposit
    let (max_withdraw_) = pool_instance.maxWithdraw(ADMIN);
    assert max_withdraw_ = Uint256(1000000000,0);
    return ();
}


@view
func test_withdraw_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(pool_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    pool_instance.pause();
    %{ expect_revert(error_message="Pausable: paused") %}
    let (shares_)  = pool_instance.withdraw(Uint256(1000000000,0), ADMIN, ADMIN);
    pool_instance.unpause();
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_withdraw_2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(pool_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="cannot withdraw for 0 shares") %}
    let (shares_)  = pool_instance.withdraw(Uint256(0,0), ADMIN, ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


@view
func test_withdraw_3{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(pool_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="amount exceeds max withdraw") %}
    let (shares_)  = pool_instance.withdraw(Uint256(1000000000,0), ADMIN, ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}

@view
func test_withdraw_4{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
    alloc_locals;
    let (pool_) = pool_instance.deployed();
    let (dai_) = dai_instance.deployed();

    // deposit first
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
    IERC20.approve(dai_, pool_, Uint256(1000000000,0));
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    let (dai_) = dai_instance.deployed();
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
    %{ expect_revert(error_message="zero address not allowed") %}
    let (shares_)  = pool_instance.withdraw(Uint256(1000000000,0), 0, ADMIN);
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ();
}


// @view
// func test_withdraw_5{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
//     alloc_locals;
//     let (pool_) = pool_instance.deployed();
//     let (dai_) = dai_instance.deployed();
//     // %{ expect_events({"name": "Withdraw", "data": [ids.ADMIN, ids.ADMIN, 1000000000, 0, 1000000000, 0], "from_address": ids.pool_}) %}

//     // deposit first
//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
//     IERC20.approve(dai_, pool_, Uint256(1000000000,0));
//     %{ [stop_prank() for stop_prank in stop_pranks] %}
//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
//     let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
//     %{ [stop_prank() for stop_prank in stop_pranks] %}

//     let (dai_) = dai_instance.deployed();

//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
//     IERC20.approve(pool_, pool_, Uint256(1000000000,0));
//     %{ [stop_prank() for stop_prank in stop_pranks] %}

//     let (allowance_) = IERC20.allowance(pool_, ADMIN, pool_);
//     assert allowance_ = Uint256(1000000000,0);
//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
//     let (shares_)  = pool_instance.withdraw(Uint256(1000000000,0), ADMIN, ADMIN);
//     %{ [stop_prank() for a in stop_pranks] %}
//     // assert shares_ = Uint256(1000000000,0);
//     let (balance_) = IERC20.balan 
//     return ()
// }


// @view
// func test_preview_withdraw_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
//     alloc_locals;
//     let (pool_) = pool_instance.deployed();
//     let (dai_) = dai_instance.deployed();
//     let (shares_) = pool_instance.previewDeposit(Uint256(1000000000,0));
//     assert shares_ = Uint256(1000000000,0);
//     return ();
// }







// @view
// func test_liquidity_1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
//     alloc_locals;
//     let (pool_) = pool_instance.deployed();
//     let (dai_) = dai_instance.deployed();
//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
//     IERC20.approve(dai_, pool_, Uint256(1000000000,0));
//     %{ [stop_prank() for stop_prank in stop_pranks] %}

//     // Before deposit

//     let (total_assets_) = pool_instance.totalAssets();
//     assert total_assets_ = Uint256(0,0);
//     let (expected_liquidity_) = pool_instance.expectedLiquidity();
//     assert expected_liquidity_ = Uint256(0,0);
//     let (available_liquidity_) = pool_instance.availableLiquidity();
//     assert available_liquidity_ = Uint256(0,0);


//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
//     let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
//     %{ [stop_prank() for stop_prank in stop_pranks] %}
//     assert shares_ = Uint256(1000000000,0);

//     // Before deposit

//     let (total_assets_) = pool_instance.totalAssets();
//     assert total_assets_ = Uint256(1000000000,0);
//     let (expected_liquidity_) = pool_instance.expectedLiquidity();
//     assert expected_liquidity_ = Uint256(1000000000,0);
//     let (available_liquidity_) = pool_instance.availableLiquidity();
//     assert available_liquidity_ = Uint256(1000000000,0);


//     return ();
// }

// @view
// func test_supply_stuff{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(){
//     alloc_locals;
//     let (dai_) = dai_instance.deployed();
//     let (pool_) = pool_instance.deployed();
    
//     // 1000 DAI deposit withdraw

//     let (shares_) = pool_instance.previewDeposit(Uint256(1000000000,0));
//     assert shares_ = Uint256(1000000000,0);


//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.dai_] ] %}
//     IERC20.approve(dai_, pool_, Uint256(1000000000,0));
//     %{ [stop_prank() for stop_prank in stop_pranks] %}

//     let (max_deposit_) = pool_instance.maxDeposit(ADMIN);
//     assert max_deposit_ = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0);

//     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
//     pool_instance.pause();
//     // %{ expect_revert(error_message="Pausable: paused") %}
//     // let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
//     pool_instance.unpause();
//     assert 1=2;
//     %{ [stop_prank() for a in stop_pranks] %}

//     // %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.pool_] ] %}
//     // %{ expect_revert(error_message="cannot deposit for 0 shares") %}
//     // let (shares_)  = pool_instance.deposit(Uint256(0,0), ADMIN);
//     // %{ expect_revert(error_message="amount exceeds max deposit") %}
//     // let (shares_)  = pool_instance.deposit(Uint256(1000000000000,0), ADMIN);
//     // %{ expect_revert(error_message="zero address not allowed") %}
//     // let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), 0);

//     // let (shares_)  = pool_instance.deposit(Uint256(1000000000,0), ADMIN);
//     // assert shares_ = Uint256(1000000000,0);
//     // %{ [stop_prank() for stop_prank in stop_pranks] %}

//     // let (total_assets_) = pool_instance.totalAssets();
//     // assert total_assets_ = Uint256(1000000000,0);
//     // let (expected_liquidity_) = pool_instance.expectedLiquidity();
//     // assert expected_liquidity_ = Uint256(1000000000,0);
//     // let (available_liquidity_) = pool_instance.availableLiquidity();
//     // assert available_liquidity_ = Uint256(1000000000,0);

//     // let (max_deposit_2) = pool_instance.maxDeposit(ADMIN);
//     // %{
//     //     print(max_deposit_2.low)
//     //     print(max_deposit_2.high)
//     // %}
//     // assert max_deposit_2 = Uint256(EXPECTED_LIQUIDITY_LIMIT_LO,0);


//     return ();
// }


namespace pool_instance{
    func deployed() -> (pool : felt){
        tempvar pool;
        %{ ids.pool = context.pool %}
        return (pool,);
    }

    // Owner stuff
    func pause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.pause(pool);
    return();
    }

    func unpause{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.unpause(pool);
    return();
    }

    func isPaused{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (state_) = IPool.isPaused(pool); 
    return(state_,);
    }

    func freezeBorrow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.freezeBorrow(pool); 
    return();
    }

    func unfreezeBorrow{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.unfreezeBorrow(pool); 
    return();
    }

    func isBorrowFrozen{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (is_borrow_frozen_) = IPool.isBorrowFrozen(pool); 
    return(is_borrow_frozen_,);
    }

    func freezeRepay{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.freezeRepay(pool); 
    return();
    }

    func unfreezeRepay{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.unfreezeRepay(pool); 
    return();
    }

    func isRepayFrozen{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state: felt) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (is_repay_frozen_) = IPool.isRepayFrozen(pool); 
    return(is_repay_frozen_,);
    }



    func setWithdrawFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(withdraw_fee: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.setWithdrawFee(pool, withdraw_fee);
    return();
    }

    func withdrawFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (withdrawFee: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (withdraw_fee_) = IPool.withdrawFee(pool); 
    return(withdraw_fee_,);
    }

    func setExpectedLiquidityLimit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_expected_liquidity_limit: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    IPool.setExpectedLiquidityLimit(pool, _expected_liquidity_limit); 
    return();
    }

    func expectedLiquidityLimit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (expectedLiquidityLimit: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (expected_liquidity_limit_) = IPool.expectedLiquidityLimit(pool); 
    return(expected_liquidity_limit_,);
    }

    func totalAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (totalManagedAssets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (total_assets_) = IPool.totalAssets(pool); 
    return(total_assets_,);
    }


    func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256, _receiver: felt) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.deposit(pool, _assets, _receiver); 
    return(shares_,);
    }

    func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256, _receiver: felt) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (assets_) = IPool.mint(pool, _shares, _receiver); 
    return(assets_,);
    }

    func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256, _receiver: felt, _owner: felt) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.withdraw(pool, _assets, _receiver, _owner); 
    return(shares_,);
    }

    func redeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256, _receiver: felt, _owner: felt) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (assets_) = IPool.redeem(pool, _shares, _receiver, _owner); 
    return(assets_,);
    }

    func expectedLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (expectedLiquidity: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (expected_liquidity_) = IPool.expectedLiquidity(pool); 
    return(expected_liquidity_,);
    }

    func availableLiquidity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableLiquidity: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (available_liquidity_) = IPool.availableLiquidity(pool); 
    return(available_liquidity_,);
    }


    func previewDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.previewDeposit(pool, _assets); 
    return(shares_,);
    }

    func previewMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (assets_) = IPool.previewMint(pool, _shares); 
    return(assets_,);
    }

    func previewWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assets: Uint256) -> (shares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (shares_) = IPool.previewWithdraw(pool, _assets); 
    return(shares_,);
    }

    func previewRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_shares: Uint256) -> (assets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (asset_) = IPool.previewRedeem(pool, _shares); 
    return(asset_,);
    }

    func maxDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxAssets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_assets_) = IPool.maxDeposit(pool, _to); 
    return(max_assets_,);
    }

    func maxMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxShares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_shares_) = IPool.maxMint(pool, _to); 
    return(max_shares_,);
    }

    func maxWithdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxAssets: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_assets_) = IPool.maxWithdraw(pool, _to); 
    return(max_assets_,);
    }

    func maxRedeem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_to: felt) -> (maxShares: Uint256) {
    tempvar pool;
    %{ ids.pool = context.pool %}
    let (max_shares_) = IPool.maxRedeem(pool, _to); 
    return(max_shares_,);
    }


}


namespace dai_instance{
    func deployed() -> (dai : felt){
        tempvar dai;
        %{ ids.dai = context.dai %}
        return (dai,);
    }
}