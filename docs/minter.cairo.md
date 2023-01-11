# View Functions

### isWhitelisted

`func isWhitelisted(_user: felt) -> (state: felt)`

: Check if a user is whitelistedo


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_user` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### hasMinted

`func hasMinted(_user: felt) -> (state: felt)`

: Check if a user has minted


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_user` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### nftContract

`func nftContract() -> (nftContract: felt)`

: get the nft address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `nftContract` | `felt` |    |

# External Functions

### mint

`func mint()`

: mint a NFT


### setWhitelist

`func setWhitelist(_address_len: felt, _address: felt*)`

: Whitelist some user or users


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_address_len` | `felt` |    |
| `_address` | `felt*` |    |

