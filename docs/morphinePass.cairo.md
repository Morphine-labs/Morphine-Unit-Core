# View Functions

### totalSupply

`func totalSupply() -> (totalSupply: Uint256)`

: Get the Morphine pass totalSupply


Outputs
| Name | Type | Description |
|------|------|-------------|
| `totalSupply` | `Uint256` |    |

### tokenByIndex

`func tokenByIndex(_index: Uint256) -> (tokenId: Uint256)`

: Get the Morphine pass coresponding to the token id


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_index` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenId` | `Uint256` |    |

### tokenOfOwnerByIndex

`func tokenOfOwnerByIndex(_owner: felt, _index: Uint256) -> (tokenId: Uint256)`

: Get the Morphine pass owner coresponding to the token id


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_owner` | `felt` |    |
| `_index` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenId` | `Uint256` |    |

### supportsInterface

`func supportsInterface(_interfaceId: felt) -> (success: felt)`

: Check if the interface is supported


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_interfaceId` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `success` | `felt` |    |

### name

`func name() -> (name: felt)`

: Get the ERC721 name


Outputs
| Name | Type | Description |
|------|------|-------------|
| `name` | `felt` |    |

### symbol

`func symbol() -> (symbol: felt)`

: Get the ERC721 symbol


Outputs
| Name | Type | Description |
|------|------|-------------|
| `symbol` | `felt` |    |

### balanceOf

`func balanceOf(_owner: felt) -> (balance: Uint256)`

: Get the ERC721 balanceOf


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_owner` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `balance` | `Uint256` |    |

### ownerOf

`func ownerOf(_tokenId: Uint256) -> (owner: felt)`

: Get the ERC721 ownerOf


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_tokenId` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |    |

### getApproved

`func getApproved(_tokenId: Uint256) -> (approved: felt)`

: Approuve your ERC721 token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_tokenId` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `approved` | `felt` |    |

### isApprovedForAll

`func isApprovedForAll(_owner: felt, _operator: felt) -> (isApproved: felt)`

: Check if the operator is approved for all


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_owner` | `felt` |    |
| `_operator` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `isApproved` | `felt` |    |

### tokenURI

`func tokenURI(_tokenId: Uint256) -> (tokenURI: felt)`

: Get the token URI


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_tokenId` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenURI` | `felt` |    |

### baseURI

`func baseURI() -> (baseURI: felt)`

: Get the base URI


Outputs
| Name | Type | Description |
|------|------|-------------|
| `baseURI` | `felt` |    |

### owner

`func owner() -> (owner: felt)`

: Get the owner of the NFT


Outputs
| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |  |

# External Functions

### setMinter

`func setMinter(_minter: felt)`

: Set Minter status


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_minter` | `felt` |    |

### addDripTransit

`func addDripTransit(_drip_transit: felt)`

: add Drip transit 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_transit` | `felt` |    |

### removeDripTransit

`func removeDripTransit(_drip_transit: felt)`

: remove Drip transit


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_transit` | `felt` |    |

### approve

`func approve(to: felt, tokenId: Uint256)`

: Method for SBT should all aways fail


Inputs

| Name | Type | Description |
|------|------|-------------|
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |

### setApprovalForAll

`func setApprovalForAll(operator: felt, approved: felt)`

: Method for SBT should all aways fail


Inputs

| Name | Type | Description |
|------|------|-------------|
| `operator` | `felt` |  |
| `approved` | `felt` |  |

### transferFrom

`func transferFrom(from_: felt, to: felt, tokenId: Uint256)`

: Method for SBT should all aways fail


Inputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |

### safeTransferFrom

`func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*)`

: Method for SBT should all aways fail


Inputs

| Name | Type | Description |
|------|------|-------------|
| `from_` | `felt` |  |
| `to` | `felt` |  |
| `tokenId` | `Uint256` |  |
| `data_len` | `felt` |  |
| `data` | `felt*` |  |

### mint

`func mint(_to: felt, _amount: Uint256)`

: mint NFT


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_to` | `felt` |    |
| `_amount` | `Uint256` |    |

### burn

`func burn(_from: felt, _amount: Uint256)`

: burn NFT


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |    |
| `_amount` | `Uint256` |    |

### setBaseURI

`func setBaseURI(_baseURI: felt)`

: set Base URI NFT


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_baseURI` | `felt` |    |

# Events

### NewMinterSet

`func NewMinterSet(minter: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `minter` | `felt` |  |

### NewDripTransitAdded

`func NewDripTransitAdded(drip_transit: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip_transit` | `felt` |  |

### NewDripTransitRemoved

`func NewDripTransitRemoved(drip_transit: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip_transit` | `felt` |  |

