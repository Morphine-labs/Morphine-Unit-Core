# View Functions

### nextDrip

`func nextDrip(_drip: felt) -> (drip: felt)`

: Next Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |    |

### dripsLength

`func dripsLength() -> (dripLength: felt)`

: Drip Length


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripLength` | `felt` |    |

### idToDrip

`func idToDrip(_id: felt) -> (drip: felt)`

: ID To Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |    |

### dripToId

`func dripToId(_drip: felt) -> (id: felt)`

: Drip To ID


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `id` | `felt` |    |

### isDrip

`func isDrip(_drip: felt) -> (state: felt)`

: Is Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### dripStockLength

`func dripStockLength() -> (length: felt)`

: Drip Stock Length

: Unused drip are stored to save gas for new Drip

Outputs
| Name | Type | Description |
|------|------|-------------|
| `length` | `felt` |    |

# External Functions

### addDrip

`func addDrip()`

: add Drip

: Deploy a new Drip

### takeDrip

`func takeDrip(_borrowed_amount: Uint256, _cumulative_index: Uint256) -> (address: felt)`

: Take Drip

: Function Used by Drip Manager for new borrower

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrowed_amount` | `Uint256` |    |
| `_cumulative_index` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `address` | `felt` |    |

### returnDrip

`func returnDrip(_used_drip: felt)`

: Return Drip

: Function Used by Drip Manager when closing Drip

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_used_drip` | `felt` |    |

### takeOut

`func takeOut(_prev: felt, _drip: felt, _to: felt)`

: Take Out

: Function Used by the Admin to Remove a bad Drip

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_prev` | `felt` |    |
| `_drip` | `felt` |    |
| `_to` | `felt` |    |

# Events

### NewDrip

`func NewDrip(drip: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |  |

### DripTaken

`func DripTaken(drip: felt, caller: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |  |
| `caller` | `felt` |  |

### DripReturned

`func DripReturned(drip: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |  |

### DripTakenForever

`func DripTakenForever(drip: felt, caller: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |  |
| `caller` | `felt` |  |

