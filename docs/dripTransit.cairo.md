# View Functions

### dripManager

`func dripManager() -> (dripManager: felt)`

: Drip Manager

: Important when set new drip transit to the drip infra

Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripManager` | `felt` |    |

### getNft

`func getNft() -> (nft: felt)`

: Get NFT


Outputs
| Name | Type | Description |
|------|------|-------------|
| `nft` | `felt` |    |

### isExpired

`func isExpired() -> (state: felt)`

: Is Expired


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### calcTotalValue

`func calcTotalValue(_drip: felt) -> (total: Uint256, twv: Uint256)`

: Calcul Total Value


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `total` | `Uint256` |    |
| `twv` | `Uint256` |    |

### calcDripHealthFactor

`func calcDripHealthFactor(_drip: felt) -> (health_factor: Uint256)`

: Calcul Drip Health Factor


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `health_factor` | `Uint256` |    |

### hasOpenedDrip

`func hasOpenedDrip(_borrower: felt) -> (state: felt)`

: Has Opened Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### isTokenAllowed

`func isTokenAllowed(_token: felt) -> (state: felt)`

: Is Token Allowed


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### isIncreaseDebtForbidden

`func isIncreaseDebtForbidden() -> (state: felt)`

: Is Increase Debt Forbidden


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### maxBorrowedAmountPerBlock

`func maxBorrowedAmountPerBlock() -> (max_borrowed_amount_per_block_: Uint256)`

: Max Borrowed Amount Per Block


Outputs
| Name | Type | Description |
|------|------|-------------|
| `max_borrowed_amount_per_block_` | `Uint256` |    |

### expirationDate

`func expirationDate() -> (expiration_date: felt)`

: Expiration Date


Outputs
| Name | Type | Description |
|------|------|-------------|
| `expiration_date` | `felt` |    |

### isExpirable

`func isExpirable() -> (state: felt)`

: Is Expirable 


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### limits

`func limits() -> (minimum_borrowed_amount: Uint256, max_borrowed_amount: Uint256)`

: Limits


Outputs
| Name | Type | Description |
|------|------|-------------|
| `minimum_borrowed_amount` | `Uint256` |    |
| `max_borrowed_amount` | `Uint256` |    |

### lastLimitSaved

`func lastLimitSaved() -> (last_limit_saved: Uint256)`

: Last Limit Saved

: Used to calculate cumulative borowed amount per block

Outputs
| Name | Type | Description |
|------|------|-------------|
| `last_limit_saved` | `Uint256` |    |

### lastBlockSaved

`func lastBlockSaved() -> (last_block_saved: felt)`

: Last Block Saved

: Used to calculate cumulative borowed amount per block

Outputs
| Name | Type | Description |
|------|------|-------------|
| `last_block_saved` | `felt` |    |

### isTransferAllowed

`func isTransferAllowed(_from: felt, _to: felt) -> (state : felt)`

: Is Transfer Allowed

: Used to calculate cumulative borowed amount per block

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |    |
| `_to` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

# External Functions

### openDrip

`func openDrip(_amount: Uint256,        _on_belhalf_of: felt,        _leverage_factor: Uint256)`

: Open Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount` | `Uint256` |    |
| `_on_belhalf_of` | `felt` |    |
| `_leverage_factor` | `Uint256` |    |

### openDripMultiCall

`func openDripMultiCall(_borrowed_amount: Uint256,        _on_belhalf_of: felt,        _call_array_len: felt,        _call_array: AccountCallArray*,        _calldata_len: felt,        _calldata: felt*)`

: Open Drip Multi Call


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrowed_amount` | `Uint256` |    |
| `_on_belhalf_of` | `felt` |    |
| `_call_array_len` | `felt` |    |
| `_call_array` | `AccountCallArray*` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

### closeDrip

`func closeDrip(_to: felt,        _call_array_len: felt,        _call_array: AccountCallArray*,        _calldata_len: felt,        _calldata: felt*)`

: Close Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_to` | `felt` |    |
| `_call_array_len` | `felt` |    |
| `_call_array` | `AccountCallArray*` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

### liquidateDrip

`func liquidateDrip(_borrower: felt,        _to: felt,        _call_array_len: felt,        _call_array: AccountCallArray*,        _calldata_len: felt,        _calldata: felt*)`

: Liquidate Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |
| `_to` | `felt` |    |
| `_call_array_len` | `felt` |    |
| `_call_array` | `AccountCallArray*` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

### liquidateExpiredDrip

`func liquidateExpiredDrip(_borrower: felt,        _to: felt,        _call_array_len: felt,        _call_array: AccountCallArray*,        _calldata_len: felt,        _calldata: felt*)`

: Liquidate Expired Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |
| `_to` | `felt` |    |
| `_call_array_len` | `felt` |    |
| `_call_array` | `AccountCallArray*` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

### increaseDebt

`func increaseDebt(_amount: Uint256)`

: Increase Debt


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount` | `Uint256` |    |

### decreaseDebt

`func decreaseDebt(_amount: Uint256)`

: Decrease Debt


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount` | `Uint256` |    |

### addCollateral

`func addCollateral(_on_belhalf_of: felt, _token: felt, _amount: Uint256)`

: Add Collateral


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_on_belhalf_of` | `felt` |    |
| `_token` | `felt` |    |
| `_amount` | `Uint256` |    |

### multicall

`func multicall(_call_array_len: felt,        _call_array: AccountCallArray*,        _calldata_len: felt,        _calldata: felt*)`

: multicall


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_call_array_len` | `felt` |    |
| `_call_array` | `AccountCallArray*` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

### enableToken

`func enableToken(_token: felt)`

: Enable Token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |

### approve

`func approve(_target: felt, _token: felt, _amount: Uint256)`

: Approve 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_target` | `felt` |    |
| `_token` | `felt` |    |
| `_amount` | `Uint256` |    |

### transferDripOwnership

`func transferDripOwnership(_to: felt)`

: Transfer Ownership 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_to` | `felt` |    |

### approveDripTransfers

`func approveDripTransfers(_from: felt, _state: felt)`

: Approve Drip Transfer


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |    |
| `_state` | `felt` |    |

### setIncreaseDebtForbidden

`func setIncreaseDebtForbidden(_state: felt)`

: Set Increase Debt Forbidden

: Forbid or Allow increase debt, and open drip

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_state` | `felt` |    |

### setMaxBorrowedAmountPerBlock

`func setMaxBorrowedAmountPerBlock(_max_borrowed_amount_per_block: Uint256)`

: Set Max Borrowed Amount Per Block

: Permisionless case only, to avoid Flash Loan Attack

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_max_borrowed_amount_per_block` | `Uint256` |    |

### setDripLimits

`func setDripLimits(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256)`

: Set Drip Limits

: Set Maximum and Minimum borrowed amount per Drip

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_minimum_borrowed_amount` | `Uint256` |    |
| `_maximum_borrowed_amount` | `Uint256` |    |

### setExpirationDate

`func setExpirationDate(_expiration_date: felt)`

: Set Expiration Date

: Effective only if drip transit expirable

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_expiration_date` | `felt` |    |

# Events

### OpenDrip

`func OpenDrip(owner: felt, drip: felt, borrowed_amount: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |
| `drip` | `felt` |  |
| `borrowed_amount` | `Uint256` |  |

### CloseDrip

`func CloseDrip(caller: felt, to: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `caller` | `felt` |  |
| `to` | `felt` |  |

### MultiCallStarted

`func MultiCallStarted(borrower: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `borrower` | `felt` |  |

### MultiCallFinished

`func MultiCallFinished()`


### AddCollateral

`func AddCollateral(on_belhalf_of: felt, token: felt, amount: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `on_belhalf_of` | `felt` |  |
| `token` | `felt` |  |
| `amount` | `Uint256` |  |

### IncreaseBorrowedAmount

`func IncreaseBorrowedAmount(borrower: felt, amount: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `borrower` | `felt` |  |
| `amount` | `Uint256` |  |

### DecreaseBorrowedAmount

`func DecreaseBorrowedAmount(borrower: felt, amount: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `borrower` | `felt` |  |
| `amount` | `Uint256` |  |

### LiquidateDrip

`func LiquidateDrip(borrower: felt, caller: felt, to: felt, remaining_funds: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `borrower` | `felt` |  |
| `caller` | `felt` |  |
| `to` | `felt` |  |
| `remaining_funds` | `Uint256` |  |

### LiquidateExpiredDrip

`func LiquidateExpiredDrip(borrower: felt, caller: felt, to: felt, remaining_funds: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `borrower` | `felt` |  |
| `caller` | `felt` |  |
| `to` | `felt` |  |
| `remaining_funds` | `Uint256` |  |

### TransferDrip

`func TransferDrip(_from : felt, to: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |  |
| `to` | `felt` |  |

### TransferDripAllowed

`func TransferDripAllowed(_from: felt, to: felt, _state: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |  |
| `to` | `felt` |  |
| `_state` | `felt` |  |

### TokenEnabled

`func TokenEnabled(_from: felt, token: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |  |
| `token` | `felt` |  |

### TokenDisabled

`func TokenDisabled(_from: felt, token: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |  |
| `token` | `felt` |  |

