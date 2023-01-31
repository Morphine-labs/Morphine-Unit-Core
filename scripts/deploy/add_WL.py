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
# WL_ADDRESSES = [1900385951641909016294557771160805230279974852683230073741824079343062515185, 1346467854455685460098999325011621961504244848751031854889451399430175951183, 1935063120963007651720444207357493815736729447667659013124670965324844680863, 2846417304015367565224703477906543256941037536794629011019627518135445046171]
WL_ADDRESSES = [ 2595978338574690111866514021249457577777356836403857594850764455231425651579]


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

    print(f'⌛️ adding WL...')
    minter_contract = await Contract.from_address(client=admin, address=utils.DAI_MINTER)
    invocation = await minter_contract.functions["setWhitelist"].invoke(WL_ADDRESSES, max_fee=int(1e16))
    await invocation.wait_for_acceptance()
    print(f'✅ Success! ')


loop = asyncio.get_event_loop()
loop.run_until_complete(call())