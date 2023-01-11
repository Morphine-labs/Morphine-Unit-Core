# View Functions

### cumulativeIndex

`func cumulativeIndex() -> (cumulativeIndex: Uint256)`

: Cumulative index 


Outputs
| Name | Type | Description |
|------|------|-------------|
| `cumulativeIndex` | `Uint256` |    |

### borrowedAmount

`func borrowedAmount() -> (totalBorrowed: Uint256)`

: Borrowed amount


Outputs
| Name | Type | Description |
|------|------|-------------|
| `totalBorrowed` | `Uint256` |    |

### lastUpdate

`func lastUpdate() -> (since: felt)`

: Last update time


Outputs
| Name | Type | Description |
|------|------|-------------|
| `since` | `felt` |    |

# External Functions

### connectTo

`func connectTo(_drip_manager: felt, _borrowed_amount: Uint256, _cumulative_index: Uint256)`

: Drip initialize


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_manager` | `felt` |    |
| `_borrowed_amount` | `Uint256` |    |
| `_cumulative_index` | `Uint256` |    |

### updateParameters

`func updateParameters(_borrowed_amount: Uint256, _cumulative_index: Uint256)`

: Update paramaters


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrowed_amount` | `Uint256` |    |
| `_cumulative_index` | `Uint256` |    |

### approveToken

`func approveToken(_token: felt, _contract: felt, _amount: Uint256)`

: Approve token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_contract` | `felt` |    |
| `_amount` | `Uint256` |    |

### cancelAllowance

`func cancelAllowance(_token: felt, _contract: felt)`

: Cancel Allowance


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_contract` | `felt` |    |

### safeTransfer

`func safeTransfer(_token: felt, _to: felt, _amount: Uint256)`

: Safe transfer


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_to` | `felt` |    |
| `_amount` | `Uint256` |    |

### execute

`func execute(_to: felt, _selector: felt, _calldata_len: felt, _calldata: felt*) -> (retdata_len: felt, retdata: felt*)`

: Execute function


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_to` | `felt` |    |
| `_selector` | `felt` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `retdata_len` | `felt` |    |
| `retdata` | `felt*` |    |

