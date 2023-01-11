# View Functions

### getPublicKey

`func getPublicKey() -> (publicKey: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `publicKey` | `felt` |  |

### supportsInterface

`func supportsInterface(interfaceId: felt) -> (success: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `interfaceId` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |  |

### isValidSignature

`func isValidSignature(hash: felt,    signature_len: felt,    signature: felt*) -> (isValid: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `hash` | `felt` |  |
| `signature_len` | `felt` |  |
| `signature` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `isValid` | `felt` |  |

# External Functions

### setPublicKey

`func setPublicKey(newPublicKey: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `newPublicKey` | `felt` |  |

### __validate__

`func __validate__(call_array_len: felt,    call_array: AccountCallArray*,    calldata_len: felt,    calldata: felt*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `call_array_len` | `felt` |  |
| `call_array` | `AccountCallArray*` |  |
| `calldata_len` | `felt` |  |
| `calldata` | `felt*` |  |

### __validate_declare__

`func __validate_declare__(class_hash: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `class_hash` | `felt` |  |

### __validate_deploy__

`func __validate_deploy__(class_hash: felt,    salt: felt,    publicKey: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `class_hash` | `felt` |  |
| `salt` | `felt` |  |
| `publicKey` | `felt` |  |

### __execute__

`func __execute__(call_array_len: felt,    call_array: AccountCallArray*,    calldata_len: felt,    calldata: felt*) -> (response_len: felt,    response: felt*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `call_array_len` | `felt` |  |
| `call_array` | `AccountCallArray*` |  |
| `calldata_len` | `felt` |  |
| `calldata` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `response_len` | `felt` |  |
| `response` | `felt*` |  |

