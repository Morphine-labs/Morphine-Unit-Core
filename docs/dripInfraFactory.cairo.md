# View Functions

### getDripInfraAddresses

`func getDripInfraAddresses() -> (drip_manager: felt, drip_transit: felt, drip_configurator: felt)`

: Get Drip Infra Address


Outputs
| Name | Type | Description |
|------|------|-------------|
| `drip_manager` | `felt` |    |
| `drip_transit` | `felt` |    |
| `drip_configurator` | `felt` |    |

# External Functions

### deployDripInfra

`func deployDripInfra(_drip_infra_factory: felt,         _pool: felt,         _nft: felt,        _expirable: felt,        _minimum_borrowed_amount: Uint256,        _maximum_borrowed_amount: Uint256,        _allowed_tokens_len: felt,        _allowed_tokens: AllowedToken*,        _salt: felt)`

Deploy the DripManager contract.


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_drip_infra_factory` | `felt` |    |
| `_pool` | `felt` |    |
| `_nft` | `felt` |    |
| `_expirable` | `felt` |    |
| `_minimum_borrowed_amount` | `Uint256` |    |
| `_maximum_borrowed_amount` | `Uint256` |    |
| `_allowed_tokens_len` | `felt` |    |
| `_allowed_tokens` | `AllowedToken*` |    |
| `_salt` | `felt` |    |

