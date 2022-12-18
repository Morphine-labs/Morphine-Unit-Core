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


# NFT
PASS_TOKEN_NAME = 'morphine_pool_access'
PASS_TOKEN_SYMBOL = 'MPA'

MINIMUM_BORROWED_AMOUNT_LO = 500000000000000000
MINIMUM_BORROWED_AMOUNT_HI = 0
MAXIMUM_BORROWED_AMOUNT_LO = 50000000000000000000
MAXIMUM_BORROWED_AMOUNT_HI = 0


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

    # print(f'⌛️ Declaring Pass...')
    # declare_transaction_pass = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.PASS_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_pass)
    # await admin.wait_for_tx(resp.transaction_hash)
    # pass_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {pass_class_hash} ')

    # print(f'⌛️ Declaring Minter...')
    # declare_transaction_minter = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.MINTER_SOUCRE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_minter)
    # await admin.wait_for_tx(resp.transaction_hash)
    # minter_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {minter_class_hash} ')

    # print(f'⌛️ Declaring Drip Manager...')
    # declare_transaction_drip_manager = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.DRIP_MANAGER_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_drip_manager)
    # await admin.wait_for_tx(resp.transaction_hash)
    # drip_manager_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {drip_manager_class_hash} ')

    # print(f'⌛️ Declaring Drip Transit...')
    # declare_transaction_drip_transit = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.DRIP_TRANSIT_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_drip_transit)
    # await admin.wait_for_tx(resp.transaction_hash)
    # drip_transit_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {drip_transit_class_hash} ')

    # print(f'⌛️ Declaring Drip Configurator...')
    # declare_transaction_drip_configurator = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.DRIP_CONFIGURATOR_SOURCE_CODE).read_text(), max_fee=int(1e16))
    # resp = await admin.declare(transaction=declare_transaction_drip_configurator)
    # await admin.wait_for_tx(resp.transaction_hash)
    # drip_configurator_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {drip_configurator_class_hash} ')

    print(f'⌛️ Declaring dripInfraFactory...')
    declare_transaction_drip_infra_factory = await admin.sign_declare_transaction(
    compilation_source=Path(utils.DRIP_INFRA_FACTORY_SOURCE_CODE).read_text(), max_fee=int(1e16))
    resp = await admin.declare(transaction=declare_transaction_drip_infra_factory)
    await admin.wait_for_tx(resp.transaction_hash)
    drip_infra_factory_class_hash = resp.class_hash
    print(f'✅ Success! Class Hash: {drip_infra_factory_class_hash} ')

    # print(f'⌛️ Deploying Pass...')
    # deploy_pass_call, pass_ = deployer.create_deployment_call(
    # class_hash=utils.PASS_HASH,
    # abi=json.loads(Path(utils.PASS_ABI).read_text()),
    # calldata={
    #     "_name": PASS_TOKEN_NAME,
    #     "_symbol": PASS_TOKEN_SYMBOL,
    #     "_registery": utils.REGISTERY})
    # resp = await admin.execute(deploy_pass_call, max_fee=int(1e16))
    # await admin.wait_for_tx(resp.transaction_hash)
    # print(f'✅ Success! Pass deployed to {pass_} ')

    # print(f'⌛️ Deploying Minter...')
    # deploy_minter_call, minter_ = deployer.create_deployment_call(
    # class_hash=utils.MINTER_HASH,
    # abi=json.loads(Path(utils.MINTER_ABI).read_text()),
    # calldata={"_nft_contract": pass_})
    # resp = await admin.execute(deploy_minter_call, max_fee=int(1e16))
    # await admin.wait_for_tx(resp.transaction_hash)
    # print(f'✅ Success! Minter deployed to {minter_} ')

    print(f'⌛️ Deploying Drip Infra Factory...')
    deploy_drip_infra_factory_call, drip_infra_factory = deployer.create_deployment_call(
    class_hash=drip_infra_factory_class_hash,
    abi=json.loads(Path(utils.DRIP_INFRA_FACTORY_ABI).read_text()),
    calldata={"_drip_manager_hash": utils.DRIP_MANAGER_HASH,
            "_drip_transit_hash": utils.DRIP_TRANSIT_HASH,
            "_drip_configurator_hash": utils.DRIP_CONFIGURATOR_HASH})
    resp = await admin.execute(deploy_drip_infra_factory_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)
    print(f'✅ Success! Drip Infra Factory deployed to {drip_infra_factory} ')

    drip_infra_factory_contract = await Contract.from_address(client=admin, address=drip_infra_factory)

    print(f'⌛️ Deploying Drip Manager, Drip Transit and Drip Configurator...')
    invocation = await drip_infra_factory_contract.functions["deployDripInfra"].invoke(
        drip_infra_factory, 
        utils.POOL_DAI,
        utils.PASS, 
        1,
        {"low": MINIMUM_BORROWED_AMOUNT_LO, "high": MINIMUM_BORROWED_AMOUNT_HI},
        {"low": MAXIMUM_BORROWED_AMOUNT_LO, "high": MAXIMUM_BORROWED_AMOUNT_HI},
        [
        {"address": utils.METH_TOKEN, {"low": METH_TOKEN_LT_POOL_DAI, "high": 0}},
        {"address": utils.VMETH, {"low": VMETH_TOKEN_LT_POOL_DAI, "high": 0}}
        ],
        0,
        max_fee=int(1e17)
    )
    await invocation.wait_for_acceptance()

    # pass_contract = await Contract.from_address(client=admin, address=utils.PASS)
    # print(f'⌛️ Set Minter to Pass...')
    # invocation = await pass_contract.functions["setMinter"].invoke(
    #     utils.MINTER,
    #     max_fee=int(1e16)
    # )
    # await invocation.wait_for_acceptance()



    







   
loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())