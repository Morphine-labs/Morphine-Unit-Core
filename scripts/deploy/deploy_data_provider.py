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

    # print(f'⌛️ Declaring Data Provider...')
    # declare_transaction_dp = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.DP_SOURCE_CODE).read_text(), max_fee=int(1e16)
    # )
    # resp = await admin.declare(transaction=declare_transaction_dp)
    # await admin.wait_for_tx(resp.transaction_hash)
    # dp_class_hash = resp.class_hash

    # print(f'✅ Success! Class Hash: {dp_class_hash} ')
    
    print(f'⌛️ Deploying data Provider...')
    deploy_dp_call, dp = deployer.create_deployment_call(
    class_hash=utils.DP_HASH)
    resp = await admin.execute(deploy_dp_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)
    print(f'✅ Success! Data Provider deployed to {dp} ')

    



loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())