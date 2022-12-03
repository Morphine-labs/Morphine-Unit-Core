from starkware.python.utils import from_bytes
import asyncio
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.contract import Contract
from starknet_py.net.udc_deployer.deployer import Deployer
from enum import Enum
from starknet_py.net.models import StarknetChainId
from starknet_py.utils.docs import as_our_module
from pathlib import Path
import settings
import utils


## ERC20
TOKEN_NAME = 'morphineDai'
TOKEN_SYMBOL = 'MDAI'
TOKEN_DECIMALS = 6
TOKEN_INITIAL_SUPPLY_LO = (10**12)*10**6
TOKEN_INITIAL_SUPPLY_HI = 0

## FAUCET
ALLOWED_AMOUNT_LO = 1500*10**6
ALLOWED_AMOUNT_HI = 0
TIME = 24*60*3600

class _StarknetChainId(Enum):
    MAINNET = from_bytes(b"SN_MAIN")
    TESTNET = from_bytes(b"SN_GOERLI")
    TESTNET_2 = from_bytes(b"SN_GOERLI2")


StarknetChainId = as_our_module(_StarknetChainId)


async def deploy():
    goerli2_client = GatewayClient(net=settings.NET)
    # keypair = KeyPair(private_key=int(settings.PRIVATE_KEY), public_key=int(settings.PUBLIC_KEY))
    
    # admin = await AccountClient.create_account(
    #     client=goerli2_client,
    #     private_key= int(settings.PRIVATE_KEY),
    #     chain= StarknetChainId.TESTNET_2,
    # )

    # print(admin.address)


    account_to_deploy = await AccountClient.sign_deploy_account_transaction(
        class_hash="0x68cb33b3ab73ee34d2084cfcb7d07b24db48095ad0907c10b6fdb7b0e91ef0a",
        contract_address_salt=7383738,
        constructor_calldata=[3260281675601709103560498194009673788088220875676491641367091347543912979573]
    )  

    
    print(f'🧱 Ck: {account_to_deploy}')




    # create_account(client: Client, private_key: Optional[int] = None, signer: Optional[BaseSigner] = None, chain: Optional[StarknetChainId] = None)

    # admin = AccountClient(
    #     client=goerli2_client,
    #     address=settings.ADMIN,
    #     key_pair=keypair,
    #     chain=StarknetChainId.TESTNET_2,
    #     supported_tx_version=1,
    # )    

    # deployer = Deployer(deployer_address=utils.UD, account_address=admin.address)
    # print(f'🧱 Ck: {StarknetChainId.TESTNET.value}')
    # block = await admin.get_block(block_number="latest")
    # print(f'🧱 Current block: {block.block_number}')
    # balance = await admin.get_balance(utils.ETH)
    # print(f'💰 Deployer balance: {balance/(10**18)} ETH')

    # print(f'⌛️ Declaring ERC20...')

    # declare_transaction_erc20 = await admin.sign_declare_transaction(
    # compiled_contract=Path("../../build/erc20.json").read_text(), max_fee=int(1e16)
    # )

    # resp = await admin.declare(transaction=declare_transaction_erc20)
    # await admin.wait_for_tx(resp.transaction_hash)
    # erc20_class_hash = resp.class_hash

    # print(f'✅ Success! Class Hash: {erc20_class_hash} ')


    # print(f'⌛️ Declaring faucet...')
    # declare_transaction_faucet = await admin.sign_declare_transaction(
    # compilation_source=Path(utils.FAUCET_SOURCE_CODE), max_fee=int(1e16)
    # )
    # resp = await admin.declare(transaction=declare_transaction_faucet)
    # await admin.wait_for_tx(resp.transaction_hash)
    # faucet_class_hash = resp.class_hash

    # print(f'✅ Success! Class Hash: {faucet_class_hash} ')
    
    # print(f'⌛️ Deploying erc20...')
    # deploy_erc20_call, erc20 = deployer.create_deployment_call(
    # class_hash=erc20_class_hash,
    # abi=utils.ERC20_ABI,
    # calldata={
    #     TOKEN_NAME,
    #     TOKEN_SYMBOL,
    #     TOKEN_DECIMALS,
    #     (TOKEN_INITIAL_SUPPLY_LO, TOKEN_INITIAL_SUPPLY_HI),
    #     admin.address
    # })

    # resp = await admin.execute(deploy_erc20_call, max_fee=int(1e16))
    # await account_client.wait_for_tx(resp.transaction_hash)

    # print(f'✅ Success! Token deployed to {erc20} ')


    # print(f'⌛️ Deploying faucet...')
    # deploy_faucet_call, faucet = deployer.create_deployment_call(
    # class_hash=faucet_class_hash,
    # abi=utils.FAUCET_ABI,
    # calldata={
    #     admin.address,
    #     erc20,
    #     (ALLOWED_AMOUNT_LO, ALLOWED_AMOUNT_HI),
    #     TIME
    # })
    # resp = await admin.execute(deploy_faucet_call, max_fee=int(1e16))
    # await account_client.wait_for_tx(resp.transaction_hash)
    # print(f'✅ Success! Faucet deployed to {faucet} ')



loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())