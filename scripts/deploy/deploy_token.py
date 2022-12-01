import asyncio
from starknet_py.net import AccountClient, KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.contract import Contract
from starknet_py.net.udc_deployer.deployer import Deployer
from utils import str_to_felt, to_uint
import settings


TOKEN_NAME = 'morphineDai'
TOKEN_SYMBOL = 'MDAI'
TOKEN_DECIMALS = 6
TOKEN_INITIAL_SUPPLY_LO = (10**12)*10**6
TOKEN_INITIAL_SUPPLY_HI = 0


TOKEN_CONTRACT= ['../../lib/openzeppelin/token/erc20/presets/ERC20Mintable.cairo']

async def deploy():
    goerli2_client = GatewayClient("https://alpha4-2.starknet.io/")
    admin = AccountClient(
        client=goerli2_client,
        address=settings.ADDRESS,
        key_pair=KeyPair(private_key=settings.PRIVATE_KEY, public_key=settings.PUBLIC_KEY),
        chain=settings.CHAIN,
        supported_tx_version=1,
    )

    balance = 


    # declare_transaction = await admin.sign_declare_transaction(
    # compilation_source=TOKEN_CONTRACT, max_fee=int(1e16)
    # )

    # deployer = Deployer(settings.UDC, settings.ADDRESS)

    # erc_deployed = deployer.create_deployment_call(
    #     class_hash="",
    #     salt=settings.SALT,
    #     abi=settings.ERC20_ABI,
    #     calldata=[TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_INITIAL_SUPPLY_LO, TOKEN_INITIAL_SUPPLY_HI, settings.ADDRESS, settings.ADDRESS]
    # )


    # print("⏳ Deploying ERC20 Contract...")
    # erc20_contract = await Contract.deploy(
    #     client=client,
    #     compilation_source=ERC20_FILE,
    #     constructor_args=[ERC20_NAME, ERC20_SYMBOL, DECIMALS, INITIAL_SUPPLY, OWNER]
    # )
    # print(f'✨ ERC20 Contract deployed at {hex(erc20_contract.deployed_contract.address)}')
    # print("⏳ Deploying Faucet Contract...")
    # scheduler_checker_contract = await Contract.deploy(
    #     client=client,
    #     compilation_source=FAUCET_FILE,
    #     constructor_args=[OWNER, erc20_contract.deployed_contract.address, ALLOWED_AMOUNT, TIMEDELTA]
    # )

    


loop = asyncio.get_event_loop()
loop.run_until_complete(deploy())