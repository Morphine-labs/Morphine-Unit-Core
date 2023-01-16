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

ERC4626_TOKEN_NAME = 'vault MEth'
ERC4626_TOKEN_SYMBOL = 'MVETH'

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

    # print(f'⌛️ Declaring DRIP...')
    # declare_transaction_drip = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.DRIP_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_drip)
    # await admin.wait_for_tx(resp.transaction_hash)
    # drip_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {drip_class_hash} ')

    # print(f'⌛️ Declaring REGISTERY...')
    # declare_transaction_registery = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.REGISTERY_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_registery)
    # await admin.wait_for_tx(resp.transaction_hash)
    # registery_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {registery_class_hash} ')

    # print(f'⌛️ Declaring DRIP FACTORY...')
    # declare_transaction_drip_factory = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.DRIP_FACTORY_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_drip_factory)
    # await admin.wait_for_tx(resp.transaction_hash)
    # drip_factory_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {drip_factory_class_hash} ')

    print(f'⌛️ Declaring ORACLE_TRANSIT...')
    declare_transaction_oracle_transit = await admin.sign_declare_transaction(
    compilation_source=Path(utils.ORACLE_TRANSIT_SOURCE_CODE).read_text(), max_fee=int(1e16))
    resp = await admin.declare(transaction=declare_transaction_oracle_transit)
    await admin.wait_for_tx(resp.transaction_hash)
    oracle_transit_class_hash = resp.class_hash
    print(f'✅ Success! Class Hash: {oracle_transit_class_hash} ')
    

    # print(f'⌛️ Deploying registery...')
    # deploy_registery_call, registery = deployer.create_deployment_call(
    # class_hash=registery_class_hash,
    # abi=json.loads(Path(utils.REGISTERY_ABI).read_text()),
    # calldata={
    #     "_owner": admin.address,
    #     "_treasury": utils.MORPHINE_TREASURY,
    #     "_oracle_transit": 63,
    #     "_drip_hash": drip_class_hash})
    # resp = await admin.execute(deploy_registery_call, max_fee=int(1e16))
    # await admin.wait_for_tx(resp.transaction_hash)
    # print(f'✅ Success! Registery deployed to {registery} ')

    # print(f'⌛️ Deploying drip factory...')
    # deploy_drip_factory_call, drip_factory = deployer.create_deployment_call(
    # class_hash=drip_factory_class_hash,
    # abi=json.loads(Path(utils.DRIP_FACTORY_ABI).read_text()),
    # calldata={"_registery": registery})
    # resp = await admin.execute(deploy_drip_factory_call, max_fee=int(1e16))
    # await admin.wait_for_tx(resp.transaction_hash)
    # print(f'✅ Success! Drip Factory deployed to {drip_factory} ')

    print(f'⌛️ Deploying oracle transit...')
    deploy_oracle_transit_call, oracle_transit = deployer.create_deployment_call(
    class_hash=oracle_transit_class_hash,
    abi=json.loads(Path(utils.ORACLE_TRANSIT_ABI).read_text()),
    calldata={
        "_oracle": utils.EMPIRIC,
        "_registery": utils.REGISTERY
    })
    resp = await admin.execute(deploy_oracle_transit_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)
    print(f'✅ Success! oracle transit deployed to {oracle_transit} ')


    # registery_contract = await Contract.from_address(client=admin, address=utils.REGISTERY)

    # print(f'⌛️ Setting Oracle Transit for Regsitery...')
    # invocation = await registery_contract.functions["setOracleTransit"].invoke(utils.ORACLE_TRANSIT, max_fee=int(1e16))
    # await invocation.wait_for_acceptance()
    # print(f'✅ Success! ')

    # print(f'⌛️ Setting Drip Factory for Regsitery...')
    # invocation = await registery_contract.functions["setDripFactory"].invoke(utils.DRIP_FACTORY, max_fee=int(1e16))
    # await invocation.wait_for_acceptance()
    # print(f'✅ Success! ')


   


loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())