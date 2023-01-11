# View Functions

### getFaucetInfo

`func getFaucetInfo(_user: felt, faucet_array_len: felt, faucet_array: felt*) -> (faucetInfo_len: felt, faucetInfo: FaucetInfo*)`

: getFaucetInfo


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_user` | `felt` |  |
| `faucet_array_len` | `felt` |  |
| `faucet_array` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `faucetInfo_len` | `felt` |    |
| `faucetInfo` | `FaucetInfo*` |    |

### getMinterInfo

`func getMinterInfo(_user: felt, minter_array_len: felt, minter_array: felt*) -> (minterInfo_len: felt, minterInfo: MinterInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_user` | `felt` |  |
| `minter_array_len` | `felt` |  |
| `minter_array` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `minterInfo_len` | `felt` |  |
| `minterInfo` | `MinterInfo*` |  |

### getUserTokens

`func getUserTokens(_registery: felt, _user: felt, token_array_len: felt, token_array: felt*) -> (tokenInfo_len: felt, tokenInfo: TokenInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_registery` | `felt` |  |
| `_user` | `felt` |  |
| `token_array_len` | `felt` |  |
| `token_array` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenInfo_len` | `felt` |  |
| `tokenInfo` | `TokenInfo*` |  |

### getUserPoolTokens

`func getUserPoolTokens(_registery: felt, _user: felt, pool_token_array_len: felt, pool_token_array: felt*) -> (PoolTokenInfo_len: felt, PoolTokenInfo: PoolTokenInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_registery` | `felt` |  |
| `_user` | `felt` |  |
| `pool_token_array_len` | `felt` |  |
| `pool_token_array` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `PoolTokenInfo_len` | `felt` |  |
| `PoolTokenInfo` | `PoolTokenInfo*` |  |

### getUserPass

`func getUserPass(_user: felt, nft_len: felt, nft: felt*) -> (hasNft_len: felt, hasNft: NftInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_user` | `felt` |  |
| `nft_len` | `felt` |  |
| `nft` | `felt*` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `hasNft_len` | `felt` |  |
| `hasNft` | `NftInfo*` |  |

### getUserDripsInfo

`func getUserDripsInfo(_registery: felt, _user: felt) -> (dripInfo_len: felt, dripInfo: DripMiniInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_registery` | `felt` |  |
| `_user` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripInfo_len` | `felt` |  |
| `dripInfo` | `DripMiniInfo*` |  |

### dripListInfo

`func dripListInfo(_registery: felt) -> (dripListInfo_len: felt, dripListInfo: DripListInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_registery` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripListInfo_len` | `felt` |  |
| `dripListInfo` | `DripListInfo*` |  |

### poolListInfo

`func poolListInfo(_registery: felt) -> (pool_info_len: felt, pool_info: PoolInfo*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_registery` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `pool_info_len` | `felt` |  |
| `pool_info` | `PoolInfo*` |  |

### poolInfo

`func poolInfo(_pool: felt) -> (pool_info: PoolInfo)`

: poolInfo


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `pool_info` | `PoolInfo` |    |

### allowedContractsFromPool

`func allowedContractsFromPool(_pool: felt) -> (allowed_contracts_len: felt, allowed_contracts: felt*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `allowed_contracts_len` | `felt` |  |
| `allowed_contracts` | `felt*` |  |

### allowedAssetsFromPool

`func allowedAssetsFromPool(_pool: felt) -> (allowed_assets_len: felt, allowed_assets: AllowedToken*)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `allowed_assets_len` | `felt` |  |
| `allowed_assets` | `AllowedToken*` |  |

### feesFromPool

`func feesFromPool(_pool: felt) -> (fees_info: FeesInfo)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `fees_info` | `FeesInfo` |  |

### limitFromPool

`func limitFromPool(_pool: felt) -> (limit_info: LimitInfo)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `limit_info` | `LimitInfo` |  |

### accessFromPool

`func accessFromPool(_pool: felt) -> (is_permisonless: felt, token_uri: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `is_permisonless` | `felt` |  |
| `token_uri` | `felt` |  |

### expirationFromPool

`func expirationFromPool(_pool: felt) -> (is_expirable: felt, remaining_time: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `is_expirable` | `felt` |  |
| `remaining_time` | `felt` |  |

### userDripFromPool

`func userDripFromPool(_pool: felt, _user: felt) -> (drip: felt)`


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |  |
| `_user` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |  |

