from starkware.python.utils import from_bytes
from starkware.crypto.signature.signature import private_to_stark_key, get_random_private_key
import asyncio
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.contract import Contract
from starknet_py.net.udc_deployer.deployer import Deployer
from enum import Enum
from starknet_py.net.models import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import StarkCurveSigner
from starknet_py.utils.docs import as_our_module
from pathlib import Path
import settings
import utils
import json


# LinearRateModel
SLOPE1_LO = 15*10**15
SLOPE1_HI = 0
SLOPE2_LO = 1*10**18
SLOPE2_HI = 0
BASE_RATE_LO =  0
BASE_RATE_HI =  0
OPTIMAL_RATE_LO = 80*10**16
OPTIMAL_RATE_HI = 0

# Pool
POOL_NAME = 'Pool ethereum'
POOL_SYMBOL = 'PETH'
EXPECTED_LIQUIDITY_LIMIT_LO = 2000*10**18
EXPECTED_LIQUIDITY_LIMIT_HI = 0


class _StarknetChainId(Enum):
    MAINNET = from_bytes(b"SN_MAIN")
    TESTNET = from_bytes(b"SN_GOERLI")
    TESTNET_2 = from_bytes(b"SN_GOERLI2")

StarknetChainId = as_our_module(_StarknetChainId)

async def deploy():
    goerli2_client = GatewayClient(net=settings.NET)
    key_pair = KeyPair(private_key=int(settings.PRIVATE_KEY,16), public_key=int(settings.PUBLIC_KEY,16))
    signer = StarkCurveSigner(settings.ADMIN, key_pair, StarknetChainId.TESTNET_2)
    admin = AccountClient(
        client=goerli2_client,
        address=settings.ADMIN,
        key_pair=key_pair,
        signer=signer,
        chain=StarknetChainId.TESTNET_2,
        supported_tx_version=1,
    )    
    
    balance = await admin.get_balance(utils.ETH)
    print(f'💰 User balance: {balance/(10**18)} ETH')

    deployer = Deployer(deployer_address=utils.UD, account_address=admin.address)

    # print(f'⌛️ Declaring Interest Rate Model...')
    # declare_transaction_interest_rate_model = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.INTEREST_RATE_MODEL_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_interest_rate_model)
    # await admin.wait_for_tx(resp.transaction_hash)
    # interest_rate_model_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {interest_rate_model_class_hash} ')

    # print(f'⌛️ Declaring Pool...')
    # declare_transaction_pool = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.POOL_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_pool)
    # await admin.wait_for_tx(resp.transaction_hash)
    # pool_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {pool_class_hash} ')
    

    print(f'⌛️ Deploying Interest Rate Model...')
    deploy_interest_rate_model_call, interest_rate_model = deployer.create_deployment_call(
    class_hash=utils.INTEREST_RATE_MODEL_HASH,
    abi=json.loads(Path(utils.INTEREST_RATE_MODEL_ABI).read_text()),
    calldata={
        "_optimal_liquidity_utilization": {"low":OPTIMAL_RATE_LO, "high":OPTIMAL_RATE_HI},
        "_slope1": {"low":SLOPE1_LO, "high":SLOPE1_HI},
        "_slope2": {"low":SLOPE2_LO, "high":SLOPE2_HI},
        "_base_rate": {"low":BASE_RATE_LO, "high":BASE_RATE_HI}})
    resp = await admin.execute(deploy_interest_rate_model_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)
    print(f'✅ Success! Interest Rate Model deployed to {interest_rate_model} ')


    print(f'⌛️ Deploying Pool...')
    deploy_pool_call, pool = deployer.create_deployment_call(
    class_hash=utils.POOL_HASH,
    abi=json.loads(Path(utils.POOL_ABI).read_text()),
    calldata={
        "_registery": utils.REGISTERY,
        "_asset": utils.METH_TOKEN,
        "_name": POOL_NAME,
        "_symbol": POOL_SYMBOL,
        "_expected_liquidity_limit": {"low":EXPECTED_LIQUIDITY_LIMIT_LO, "high":EXPECTED_LIQUIDITY_LIMIT_HI},
        "_interest_rate_model": interest_rate_model})
    resp = await admin.execute(deploy_pool_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)
    print(f'✅ Success! Pool deployed to {pool} ')

    print(f'⌛️ Saving Pool to registery...')
    registery_contract = await Contract.from_address(client=admin, address=utils.REGISTERY)
    invocation = await registery_contract.functions["addPool"].invoke(pool, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')
   
loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())