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
TOKEN_ADDRESS = utils.VMETH
MIN = {"low": 100000000, "high": 0}
MAX = {"low": 30000000000, "high": 0}

# MINIMUM_BORROWED_AMOUNT_LO = 100000000
# MINIMUM_BORROWED_AMOUNT_HI = 0
# MAXIMUM_BORROWED_AMOUNT_LO = 1000000000000
# MAXIMUM_BORROWED_AMOUNT_HI = 0

class _StarknetChainId(Enum):
    MAINNET = from_bytes(b"SN_MAIN")
    TESTNET = from_bytes(b"SN_GOERLI")
    TESTNET_2 = from_bytes(b"SN_GOERLI2")


StarknetChainId = as_our_module(_StarknetChainId)


async def call():
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

    print(f'⌛️ update Limits...')
    drip_configurator_contract = await Contract.from_address(client=admin, address=utils.DAI_DRIP_CONFIGURATOR)
    invocation = await drip_configurator_contract.functions["setLimits"].invoke(MIN, MAX, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')


loop = asyncio.get_event_loop()
loop.run_until_complete(call())