%lang starknet

from starkware.cairo.common.math import assert_nn, assert_le
from starkware.cairo.common.cairo_builtins import HashBuiltin


// Precision x 1.000.000

@storage_var
func optimal_utilization() -> (res : felt):
end

@storage_var
func base_rate() -> (res : felt):
end

@storage_var
func base_slop1() -> (res : felt):
end

@storage_var
func base_slop2() -> (res : felt):
end

const PRECISION = 10**6

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _optimal_utilization: felt,
        _base_rate: felt,
        _base_slop1: felt,
        _base_slop2: felt,
        ):

    with_attr error_message("Parameter must be lower than 1.000.000"):
        assert_le(optimal_utilization, PRECISION)
    end
    with_attr error_message("Parameter must be lower than 1.000.000"):
        assert_le(base_rate, PRECISION)
    end
    with_attr error_message("Parameter must be lower than 1.000.000"):
        assert_le(base_slop1, PRECISION)
    end
    with_attr error_message("Parameter must be lower than 1.000.000"):
        assert_le(base_slop2, PRECISION)
    end

    optimal_utilization.write(_optimal_utilization);
    base_rate.write(_base_rate);
    base_slop1.write(_base_slop1);
    base_slop2.write(_base_slop2);
    return ()
end

@external
func borrowRate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        amount : felt):
    with_attr error_message("Amount must be positive. Got: {amount}."):
        assert_nn(amount)
    end

    let (res) = balance.read()
    balance.write(res + amount)
    return ()
end


@view
func poolParameters{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        optimal_utilization: felt,
        base_rate: felt,
        base_slop1: felt,
        base_slop2: felt):

    let (optimal_utilization_) = optimal_utilization.read()
    let (base_rate_) = base_rate.read();
    let (base_slop1_) = base_slop1.read();
    let (base_slop2_) = base_slop2.read();
    return (optimal_utilization_, base_rate_, base_slop1_, base_slop2_)
end