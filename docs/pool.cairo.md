# View Functions

### isPaused

`func isPaused() -> (state : felt)`

check if contract are paused


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |  if contract are paused  |

### isBorrowFrozen

`func isBorrowFrozen() -> (state : felt)`

check if borrow are frozen


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |  if borrow are frozen  |

### isRepayFrozen

`func isRepayFrozen() -> (state : felt)`

check if repay are frozen


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |  if repay are frozen  |

### interestRateModel

`func interestRateModel() -> (interestRateModel: felt)`

get interest rate model address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `interestRateModel` | `felt` |    |

### connectedDripManager

`func connectedDripManager() -> (dripManager: felt)`

get connected drip manager address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripManager` | `felt` |    |

### getRegistery

`func getRegistery() -> (registery : felt)`

get registery 


Outputs
| Name | Type | Description |
|------|------|-------------|
| `registery` | `felt` |  registrey address   |

### asset

`func asset() -> (asset: felt)`

get the underlying asset


Outputs
| Name | Type | Description |
|------|------|-------------|
| `asset` | `felt` |    |

### maxDeposit

`func maxDeposit(_to: felt) -> (maxAssets: Uint256)`

max deposit authorized 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_to` | `felt` |  the address of the pool you want to deposit  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `maxAssets` | `Uint256` |  the maximum amount of assets you can deposit  |

### maxMint

`func maxMint(_to: felt) -> (maxShares: Uint256)`

max mint authorized 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_to` | `felt` |  the address of the pool where you want to mint shares  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `maxShares` | `Uint256` |  the maximum amount of shares you can mint  |

### maxWithdraw

`func maxWithdraw(_from: felt) -> (maxAssets: Uint256)`

max withdraw authorized 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |  the address of the pool where you want to withdraw assets  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `maxAssets` | `Uint256` |    |

### maxRedeem

`func maxRedeem(caller: felt) -> (maxShares: Uint256)`

max redeem authorized 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `caller` | `felt` |  caller address  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `maxShares` | `Uint256` |  the maximum amount of assets you can redeem  |

### previewDeposit

`func previewDeposit(_assets: Uint256) -> (shares: Uint256)`

max redeem authorized 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_assets` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `shares` | `Uint256` |    |

### previewMint

`func previewMint(_shares: Uint256) -> (assets: Uint256)`

give you preview of amount assets you will have if you burn your shares


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_shares` | `Uint256` |  number of shares  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assets` | `Uint256` |  number of assets you will have  |

### previewWithdraw

`func previewWithdraw(_assets: Uint256) -> (shares: Uint256)`

give you preview of amount shares you will have if you withdraw your assets


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_assets` | `Uint256` |  number of assets  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `shares` | `Uint256` |  number of shares you will have  |

### previewRedeem

`func previewRedeem(_shares: Uint256) -> (assets: Uint256)`

give you preview of amount shares you will have if you withdraw your assets


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_shares` | `Uint256` |  number of shares  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assets` | `Uint256` |  number of assets you will have  |

### calcLinearCumulativeIndex

`func calcLinearCumulativeIndex() -> (cumulativeIndex: Uint256)`

calculate the cumulative index /     currentBorrowRate * timeDifference \ new_cumulative_index  &#x3D; last_updated_cumulative_index * | 1 + ------------------------------------ | \              SECONDS_PER_YEAR          /


Outputs
| Name | Type | Description |
|------|------|-------------|
| `cumulativeIndex` | `Uint256` |  new cumulativeIndex  |

### convertToShares

`func convertToShares(_assets: Uint256) -> (shares: Uint256)`

convert assets to shares


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_assets` | `Uint256` |  assets to convert  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `shares` | `Uint256` |  number of shares you can obtain from assets  |

### convertToAssets

`func convertToAssets(_shares: Uint256) -> (assets: Uint256)`

convert shares to assets


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_shares` | `Uint256` |  shares to convert  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assets` | `Uint256` |  number of assets you can obtain from shares  |

### totalAssets

`func totalAssets() -> (totalManagedAssets: Uint256)`

get total assets 


Outputs
| Name | Type | Description |
|------|------|-------------|
| `totalManagedAssets` | `Uint256` |  total assets managed by a drip  |

### totalBorrowed

`func totalBorrowed() -> (totalBorrowed: Uint256)`

get total borrowed


Outputs
| Name | Type | Description |
|------|------|-------------|
| `totalBorrowed` | `Uint256` |  total borrowed by a drip  |

### borrowRate

`func borrowRate() -> (borrowRate: Uint256)`

get borrowed rate


Outputs
| Name | Type | Description |
|------|------|-------------|
| `borrowRate` | `Uint256` |    |

### cumulativeIndex

`func cumulativeIndex() -> (borrowRate: Uint256)`

get cumulative index


Outputs
| Name | Type | Description |
|------|------|-------------|
| `borrowRate` | `Uint256` |    |

### lastUpdatedTimestamp

`func lastUpdatedTimestamp() -> (lastUpdatedTimestamp: felt)`

get last timestamp update


Outputs
| Name | Type | Description |
|------|------|-------------|
| `lastUpdatedTimestamp` | `felt` |  last time the timestamp was updated  |

### expectedLiquidity

`func expectedLiquidity() -> (expectedLiquidity: Uint256)`

get expected liquidity


Outputs
| Name | Type | Description |
|------|------|-------------|
| `expectedLiquidity` | `Uint256` |  expected liquidity  |

### expectedLiquidityLimit

`func expectedLiquidityLimit() -> (expectedLiquidityLimit: Uint256)`

get expected liquidity limit


Outputs
| Name | Type | Description |
|------|------|-------------|
| `expectedLiquidityLimit` | `Uint256` |  expected liquidity limit  |

### availableLiquidity

`func availableLiquidity() -> (availableLiquidity: Uint256)`

get available liquidity 


Outputs
| Name | Type | Description |
|------|------|-------------|
| `availableLiquidity` | `Uint256` |  available liquidity  |

### withdrawFee

`func withdrawFee() -> (withdrawFee: Uint256)`

get withdrawFee


Outputs
| Name | Type | Description |
|------|------|-------------|
| `withdrawFee` | `Uint256` |  withdraw fee  |

### name

`func name() -> (name: felt)`

get name


Outputs
| Name | Type | Description |
|------|------|-------------|
| `name` | `felt` |    |

### symbol

`func symbol() -> (symbol: felt)`

get symbol


Outputs
| Name | Type | Description |
|------|------|-------------|
| `symbol` | `felt` |    |

### totalSupply

`func totalSupply() -> (totalSupply: Uint256)`

get totalSupply


Outputs
| Name | Type | Description |
|------|------|-------------|
| `totalSupply` | `Uint256` |    |

### decimals

`func decimals() -> (decimals: felt)`

get decimals


Outputs
| Name | Type | Description |
|------|------|-------------|
| `decimals` | `felt` |    |

### balanceOf

`func balanceOf(account: felt) -> (balance: Uint256)`

get balanceOf


Inputs

| Name | Type | Description |
|------|------|-------------|
| `account` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `balance` | `Uint256` |    |

### allowance

`func allowance(_owner: felt, _spender: felt) -> (remaining: Uint256)`

get allowance


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_owner` | `felt` |  |
| `_spender` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `remaining` | `Uint256` |    |

# External Functions

### pause

`func pause()`

pause pool contract


### unpause

`func unpause()`

unpause pool contract


### freezeBorrow

`func freezeBorrow()`

freeze borrow from pool


### unfreezeBorrow

`func unfreezeBorrow()`

unfreeze borrow from pool


### freezeRepay

`func freezeRepay()`

freeze repay from pool


### unfreezeRepay

`func unfreezeRepay()`

unfreeze repay from pool


### setWithdrawFee

`func setWithdrawFee(_base_withdraw_fee: Uint256)`

set withdraw fee from pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_base_withdraw_fee` | `Uint256` |  fee when withdraw pool  |

### setExpectedLiquidityLimit

`func setExpectedLiquidityLimit(_expected_liquidity_limit: Uint256)`

liquidity limit in pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_expected_liquidity_limit` | `Uint256` |  liquidity limit in pool  |

### updateInterestRateModel

`func updateInterestRateModel(_interest_rate_model: felt)`

update interest rate model in pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_interest_rate_model` | `felt` |  modify interest rate in pool  |

### connectDripManager

`func connectDripManager(_drip_manager: felt)`

connect a new drip manager to a pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_manager` | `felt` |  drip manager address  |

### deposit

`func deposit(_assets: Uint256, _receiver: felt) -> (shares: Uint256)`

deposit assets in pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_assets` | `Uint256` |  amount of assets you want to deposit in the pool  |
| `_receiver` | `felt` |  address who will receive the LP token  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `shares` | `Uint256` |    |

### mint

`func mint(_shares: Uint256, _receiver: felt) -> (assets: Uint256)`

mint LP 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_shares` | `Uint256` |  amount of shares you want to mint  |
| `_receiver` | `felt` |  address who will receive the LP token  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assets` | `Uint256` |    |

### withdraw

`func withdraw(_assets: Uint256, _receiver: felt, _owner: felt) -> (shares: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_assets` | `Uint256` |  |
| `_receiver` | `felt` |  |
| `_owner` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `shares` | `Uint256` |  |

### redeem

`func redeem(_shares: Uint256, _receiver: felt, _owner: felt) -> (assets: Uint256)`

redeem from pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_shares` | `Uint256` |  number of shares you want to redeem  |
| `_receiver` | `felt` |  address who will receive the reedem assets  |
| `_owner` | `felt` |  owner address  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assets` | `Uint256` |    |

### borrow

`func borrow(_borrow_amount: Uint256, _drip: felt)`

borrow from pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrow_amount` | `Uint256` |  amount borrow from the pool  |
| `_drip` | `felt` |  address of the drip where you will got the assets borrowed  |

### repayDripDebt

`func repayDripDebt(_borrowed_amount: Uint256, _profit: Uint256, _loss: Uint256)`

repay the drip debt


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrowed_amount` | `Uint256` |    |
| `_profit` | `Uint256` |  profit you made from the money you borrowed  |
| `_loss` | `Uint256` |  loss you made from the money you borrowed  |

### transfer

`func transfer(recipient: felt, amount: Uint256) -> (success: felt)`

transfer ERC20


Inputs

| Name | Type | Description |
|------|------|-------------|
| `recipient` | `felt` |    |
| `amount` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

### transferFrom

`func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt)`

transferFrom ERC20


Inputs

| Name | Type | Description |
|------|------|-------------|
| `sender` | `felt` |    |
| `recipient` | `felt` |    |
| `amount` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

### approve

`func approve(_spender: felt, amount: Uint256) -> (success: felt)`

Approve ERC20


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_spender` | `felt` |    |
| `amount` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

### increaseAllowance

`func increaseAllowance(_spender: felt, added_value: Uint256) -> (success: felt)`

increaseAllowance ERC20


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_spender` | `felt` |    |
| `added_value` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

### decreaseAllowance

`func decreaseAllowance(_spender: felt, subtracted_value: Uint256) -> (success: felt)`

decreaseAllowance ERC20


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_spender` | `felt` |    |
| `subtracted_value` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

# Events

### Deposit

`func Deposit(from_: felt, to: felt, amount: Uint256, shares: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `to` | `felt` |  |
| `amount` | `Uint256` |  |
| `shares` | `Uint256` |  |

### Withdraw

`func Withdraw(from_: felt, to: felt, amount: Uint256, shares: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `to` | `felt` |  |
| `amount` | `Uint256` |  |
| `shares` | `Uint256` |  |

### BorrowFrozen

`func BorrowFrozen()`


### BorrowUnfrozen

`func BorrowUnfrozen()`


### RepayFrozen

`func RepayFrozen()`


### RepayUnfrozen

`func RepayUnfrozen()`


### Borrow

`func Borrow(from_: felt, amount: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `amount` | `Uint256` |  |

### RepayDebt

`func RepayDebt(borrowedAmount: Uint256, profit: Uint256, loss: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `borrowedAmount` | `Uint256` |  |
| `profit` | `Uint256` |  |
| `loss` | `Uint256` |  |

### NewWithdrawFee

`func NewWithdrawFee(value: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `value` | `Uint256` |  |

### NewExpectedLiquidityLimit

`func NewExpectedLiquidityLimit(value: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `value` | `Uint256` |  |

### NewDripManagerConnected

`func NewDripManagerConnected(drip: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |  |

### UncoveredLoss

`func UncoveredLoss(value: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `value` | `Uint256` |  |

### NewInterestRateModel

`func NewInterestRateModel(interest_rate_model: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `interest_rate_model` | `felt` |  |

