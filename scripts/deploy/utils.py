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


## CONTRACTS COMPILED 
ERC20_SOURCE_CODE = "../../lib/openzeppelin/token/erc20/presets/ERC20Mintable.cairo"
FAUCET_SOURCE_CODE ="../../lib/utils/faucet.cairo"

## HASH
ERC20_HASH=1515369715480586678371871707714455491518866650338056761811368589140008332440
FAUCET_HASH=1647980243453739192790302298162846929224199636665047613293689882696401554566

## CONTRACTS ABI
ERC20_ABI = "../../build/erc20_abi.json"
FAUCET_ABI ="../../build/faucet_abi.json"


## CONTRACTS ADDRESSES
ETH = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
UD = "0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf"
MDAI_TOKEN = 1343736755528245583556844068241376787306736200839213048599512351803845737954
MDAI_FAUCET = 2782075477786179006318107668768994745145980650246910991540991004842130432355
METH_TOKEN = 2531763062148050252631886495495305907867811931278673729671486857820654632373
METH_FAUCET = 3437507200985476270270551084396656880648881838932408415183233498621812412964