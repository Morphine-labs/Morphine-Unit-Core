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

## ERC20
TOKEN_NAME = 'morphineBTC'
TOKEN_SYMBOL = 'MBTC'
TOKEN_DECIMALS = 18
TOKEN_INITIAL_SUPPLY_LO = (10**6)*10**18
TOKEN_INITIAL_SUPPLY_HI = 0

## FAUCET
ALLOWED_AMOUNT_LO = 2*10**17
ALLOWED_AMOUNT_HI = 0
TIME = 24*60*3600

INITIAL_FUNDING_LO = (10**9)*10**6
INITIAL_FUNDING_HI = 0

ACCOUNT_TO_FEED = 1346467854455685460098999325011621961504244848751031854889451399430175951183

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

    print(f'⌛️ Funding address...')
    erc20_contract = await Contract.from_address(client=admin, address=utils.MDAI_TOKEN)
    invocation = await erc20_contract.functions["transfer"].invoke(ACCOUNT_TO_FEED, {"low":INITIAL_FUNDING_LO, "high":INITIAL_FUNDING_HI}, max_fee=int(1e16))
    await invocation.wait_for_acceptance()

    print(f'✅ Success! Address  has been funded ')
    (balance,) = await erc20_contract.functions["balanceOf"].call(ACCOUNT_TO_FEED)
    print(f'💰 Faucet Balance : {balance} ')



loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())