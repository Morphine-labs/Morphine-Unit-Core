import asyncio
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.contract import Contract
from starknet_py.net.udc_deployer.deployer import Deployer
import settings
import utils


TOKEN_NAME = 'morphineDai'
TOKEN_SYMBOL = 'MDAI'
TOKEN_DECIMALS = 6
TOKEN_INITIAL_SUPPLY_LO = (10**12)*10**6
TOKEN_INITIAL_SUPPLY_HI = 0



async def deploy():
    goerli2_client = GatewayClient(net=settings.NET)
    keypair = KeyPair(private_key=settings.PRIVATE_KEY, public_key=settings.PUBLIC_KEY)
    admin = AccountClient(
        client=goerli2_client,
        address=settings.ADMIN,
        key_pair=keypair,
        chain=settings.CHAIN,
        supported_tx_version=1,
    )    
    deployer = Deployer(deployer_address=utils.UD, account_address=admin.address)

    block = await admin.get_block(block_number="latest")
    print(f'🧱 Current block: {block.block_number}')
    balance = await admin.get_balance(utils.ETH)
    print(f'💰 Deployer balance: {balance/(10**18)} ETH')

    print(f'⌛️ Declaring ERC20...')
    declare_transaction_erc20 = await admin.sign_declare_transaction(
    compilation_source=utils.ERC20_SOURCE_CODE, max_fee=int(1e16)
    )

    resp = await admin.declare(transaction=declare_transaction_erc20)
    await admin.wait_for_tx(resp.transaction_hash)
    erc20_class_hash = resp.class_hash

    print(f'✅ Success! Class Hash: {erc20_class_hash} ')


    print(f'⌛️ Declaring faucet...')
    declare_transaction_faucet = await admin.sign_declare_transaction(
    compilation_source=utils.FAUCET_SOURCE_CODE, max_fee=int(1e16)
    )
    resp = await admin.declare(transaction=declare_transaction_faucet)
    await admin.wait_for_tx(resp.transaction_hash)
    faucet_class_hash = resp.class_hash

    print(f'✅ Success! Class Hash: {faucet_class_hash} ')
    
    print(f'⌛️ Declaring erc20...')
    deploy_erc20_call, erc20 = deployer.create_deployment_call(
    class_hash=erc20_class_hash,
    abi=utils.FAUCET_ABI,
    calldata={
        "single_value": 10,
        "tuple": (1, (2, 3)),
        "arr": [1, 2, 3],
        "dict": {"value": 12, "nested_struct": {"value": 99}},
    },

    # Once call is prepared, it can be executed with an account (preferred way)
    resp = await account_client.execute(deploy_call, max_fee=int(1e16))

    # Or signed and send with an account
    invoke_tx = await account_client.sign_invoke_transaction(
        deploy_call, max_fee=int(1e16)
    )
    resp = await account_client.send_transaction(invoke_tx)

    # Wait for transaction
    await account_client.wait_for_tx(resp.transaction_hash)


    deploy_erc20_call, erc20 = deployer.create_deployment_call(
    class_hash=erc20_class_hash,
    abi=utils.FAUCET_ABI,
    calldata={
        "single_value": 10,
        "tuple": (1, (2, 3)),
        "arr": [1, 2, 3],
        "dict": {"value": 12, "nested_struct": {"value": 99}},
    },

    # Once call is prepared, it can be executed with an account (preferred way)
    resp = await account_client.execute(deploy_call, max_fee=int(1e16))

    # Or signed and send with an account
    invoke_tx = await account_client.sign_invoke_transaction(
        deploy_call, max_fee=int(1e16)
    )
    resp = await account_client.send_transaction(invoke_tx)

    # Wait for transaction
    await account_client.wait_for_tx(resp.transaction_hash)

)



loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())