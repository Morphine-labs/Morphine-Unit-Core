# Morphine Core v0.1
This repository contains the smart contracts source code. We are using Protostar as development environment for compilation, testing and Starknet Py for deployment and contract interaction tasks.

  ## What is Morphine
  
Morphine offers powerful and versatile tools to build, scale, manage and monetize on-chain strategies.

![](https://files.gitbook.com/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FtT497TblSFFiwqDYCfDC%2Fuploads%2FH0hkC4fnoKVaqWxHwuYl%2Fimage.png?alt=media&token=a221e717-8cda-46f7-bf7e-aa53435e4482)
  
# 🕹️ Getting started

  

- Clone this repo

(We recommend working inside a Python virtual environment)

- python3.9 -m venv ~/cairo_venv source ~/cairo_venv/bin/activate

- pip install -r requirements.txt
- protostar build / test for compilation and testing
- python for scripts
- make for docs

 
  

# 🪄 Dependencies

  

- [cairo-lang](https://www.cairo-lang.org/docs/quickstart.html) - Setup cairo environment

- [starknet-py](https://github.com/software-mansion/starknet.py) - For any kind of scripts

- [protostar](https://docs.swmansion.com/protostar/) - StarkNet smart contract development toolchain

  

#  🧱 Application Structure 

- `lib/morphine` - Morphine contracts 
- `lib/openzeppelin` - OZ contracts
- `lib/utils` - Utils contracts 
- `tests/` - Unit and integrations test 
- `scripts/` - Deploy and protocol interaction tasks 
 - `docs/` - Tech Docs
 - `build/` - Abi and JSON compiled contracts

  
# 🏒 Audits and Formal Verification

No Audits have been done so far. 

- [Tech Docs ](https://sachas-organization.gitbook.io/morphine/developers/protocol) 

# 🤝 Contributions 

All Contributions for this unit have to be performed via repository issue.

- [Available Tasks ](https://sachas-organization.gitbook.io/morphine-tasks/) 
- [Contributor guide ](https://sachas-organization.gitbook.io/morphine/contributors/tasks) 
