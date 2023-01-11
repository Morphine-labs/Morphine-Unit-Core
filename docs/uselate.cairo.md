# View Functions

### poolDebt

`func poolDebt(_pool_id: felt) -> (debt: Position)`

: Calculate a Pool debt


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `debt` | `Position` |    |

### allPoolDebt

`func allPoolDebt() -> (debt_len: felt, debt: Position)`

: Calculate all Pool Debt


Outputs
| Name | Type | Description |
|------|------|-------------|
| `debt_len` | `felt` |    |
| `debt` | `Position` |    |

### collateral

`func collateral(_asset_id: felt) -> (collateralAmount: felt)`

: Calculate collateral


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_asset_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `collateralAmount` | `felt` |    |

### allCollateral

`func allCollateral() -> (collateral_len: felt, collateral: Position)`

: Calculate all collateral


Outputs
| Name | Type | Description |
|------|------|-------------|
| `collateral_len` | `felt` |  |
| `collateral` | `Position` |  |

### dripValue

`func dripValue() -> (dripValue: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripValue` | `felt` |  |

### assetValue

`func assetValue(_asset_id: felt, _amount: Uint256) -> (assetValue: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_asset_id` | `felt` |  |
| `_amount` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assetValue` | `Uint256` |  |

### collateralValue

`func collateralValue(_asset_id: felt, _amount: Uint256) -> (assetValue: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_asset_id` | `felt` |  |
| `_amount` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `assetValue` | `Uint256` |  |

# External Functions

### activate

`func activate()`


### borrow

`func borrow(_pool_id: felt, _amount: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool_id` | `felt` |  |
| `_amount` | `Uint256` |  |

### repayDebt

`func repayDebt(_pool_id: felt, _amount: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool_id` | `felt` |  |
| `_amount` | `Uint256` |  |

### addCollateral

`func addCollateral(_asset_id: felt, _amount: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_asset_id` | `felt` |  |
| `_amount` | `Uint256` |  |

