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
# TARGET_1 = utils.ROOTER_JEDISWAP
# ADAPTER_1 = utils.ETH_JEDISWAP_ADAPTER

TARGET_2 = utils.VMETH
ADAPTER_2 = utils.DAI_ERC4626_ADAPTER

TARGET_3 = utils.POOL_BTC
ADAPTER_3 = utils.DAI_ERC4626_BTC_ADAPTER

TARGET_4 = utils.POOL_DAI
ADAPTER_4 = utils.DAI_ERC4626_DAI_ADAPTER

TARGET_5 = utils.POOL_ETH
ADAPTER_5 = utils.DAI_ERC4626_ETH_ADAPTER




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

    # print(f'⌛️ Add allowed contract...')
    drip_configurator_contract = await Contract.from_address(client=admin, address=utils.DAI_DRIP_CONFIGURATOR)

    # invocation = await drip_configurator_contract.functions["allowContract"].invoke(TARGET_1, ADAPTER_1, max_fee=int(1e16))
    # await invocation.wait_for_acceptance()
    # print(f'✅ Success! ')

    print(f'⌛️ Add allowed contract...')
    invocation = await drip_configurator_contract.functions["allowContract"].invoke(TARGET_2, ADAPTER_2, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')

    print(f'⌛️ Add allowed contract...')
    invocation = await drip_configurator_contract.functions["allowContract"].invoke(TARGET_3, ADAPTER_3, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')

    print(f'⌛️ Add allowed contract...')
    invocation = await drip_configurator_contract.functions["allowContract"].invoke(TARGET_4, ADAPTER_4, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')

    print(f'⌛️ Add allowed contract...')
    invocation = await drip_configurator_contract.functions["allowContract"].invoke(TARGET_5, ADAPTER_5, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')


loop = asyncio.get_event_loop()
loop.run_until_complete(call())