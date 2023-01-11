# View Functions

### primitivePairId

`func primitivePairId(_primitive: felt) -> (pair_id: felt)`

: Primitive Pair ID


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_primitive` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `pair_id` | `felt` |    |

### derivativePriceFeed

`func derivativePriceFeed(_derivative: felt) -> (price_feed: felt)`

: Derivative Price Feed


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_derivative` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `price_feed` | `felt` |    |

### convertToUSD

`func convertToUSD(_amount: Uint256, _token: felt) -> (tokenPriceUsd: Uint256)`

: convert To USD

decimals token are managed and the output is 8 decimals

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount` | `Uint256` |    |
| `_token` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenPriceUsd` | `Uint256` |    |

### convertFromUSD

`func convertFromUSD(_amount: Uint256, _token: felt) -> (tokenPrice: Uint256)`

: convert From USD

decimals token are managed and the input is 8 decimals

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount` | `Uint256` |    |
| `_token` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenPrice` | `Uint256` |    |

### convert

`func convert(_amount: Uint256, _token_from: felt, _token_to: felt) -> (price: Uint256)`

: convert

Converts directly an asset into an other one

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount` | `Uint256` |    |
| `_token_from` | `felt` |    |
| `_token_to` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `price` | `Uint256` |    |

### fastCheck

`func fastCheck(_amount_from: Uint256, _token_from: felt, _amount_to: Uint256, _token_to: felt) -> (collateralFrom: Uint256, collateralTo: Uint256)`

: Fast Check

Used to check price of incoming and leaving asset, to control loss

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_amount_from` | `Uint256` |    |
| `_token_from` | `felt` |    |
| `_amount_to` | `Uint256` |    |
| `_token_to` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `collateralFrom` | `Uint256` |    |
| `collateralTo` | `Uint256` |    |

# External Functions

### addPrimitive

`func addPrimitive(_token: felt, _pair_id: felt)`

: Add Primitive


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_pair_id` | `felt` |    |

### addDerivative

`func addDerivative(_token: felt, _derivative_price_feed: felt)`

: Add Derivative


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_derivative_price_feed` | `felt` |    |

# Events

### NewPrimitive

`func NewPrimitive(token: felt, pair_id: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |  |
| `pair_id` | `felt` |  |

### NewDerivative

`func NewDerivative(token: felt, price_feed: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |  |
| `price_feed` | `felt` |  |

