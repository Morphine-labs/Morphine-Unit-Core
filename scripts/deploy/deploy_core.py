import asyncio
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.contract import Contract
from starknet_py.net.udc_deployer.deployer import Deployer
from utils import str_to_felt
import ascii
import settings


async def deploy():
    print(ascii.Core)
    goerli2_client = GatewayClient("https://alpha4-2.starknet.io/")
    admin = AccountClient(
        client=goerli2_client,
        address=settings.ADDRESS,
        key_pair=KeyPair(private_key=settings.PRIVATE_KEY, public_key=settings.PUBLIC_KEY),
        chain=settings.CHAIN,
        supported_tx_version=1,
    )

    deployer = Deployer(settings.UDC, settings.ADDRESS)

    deployer.create_deployment_call(
        class_hash="",
        salt=settings.SALT,
        abi=
        calldata=
    )


    print("⏳ Deploying ERC20 Contract...")
    erc20_contract = await Contract.deploy(
        client=client,
        compilation_source=ERC20_FILE,
        constructor_args=[ERC20_NAME, ERC20_SYMBOL, DECIMALS, INITIAL_SUPPLY, OWNER]
    )
    print(f'✨ ERC20 Contract deployed at {hex(erc20_contract.deployed_contract.address)}')
    print("⏳ Deploying Faucet Contract...")
    scheduler_checker_contract = await Contract.deploy(
        client=client,
        compilation_source=FAUCET_FILE,
        constructor_args=[OWNER, erc20_contract.deployed_contract.address, ALLOWED_AMOUNT, TIMEDELTA]
    )

    


loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())