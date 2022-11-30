from starknet_py.net import AccountClient
from starknet_py.net import KeyPair
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models import StarknetChainId
from starknet_py.net.models import compute_address

# First, make sure to generate private key and salt
private_key = 0xa0448463f5e8c9b21f7db564d4eba66245cd72944072600e817894b4f
salt = 0
key_pair = KeyPair.from_private_key(private_key)

# Compute an address
address = compute_address(
    salt=salt,
    class_hash=class_hash,  # class_hash of the Account declared on the StarkNet
    constructor_calldata=[key_pair.public_key],
    deployer_address=0,
)

# Prefund the address (using the token bridge or by sending fee tokens to the computed address)
# Make sure the tx has been accepted on L2 before proceeding

# Create an AccountClient instance
account = AccountClient(
    address=address,
    client=GatewayClient(net=network),
    key_pair=key_pair,
    chain=StarknetChainId.TESTNET,
    supported_tx_version=1,
)

# Create and sign DeployAccount transaction
deploy_account_tx =  account.sign_deploy_account_transaction(
    class_hash=class_hash,
    contract_address_salt=salt,
    constructor_calldata=[key_pair.public_key],
    max_fee=int(1e15),
)

resp = account.deploy_account(transaction=deploy_account_tx)
account.wait_for_tx(resp.transaction_hash)