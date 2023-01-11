# View Functions

### get_token_address

`func get_token_address() -> (res: felt)`

: Get the token address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `res` | `felt` |    |

### get_wait

`func get_wait() -> (res: felt)`

: Get the wait time


Outputs
| Name | Type | Description |
|------|------|-------------|
| `res` | `felt` |    |

### get_allowed_time

`func get_allowed_time(account: felt) -> (res: felt)`

: Get the time when you will be able to mint again


Inputs

| Name | Type | Description |
|------|------|-------------|
| `account` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `res` | `felt` |    |

### isAllowedForTransaction

`func isAllowedForTransaction(address: felt) -> (success: felt)`

: Check if an address is allowed to mint


Inputs

| Name | Type | Description |
|------|------|-------------|
| `address` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

# External Functions

### faucet_mint

`func faucet_mint() -> (success: felt)`

: Faucet mint function


Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

