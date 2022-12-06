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
TOKEN_NAME = 'morphineEth'
TOKEN_SYMBOL = 'METH'
TOKEN_DECIMALS = 18
TOKEN_INITIAL_SUPPLY_LO = (10**9)*10**18
TOKEN_INITIAL_SUPPLY_HI = 0

## FAUCET
ALLOWED_AMOUNT_LO = 2*10**18
ALLOWED_AMOUNT_HI = 0
TIME = 24*60*3600

INITIAL_FUNDING_LO = (10**6)*10**18
INITIAL_FUNDING_HI = 0


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

    # print(f'⌛️ Declaring ERC20...')
    # declare_transaction_erc20 = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.ERC20_SOURCE_CODE).read_text(), max_fee=int(1e16)
    # )
    # resp = await admin.declare(transaction=declare_transaction_erc20)
    # await admin.wait_for_tx(resp.transaction_hash)
    # erc20_class_hash = resp.class_hash

    # print(f'✅ Success! Class Hash: {erc20_class_hash} ')


    # print(f'⌛️ Declaring faucet...')
    # declare_transaction_faucet = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.FAUCET_SOURCE_CODE).read_text(), max_fee=int(1e16)
    # )
    # resp = await admin.declare(transaction=declare_transaction_faucet)
    # await admin.wait_for_tx(resp.transaction_hash)
    # faucet_class_hash = resp.class_hash
    # print(f'✅ Success! Class Hash: {faucet_class_hash} ')

    
    print(f'⌛️ Deploying erc20...')
    deploy_erc20_call, erc20 = deployer.create_deployment_call(
    class_hash=utils.ERC20_HASH,
    abi=json.loads(Path(utils.ERC20_ABI).read_text()),
    calldata={
        "name": TOKEN_NAME,
        "symbol": TOKEN_SYMBOL,
        "decimals": TOKEN_DECIMALS,
        "initial_supply": {"low":TOKEN_INITIAL_SUPPLY_LO, "high":TOKEN_INITIAL_SUPPLY_HI},
        "recipient": admin.address,
        "owner": admin.address
    })

    resp = await admin.execute(deploy_erc20_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)

    print(f'✅ Success! Token deployed to {erc20} ')


    print(f'⌛️ Deploying faucet...')
    deploy_faucet_call, faucet = deployer.create_deployment_call(
    class_hash=utils.FAUCET_HASH,
    abi=json.loads(Path(utils.FAUCET_ABI).read_text()),
    calldata={
        "_owner": admin.address,
        "_token_address": erc20,
        "_allowed_amount": {"low":ALLOWED_AMOUNT_LO, "high":ALLOWED_AMOUNT_HI},
        "_time": TIME,
    })
    resp = await admin.execute(deploy_faucet_call, max_fee=int(1e16))
    await admin.wait_for_tx(resp.transaction_hash)
    print(f'✅ Success! Faucet deployed to {faucet} ')


    print(f'⌛️ Funding faucet...')
    erc20_contract = await Contract.from_address(client=admin, address=erc20)
    invocation = await erc20_contract.functions["transfer"].invoke(faucet, {"low":INITIAL_FUNDING_LO, "high":INITIAL_FUNDING_HI}, max_fee=int(1e16))
    await invocation.wait_for_acceptance()

    print(f'✅ Success! Faucet  has been funded ')
    (balance,) = await erc20_contract.functions["balanceOf"].call(faucet)
    print(f'💰 Faucet Balance : {balance} ')



loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())