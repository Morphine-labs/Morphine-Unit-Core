# View Functions

### isPaused

`func isPaused() -> (state : felt)`

: Is Paused


Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### underlying

`func underlying() -> (underlying: felt)`

: Underlying Token


Outputs
| Name | Type | Description |
|------|------|-------------|
| `underlying` | `felt` |    |

### allowedTokensLength

`func allowedTokensLength() -> (tokenLength: felt)`

: Allowed Token Length


Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenLength` | `felt` |    |

### maxAllowedTokensLength

`func maxAllowedTokensLength() -> (maxAllowedTokenLength: Uint256)`

: Max Allowed Tokens Length per drip


Outputs
| Name | Type | Description |
|------|------|-------------|
| `maxAllowedTokenLength` | `Uint256` |    |

### tokenMask

`func tokenMask(_token: felt) -> (tokenMask: Uint256)`

: Token Mask

: token to 2**index_token

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `tokenMask` | `Uint256` |    |

### enabledTokensMap

`func enabledTokensMap(_drip: felt) -> (enabledTokens: Uint256)`

: Drip Enabled Tokens Mask


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `enabledTokens` | `Uint256` |    |

### forbiddenTokenMask

`func forbiddenTokenMask() -> (forbiddenTokenMask: Uint256)`

: Forbidden Token Mask


Outputs
| Name | Type | Description |
|------|------|-------------|
| `forbiddenTokenMask` | `Uint256` |    |

### tokenByMask

`func tokenByMask(_token_mask: Uint256) -> (token: felt)`

: Token by Mask


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token_mask` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |    |

### tokenById

`func tokenById(_id: felt) -> (token: felt)`

: Token by Mask


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `token` | `felt` |    |

### liquidationThreshold

`func liquidationThreshold(_token: felt) -> (LiquidationThreshold: Uint256)`

: Liquidation Threshold


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `LiquidationThreshold` | `Uint256` |    |

### liquidationThresholdByMask

`func liquidationThresholdByMask(_token_mask: Uint256) -> (LiquidationThreshold: Uint256)`

: Liquidation Threshold By Mask


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token_mask` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `LiquidationThreshold` | `Uint256` |    |

### liquidationThresholdById

`func liquidationThresholdById(_id: felt) -> (LiquidationThreshold: Uint256)`

: Liquidation Threshold By ID


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_id` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `LiquidationThreshold` | `Uint256` |    |

### adapterToContract

`func adapterToContract(_adapter: felt) -> (contract: felt)`

: adapter to Contract


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_adapter` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `contract` | `felt` |    |

### contractToAdapter

`func contractToAdapter(_contract: felt) -> (adapter: felt)`

: Contract to Adapter


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_contract` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `adapter` | `felt` |    |

### feeInterest

`func feeInterest() -> (feeInterest: Uint256)`

: Fee Interest


Outputs
| Name | Type | Description |
|------|------|-------------|
| `feeInterest` | `Uint256` |    |

### feeLiquidation

`func feeLiquidation() -> (feeLiquidation: Uint256)`

: Fee Liquidation


Outputs
| Name | Type | Description |
|------|------|-------------|
| `feeLiquidation` | `Uint256` |    |

### feeLiquidationExpired

`func feeLiquidationExpired() -> (feeLiquidationExpired: Uint256)`

: Fee Liquidation Expired


Outputs
| Name | Type | Description |
|------|------|-------------|
| `feeLiquidationExpired` | `Uint256` |    |

### liquidationDiscount

`func liquidationDiscount() -> (liquidationDiscount: Uint256)`

: Liquidation Discount


Outputs
| Name | Type | Description |
|------|------|-------------|
| `liquidationDiscount` | `Uint256` |    |

### liquidationDiscountExpired

`func liquidationDiscountExpired() -> (liquidationDiscountExpired: Uint256)`

: Liquidation Discount Expired


Outputs
| Name | Type | Description |
|------|------|-------------|
| `liquidationDiscountExpired` | `Uint256` |    |

### canLiquidateWhilePaused

`func canLiquidateWhilePaused(_liquidator: felt) -> (state: felt)`

: Can Liquidate While Paused 

: Checks emergency liquidators

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_liquidator` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |    |

### getPool

`func getPool() -> (pool: felt)`

: Get Pool


Outputs
| Name | Type | Description |
|------|------|-------------|
| `pool` | `felt` |    |

### dripTransit

`func dripTransit() -> (dripTransit: felt)`

: Drip Transit


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripTransit` | `felt` |    |

### dripConfigurator

`func dripConfigurator() -> (dripConfigurator: felt)`

: Drip Configurator


Outputs
| Name | Type | Description |
|------|------|-------------|
| `dripConfigurator` | `felt` |    |

### oracleTransit

`func oracleTransit() -> (oracleTransit: felt)`

: Oracle Transit


Outputs
| Name | Type | Description |
|------|------|-------------|
| `oracleTransit` | `felt` |    |

### getDrip

`func getDrip(_borrower: felt) -> (drip: felt)`

: Get Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |    |

### getDripOrRevert

`func getDripOrRevert(_borrower: felt) -> (drip: felt)`

: Get Drip Or Revert

: revert if borrower has no drip

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |    |

### dripParameters

`func dripParameters(_drip: felt) -> (borrowedAmount: Uint256, cumulativeIndex: Uint256, currentCumulativeIndex: Uint256)`

: Drip Parameters


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `borrowedAmount` | `Uint256` |    |
| `cumulativeIndex` | `Uint256` |    |
| `currentCumulativeIndex` | `Uint256` |    |

### calcDripAccruedInterest

`func calcDripAccruedInterest(_drip: felt) -> (borrowedAmount: Uint256, borrowedAmountWithInterest: Uint256, borrowedAmountWithInterestAndFees: Uint256)`

: Calcul Drip Accrued Interest


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `borrowedAmount` | `Uint256` |    |
| `borrowedAmountWithInterest` | `Uint256` |    |
| `borrowedAmountWithInterestAndFees` | `Uint256` |    |

### calcClosePayments

`func calcClosePayments(_total_value: Uint256,    _type: felt,    _borrowed_amount: Uint256,    _borrowed_amount_with_interests: Uint256) -> (amountToPool: Uint256, remainingFunds: Uint256, profit: Uint256, loss: Uint256)`

: Calcul Close Payments


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_total_value` | `Uint256` |    |
| `_type` | `felt` |  0 and other: ordinary closure type 1: liquidation, 2: drip expired liquidation, 3: pause liquidation (felt)  |
| `_borrowed_amount` | `Uint256` |    |
| `_borrowed_amount_with_interests` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `amountToPool` | `Uint256` |    |
| `remainingFunds` | `Uint256` |    |
| `profit` | `Uint256` |    |
| `loss` | `Uint256` |    |

### get_max_index

`func get_max_index(_mask: Uint256) -> (max_index: Uint256)`

: get_max_index


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_mask` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `max_index` | `Uint256` |    |

### calc_enabled_tokens

`func calc_enabled_tokens(_enabled_tokens: Uint256, _cum_total_tokens_enabled: Uint256) -> (total_tokens_enabled: Uint256)`

: calc_enabled_tokens


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_enabled_tokens` | `Uint256` |    |
| `_cum_total_tokens_enabled` | `Uint256` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `total_tokens_enabled` | `Uint256` |    |

# External Functions

### pause

`func pause()`

: Pause Contract


### unpause

`func unpause()`

: Unpause Contract


### checkEmergencyPausable

`func checkEmergencyPausable(_caller: felt, _state: felt) -> (state: felt)`

: Set emergency liquidator while pause if caller allowed


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_caller` | `felt` |  |
| `_state` | `felt` |  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `state` | `felt` |  |

### openDrip

`func openDrip(_borrowed_amount: Uint256, _on_belhalf_of: felt) -> (drip: felt)`

: Open Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrowed_amount` | `Uint256` |    |
| `_on_belhalf_of` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip` | `felt` |    |

### closeDrip

`func closeDrip(_borrower: felt, _type: felt, _total_value: Uint256, _payer: felt, _to: felt) -> (remainingFunds: Uint256)`

: Close Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |
| `_type` | `felt` |  0 and other: ordinary closure type 1: liquidation, 2: drip expired liquidation, 3: pause liquidation (felt)  |
| `_total_value` | `Uint256` |    |
| `_payer` | `felt` |    |
| `_to` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `remainingFunds` | `Uint256` |    |

### addCollateral

`func addCollateral(_payer: felt, _drip: felt, _token: felt, _amount: Uint256)`

: Add Collateral 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_payer` | `felt` |    |
| `_drip` | `felt` |    |
| `_token` | `felt` |    |
| `_amount` | `Uint256` |    |

### manageDebt

`func manageDebt(_drip: felt, _amount: Uint256, _increase: felt) -> (newBorrowedAmount: Uint256)`

: Manage Debt 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |
| `_amount` | `Uint256` |    |
| `_increase` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `newBorrowedAmount` | `Uint256` |    |

### approveDrip

`func approveDrip(_borrower: felt, _target: felt, _token: felt, _amount: Uint256)`

: Approve Drip


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |
| `_target` | `felt` |    |
| `_token` | `felt` |    |
| `_amount` | `Uint256` |    |

### executeOrder

`func executeOrder(_borrower: felt, _to: felt, _selector: felt, _calldata_len: felt, _calldata: felt*) -> (retdata_len: felt, retdata: felt*)`

: Check Allowance and Execute order


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_borrower` | `felt` |    |
| `_to` | `felt` |    |
| `_selector` | `felt` |    |
| `_calldata_len` | `felt` |    |
| `_calldata` | `felt*` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `retdata_len` | `felt` |    |
| `retdata` | `felt*` |    |

### checkAndEnableToken

`func checkAndEnableToken(_drip: felt, _token: felt)`

: Check Allowance and Enable token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |
| `_token` | `felt` |    |

### disableToken

`func disableToken(_drip: felt,    _token: felt) -> (wasChanged: felt)`

: Disable Token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |
| `_token` | `felt` |    |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `wasChanged` | `felt` |    |

### transferDripOwnership

`func transferDripOwnership(_from: felt, _to: felt)`

: transfer Drip Ownership 


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_from` | `felt` |    |
| `_to` | `felt` |    |

### fullCollateralCheck

`func fullCollateralCheck(_drip: felt)`

: Full Collateral Check

: Check Drip holding to make sure there is enough collateral, can potentially disble tokens

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

### checkAndOptimizeEnabledTokens

`func checkAndOptimizeEnabledTokens(_drip: felt)`

: Check And Optimize Enabled Tokens

: Check not too much tokens and remove some if necessary

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip` | `felt` |    |

### addToken

`func addToken(_token: felt)`

: Add Token


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |

### setFees

`func setFees(_fee_interest: Uint256,    _fee_liquidation: Uint256,    _liquidation_discount: Uint256,    _fee_liquidation_expired: Uint256,    _liquidation_discount_expired: Uint256)`

: Set Fees


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_fee_interest` | `Uint256` |    |
| `_fee_liquidation` | `Uint256` |    |
| `_liquidation_discount` | `Uint256` |    |
| `_fee_liquidation_expired` | `Uint256` |    |
| `_liquidation_discount_expired` | `Uint256` |    |

### setLiquidationThreshold

`func setLiquidationThreshold(_token: felt, _liquidation_threshold: Uint256)`

: Set Liquidation threshold


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_token` | `felt` |    |
| `_liquidation_threshold` | `Uint256` |    |

### setForbidMask

`func setForbidMask(_fobid_mask: Uint256)`

: Set Forbid Mask

: A drip holding forbidden tokens have limited allowed interactions

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_fobid_mask` | `Uint256` |    |

### setMaxEnabledTokens

`func setMaxEnabledTokens(_new_max_enabled_tokens: Uint256)`

: Set Max Enabled Tokens


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_new_max_enabled_tokens` | `Uint256` |    |

### changeContractAllowance

`func changeContractAllowance(_adapter: felt, _target: felt)`

: Change Contract Allowance

: This function is use to add or remove allowed integrations

Inputs

| Name | Type | Description |
|------|------|-------------|
| `_adapter` | `felt` |    |
| `_target` | `felt` |    |

### upgradeOracleTransit

`func upgradeOracleTransit(_oracle_transit: felt)`

: Upgrade Oracle Transit


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_oracle_transit` | `felt` |    |

### upgradeDripTransit

`func upgradeDripTransit(_drip_transit: felt)`

: Upgrade Drip Transit


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_transit` | `felt` |    |

### setConfigurator

`func setConfigurator(_drip_configurator: felt)`

: Upgrade Drip Configurator


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_configurator` | `felt` |    |

### addEmergencyLiquidator

`func addEmergencyLiquidator(_liquidator: felt)`

: Add Emergency Liquidator


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_liquidator` | `felt` |    |

### removeEmergencyLiquidator

`func removeEmergencyLiquidator(_liquidator: felt)`

: Remove Emergency Liquidator


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_liquidator` | `felt` |    |

