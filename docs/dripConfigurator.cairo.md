# View Functions

### allowedContractsLength

`func allowedContractsLength() -> (allowedContractsLength: felt)`

: get allowed contract length


Outputs
| Name | Type | Description |
|------|------|-------------|
| `allowedContractsLength` | `felt` |    |

### idToAllowedContract

`func idToAllowedContract(_id: felt) -> (allowedContract: felt)`

: get id to allowed contract


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_id` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `allowedContract` | `felt` |    |

### allowedContractToId

`func allowedContractToId(_allowed_contract: felt) -> (id: felt)`

: get allowed contract to id


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_allowed_contract` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `id` | `felt` |    |

### isAllowedContract

`func isAllowedContract(_contract: felt) -> (state: felt)`

: check if a contract is allowed


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_contract` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### dripManager

`func dripManager() -> (dripManager: felt)`

: get Drip manager address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripManager` | `felt` |    |

# External Functions

### setMaxEnabledTokens

`func setMaxEnabledTokens(_new_max_enabled_tokens: Uint256)`

: Set the maximum number of tokens that can be allowed

: Should not execeed 256

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_max_enabled_tokens` | `Uint256` |    |

### addToken

`func addToken(_token: felt, _liquidation_threshold: Uint256)`

: Allow a token to be used 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_liquidation_threshold` | `Uint256` |    |

### setLiquidationThreshold

`func setLiquidationThreshold(_token: felt, _liquidation_threshold: Uint256)`

: Set the liquidation threshold for a token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_liquidation_threshold` | `Uint256` |    |

### allowToken

`func allowToken(_token: felt)`

: Allow new tokens to be used


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |

### forbidToken

`func forbidToken(_token: felt)`

: Forbid a token to be used


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |

### allowContract

`func allowContract(_contract: felt, _adapter: felt)`

: Allow a new contract


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_contract` | `felt` |    |
| `_adapter` | `felt` |    |

### forbidContract

`func forbidContract(_contract: felt)`

: Forbid a contract


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_contract` | `felt` |    |

### setLimits

`func setLimits(_minimum_borrowed_amount: Uint256, _maximum_borrowed_amount: Uint256)`

: Set Limit (minimum and maximum that can be borrowed)


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_minimum_borrowed_amount` | `Uint256` |    |
| `_maximum_borrowed_amount` | `Uint256` |    |

### setFees

`func setFees(_fee_interest: Uint256, _fee_liquidation: Uint256, _liquidation_premium: Uint256, _fee_liquidation_expired: Uint256, _liquidation_premium_expired: Uint256)`

: Set Fees


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_fee_interest` | `Uint256` |    |
| `_fee_liquidation` | `Uint256` |    |
| `_liquidation_premium` | `Uint256` |    |
| `_fee_liquidation_expired` | `Uint256` |    |
| `_liquidation_premium_expired` | `Uint256` |    |

### setIncreaseDebtForbidden

`func setIncreaseDebtForbidden(_state: felt)`

: Set Increase Forbidden Debt

: Freeze borrow more and open credit account

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_state` | `felt` |  |

### setLimitPerBlock

`func setLimitPerBlock(_new_limit: Uint256)`

: Set max Borrowed Amount per block


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_limit` | `Uint256` |    |

### setExpirationDate

`func setExpirationDate(_new_expiration_date: felt)`

: Set Drip Expiration Date


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_expiration_date` | `felt` |    |

### addEmergencyLiquidator

`func addEmergencyLiquidator(_liquidator: felt)`

: Emergency liquidation in case 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_liquidator` | `felt` |    |

### removeEmergencyLiquidator

`func removeEmergencyLiquidator(_liquidator: felt)`

: Remove emergency liquidator


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_liquidator` | `felt` |    |

### upgradeOracleTransit

`func upgradeOracleTransit()`

: Upgrade Oracle transit


### upgradeDripTransit

`func upgradeDripTransit(_drip_transit: felt, _migrate_parameters: felt)`

: Upgrade Drip Transit


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_transit` | `felt` |    |
| `_migrate_parameters` | `felt` |    |

### upgradeConfigurator

`func upgradeConfigurator(_drip_configurator: felt)`

: Upgrade Drip Configurator


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_configurator` | `felt` |    |

# Events

### maxEnabledTokensSet

`func maxEnabledTokensSet(max_enabled_tokens: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `max_enabled_tokens` | `Uint256` |  |

### TokenAllowed

`func TokenAllowed(token: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |  |

### TokenForbidden

`func TokenForbidden(token: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |  |

### ContractAllowed

`func ContractAllowed(contract: felt, adapter: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `contract` | `felt` |  |
| `adapter` | `felt` |  |

### ContractForbidden

`func ContractForbidden(contract: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `contract` | `felt` |  |

### LimitsUpdated

`func LimitsUpdated(minimum_borrowed_amount: Uint256, maximum_borrowed_amount: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `minimum_borrowed_amount` | `Uint256` |  |
| `maximum_borrowed_amount` | `Uint256` |  |

### LimitPerBlockUpdated

`func LimitPerBlockUpdated(limit_per_block: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `limit_per_block` | `Uint256` |  |

### FastCheckFeesUpdated

`func FastCheckFeesUpdated(chi_threshold: Uint256, hf_check_interval: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `chi_threshold` | `Uint256` |  |
| `hf_check_interval` | `Uint256` |  |

### FeesUpdated

`func FeesUpdated(fee_interest: Uint256, fee_liquidation: Uint256, liquidation_premium: Uint256, fee_liquidation_expired: Uint256, liquidation_premium_expired: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `fee_interest` | `Uint256` |  |
| `fee_liquidation` | `Uint256` |  |
| `liquidation_premium` | `Uint256` |  |
| `fee_liquidation_expired` | `Uint256` |  |
| `liquidation_premium_expired` | `Uint256` |  |

### OracleTransitUpgraded

`func OracleTransitUpgraded(oracle: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `oracle` | `felt` |  |

### DripTransitUpgraded

`func DripTransitUpgraded(drip_transit: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip_transit` | `felt` |  |

### DripConfiguratorUpgraded

`func DripConfiguratorUpgraded(drip_configurator: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `drip_configurator` | `felt` |  |

### TokenLiquidationThresholdUpdated

`func TokenLiquidationThresholdUpdated(token: felt, liquidation_threshold: Uint256)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |  |
| `liquidation_threshold` | `Uint256` |  |

### IncreaseDebtForbiddenStateChanged

`func IncreaseDebtForbiddenStateChanged(state: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |  |

### ExpirationDateUpdated

`func ExpirationDateUpdated(expiration_date: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `expiration_date` | `felt` |  |

### EmergencyLiquidatorAdded

`func EmergencyLiquidatorAdded(liquidator: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `liquidator` | `felt` |  |

### EmergencyLiquidatorRemoved

`func EmergencyLiquidatorRemoved(liquidator: felt)`


Outputs

| Name | Type | Description |
|------|------|-------------|
| `liquidator` | `felt` |  |

