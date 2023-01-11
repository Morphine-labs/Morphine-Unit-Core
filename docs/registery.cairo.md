# View Functions

### getTreasury

`func getTreasury() -> (treasury : felt)`

: get treasury address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `treasury` | `felt` |    |

### dripFactory

`func dripFactory() -> (drip_factory : felt)`

: get drip factory address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip_factory` | `felt` |    |

### dripHash

`func dripHash() -> (drip_hash : felt)`

: get drip hash address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip_hash` | `felt` |    |

### owner

`func owner() -> (owner : felt)`

: get owner address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `owner` | `felt` |    |

### oracleTransit

`func oracleTransit() -> (oracle : felt)`

: get oracle transit address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `oracle` | `felt` |    |

### isPool

`func isPool(_pool: felt) -> (state : felt)`

: check if address is a pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### isDripManager

`func isDripManager(_drip_manager: felt) -> (state : felt)`

: check if address is a drip manager


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_manager` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### idToPool

`func idToPool(_id: felt) -> (pool : felt)`

: get pool address by id


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `pool` | `felt` |    |

### idToDripManager

`func idToDripManager(_id: felt) -> (dripManager : felt)`

: get drip manager address by id


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripManager` | `felt` |    |

### poolsLength

`func poolsLength() -> (poolsLength : felt)`

: get pools length


Outputs
| Name | Type | Description |
|------|------|-------------|
| `poolsLength` | `felt` |    |

### dripManagerLength

`func dripManagerLength() -> (dripManagerLength : felt)`

: get drip managers length


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripManagerLength` | `felt` |    |

# External Functions

### setOwner

`func setOwner(_new_owner : felt)`

: set new owner


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_owner` | `felt` |    |

### setTreasury

`func setTreasury(_new_treasury: felt)`

: set new treasury address


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_treasury` | `felt` |    |

### setDripFactory

`func setDripFactory(_drip_factory: felt)`

: set new drip factory address


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_factory` | `felt` |    |

### setOracleTransit

`func setOracleTransit(_new_oracle_transit : felt)`

: set new oracle transit address


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_oracle_transit` | `felt` |    |

### setDripHash

`func setDripHash(_new_drip_hash : felt)`

: set new drip hash address


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_drip_hash` | `felt` |    |

### addPool

`func addPool(_pool : felt)`

: add new pool


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_pool` | `felt` |    |

### addDripManager

`func addDripManager(_drip_manager : felt)`

: add new drip manager


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_manager` | `felt` |    |

