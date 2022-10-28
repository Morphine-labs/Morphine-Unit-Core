// Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IInterestRateModel {

    func calcBorrowRate(expected_liquidity: Uint256, available_liquidity: Uint256) -> (borrowRate: Uint256) {
    }

    func modelParameters() -> (optimalLiquidityUtilization: Uint256, baseRate: Uint256, slop1: Uint256, slop2: Uint256) {
    }
}
