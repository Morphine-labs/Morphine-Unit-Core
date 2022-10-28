%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin


struct InfoStruct{
    price: felt,
    decimals: felt,
    last_updated_timestamp: felt,
    num_sources_aggregated: felt,
}

@storage_var
func pair_info(pair_id: felt) -> (info: InfoStruct) {
}

@view
func get_spot_median{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(pair_id: felt) -> (
    price: felt, 
    decimals: felt, 
    last_updated_timestamp: felt, 
    num_sources_aggregated: felt){
    alloc_locals;
    let (info_struct_) = pair_info.read(pair_id);
    return(info_struct_.price, info_struct_.decimals, info_struct_.last_updated_timestamp, info_struct_.num_sources_aggregated,);
} 

@external
func set_spot_median{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _pair_id: felt,
    _price: felt, 
    _decimals: felt, 
    _last_updated_timestamp: felt, 
    _num_sources_aggregated: felt) {
    pair_info.write(_pair_id, InfoStruct(_price, _decimals, _last_updated_timestamp, _num_sources_aggregated));
    return();
}
