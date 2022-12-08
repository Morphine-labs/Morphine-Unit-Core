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
FAUCET_SOURCE_CODE ="../../lib/utils/faucet.cairo"
DP_SOURCE_CODE="../../lib/morphine/utils/dataProvider.cairo"
ERC4626_SOURCE_CODE = "../../tests/mocks/erc4626.cairo"
EMPIRIC_ORACLE_SOURCE_CODE = "../../tests/mocks/empiricOracle.cairo"
DRIP_SOURCE_CODE="../../lib/morphine/drip/drip.cairo"
ERC4626_PRICE_FEED_SOURCE_CODE = "../../lib/morphine/oracle/derivativePriceFeed/erc4626.cairo"
REGISTERY_SOURCE_CODE = "../../lib/morphine/registery.cairo"
DRIP_FACTORY_SOURCE_CODE = "../../lib/morphine/drip/dripFactory.cairo"
ORACLE_TRANSIT_SOURCE_CODE = "../../lib/morphine/oracle/oracleTransit.cairo"
INTEREST_RATE_MODEL_SOURCE_CODE = "../../lib/morphine/pool/linearInterestRateModel.cairo"
POOL_SOURCE_CODE = "../../lib/morphine/pool/pool.cairo"
PASS_SOURCE_CODE = "../../lib/morphine/token/morphinePass.cairo"
MINTER_SOUCRE_CODE = "../../lib/morphine/token/minter.cairo"
DRIP_MANAGER_SOURCE_CODE = "../../lib/drip/dripManager.cairo"
DRIP_TRANSIT_SOURCE_CODE = "../../lib/drip/dripTransit.cairo"
DRIP_CONFIGURATOR_SOURCE_CODE = "../../lib/drip/dripConfigurator.cairo"
DRIP_INFRA_FACTORY_SOURCE_CODE = "../../lib/deployment/dripInfraFactory.cairo"


## HASH
ERC20_HASH=1515369715480586678371871707714455491518866650338056761811368589140008332440
FAUCET_HASH=1647980243453739192790302298162846929224199636665047613293689882696401554566
DP_HASH=3478916000735860908178919372784063811911741764536794130924548778064381256941
EMPIRIC_HASH = 5755831660708856892810427071180638230886885985735079627958382952945798945
ERC4626_HASH = 3177736643056838684957359654467894140894092331386636448138632244448481031098
ERC4626_PRICE_FEED_HASH = 3456996936454517072155935217253182389372587970966916468873658483681202499880
DRIP_HASH = 3470768313806998412707504545215648081657424043867684497421112488270557126616
REGISTERY_HASH = 1288233144853942835256639887824459106824078942442917350611588728975210655140
DRIP_FACTORY_HASH = 3212209140101738968637559516396157847660880131085211319939476192782848287622
ORACLE_TRANSIT_HASH = 1102954667229741963948847799486493325283950793995721023205953120841037500137
INTEREST_RATE_MODEL_HASH = 1082642635321285981211985190038968243353495468799428202225732642323319566301
POOL_HASH = 2068719357389587093117220843425794625257440204655673718455302627313576042071


## CONTRACTS ABI
ERC20_ABI = "../../build/erc20_abi.json"
FAUCET_ABI ="../../build/faucet_abi.json"
ERC4626_ABI ="../../build/erc4626_abi.json"
ORACLE_TRANSIT_ABI = "../../build/oracle_transit_abi.json"
REGISTERY_ABI = "../../build/registery_abi.json"
DRIP_FACTORY_ABI = "../../build/drip_factory_abi.json"
INTEREST_RATE_MODEL_ABI= "../../build/interest_rate_model_abi.json"
POOL_ABI= "../../build/pool_abi.json"
PASS_ABI= "../../build/pass_abi.json"
MINTER_ABI = "../../build/minter_abi.json"
DRIP_MANAGER_ABI = "../../build/drip_manager_abi.json"
DRIP_CONFIGURATOR_ABI = "../../build/drip_configurator_abi.json"
DRIP_TRANSIT_ABI = "../../build/drip_transit_abi.json"
DRIP_INFRA_FACTORY_ABI = "../../build/drip_infra_factory_abi.json"






## CONTRACT ADDRESSES TOKEN
MDAI_TOKEN = 1343736755528245583556844068241376787306736200839213048599512351803845737954
MDAI_FAUCET = 2782075477786179006318107668768994745145980650246910991540991004842130432355
METH_TOKEN = 2531763062148050252631886495495305907867811931278673729671486857820654632373
METH_FAUCET = 3437507200985476270270551084396656880648881838932408415183233498621812412964
VMETH = 3446502081995786345634146805122248791347638340202520965030638671516998580902

## CONTRACT ADDRESSES
ETH = 2087021424722619777119509474943472645767659996348769578120564519014510906823
UD = "0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf"

## CONTRACT ADDRESSES MORPHINE 
DP = 3259210152190599364573643904097557845956993778887948693993689170467938495292
EMPIRIC = 3192999979809713360859433670175671629845112645681593563478436841098137933103
ERC4626_PRICE_FEED = 2047635248313878453958284951015662486494385192215501297325413794656612859354
MORPHINE_TREASURY = 1063295380747518586658370424749994928222764270094741700145566703757650981707
REGISTERY = 518186857286480997042134318740742945484555217897153472954903189151185344668
DRIP_FACTORY = 329371139683704594979494494179676512830734507737315551474196441869549755171
ORACLE_TRANSIT = 2240990798020187506540983177006033876777311404260591869591592097798926375786

## POOL DAI
INTEREST_RATE_MODEL_POOL_DAI = 998563234458507610642893064737107816755932959908947504191062285667893227699
POOL_DAI = 1028323746011883363607633224752822332974491302529220781512557136142961560265

## POOL ETH


## TOKEN KEYS
ETH_USD = 19514442401534788
BTC_USD = 18669995996566340
DAI_USD = 28254602066752356

## TOKEN PRICE
ETH_PRICE = 100000000000
BTC_PRICE = 2000000000000
DAI_PRICE = 100000000
