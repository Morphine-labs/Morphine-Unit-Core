# External Functions

### deployContract

`func deployContract(classHash: felt,    salt: felt,    unique: felt,    calldata_len: felt,    calldata: felt*) -> (address: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `classHash` | `felt` |  |
| `salt` | `felt` |  |
| `unique` | `felt` |  |
| `calldata_len` | `felt` |  |
| `calldata` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `address` | `felt` |  |

# Events

### ContractDeployed

`func ContractDeployed(address: felt,    deployer: felt,    unique: felt,    classHash: felt,    calldata_len: felt,    calldata: felt*,    salt: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `address` | `felt` |  |
| `deployer` | `felt` |  |
| `unique` | `felt` |  |
| `classHash` | `felt` |  |
| `calldata_len` | `felt` |  |
| `calldata` | `felt*` |  |
| `salt` | `felt` |  |

