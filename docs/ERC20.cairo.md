# View Functions

### name

`func name() -> (name: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `name` | `felt` |  |

### symbol

`func symbol() -> (symbol: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `symbol` | `felt` |  |

### totalSupply

`func totalSupply() -> (totalSupply: Uint256)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `totalSupply` | `Uint256` |  |

### decimals

`func decimals() -> (decimals: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `decimals` | `felt` |  |

### balanceOf

`func balanceOf(account: felt) -> (balance: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `account` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `balance` | `Uint256` |  |

### allowance

`func allowance(owner: felt, spender: felt) -> (remaining: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |
| `spender` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `remaining` | `Uint256` |  |

# External Functions

### transfer

`func transfer(recipient: felt, amount: Uint256) -> (success: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `recipient` | `felt` |  |
| `amount` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |  |

### transferFrom

`func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `sender` | `felt` |  |
| `recipient` | `felt` |  |
| `amount` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |  |

### approve

`func approve(spender: felt, amount: Uint256) -> (success: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `spender` | `felt` |  |
| `amount` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |  |

### increaseAllowance

`func increaseAllowance(spender: felt, added_value: Uint256) -> (success: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `spender` | `felt` |  |
| `added_value` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |  |

### decreaseAllowance

`func decreaseAllowance(spender: felt, subtracted_value: Uint256) -> (success: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `spender` | `felt` |  |
| `subtracted_value` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |  |

