# View Functions

### modelParameters

`func modelParameters() -> (optimalLiquidityUtilization: Uint256,    baseRate: Uint256,    slope1: Uint256,    slope2: Uint256)`

modelize all the parameters need in order to calculate the interest rate


Outputs
| Name | Type | Description |
|------|------|-------------|
| `optimalLiquidityUtilization` | `Uint256` |    |
| `baseRate` | `Uint256` |    |
| `slope1` | `Uint256` |    |
| `slope2` | `Uint256` |    |

# External Functions

### calcBorrowRate

`func calcBorrowRate(_expected_liqudity: Uint256, _available_liquidity: Uint256) -> (borrowRate: Uint256)`

calculate the borrow rate


Inputs

| Name | Type | Description |
|------|------|-------------|
| `_expected_liqudity` | `Uint256` |  expected liquidity  |
| `_available_liquidity` | `Uint256` |  available liquidity  |

Outputs
| Name | Type | Description |
|------|------|-------------|
| `borrowRate` | `Uint256` |  return the borrow rate  |

