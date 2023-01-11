# View Functions

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

### balanceOf

`func balanceOf(owner: felt) -> (balance: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `balance` | `Uint256` |  |

### ownerOf

`func ownerOf(tokenId: Uint256) -> (owner: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `tokenId` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |

### getApproved

`func getApproved(tokenId: Uint256) -> (approved: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `tokenId` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `approved` | `felt` |  |

### isApprovedForAll

`func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |
| `operator` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `isApproved` | `felt` |  |

### tokenURI

`func tokenURI(tokenId: Uint256) -> (tokenURI: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `tokenId` | `Uint256` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenURI` | `felt` |  |

### owner

`func owner() -> (owner: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |

### paused

`func paused() -> (paused: felt)`


Outputs
| Name | Type | Description |
|------|------|-------------|
| `paused` | `felt` |  |

# External Functions

### approve

`func approve(to: felt, tokenId: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |

### setApprovalForAll

`func setApprovalForAll(operator: felt, approved: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `operator` | `felt` |  |
| `approved` | `felt` |  |

### transferFrom

`func transferFrom(from_: felt, to: felt, tokenId: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |

### safeTransferFrom

`func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |
| `data_len` | `felt` |  |
| `data` | `felt*` |  |

### mint

`func mint(to: felt, tokenId: Uint256)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |

### setTokenURI

`func setTokenURI(tokenId: Uint256, tokenURI: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `tokenId` | `Uint256` |  |
| `tokenURI` | `felt` |  |

### transferOwnership

`func transferOwnership(newOwner: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `newOwner` | `felt` |  |

### renounceOwnership

`func renounceOwnership()`


### pause

`func pause()`


### unpause

`func unpause()`


