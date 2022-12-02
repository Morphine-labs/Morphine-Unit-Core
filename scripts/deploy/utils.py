def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")

def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)

def long_str_to_array(text):
    res = []
    for tok in text:
        res.append(str_to_felt(tok))
    return res

def long_str_to_print_array(text):
    res = []
    for tok in text:
        res.append(str_to_felt(tok))
    return ' '.join(res)

def decimal_to_hex(decimal: int):
    return hex(decimal)


## VARIOUS
SALT = 0


## CONTRACTS SOURCE CODE
ERC20_SOURCE_CODE = "../../lib/openzeppelin/token/erc20/presets/ERC20Mintable.cairo"
FAUCET_SOURCE_CODE = "../../lib/utils/faucet.cairo"

## CONTRACTS ABI
ERC20_ABI = "../../build/erc20_abi.json"
FAUCET_ABI ="../../build/faucet_abi.json"



## CONTRACTS ADDRESSES
ETH = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
UD = "0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf"