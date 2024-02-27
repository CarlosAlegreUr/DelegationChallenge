# Attempt to include .env file and export its variables
-include .env
export

# Default values for variables
RPC_URL ?= $(ANVIL_ENDPOINT)
PRIVATE_KEY ?= $(DEFAULT_ACCOUNT_ZERO_ANVIL_SK)
CHAIN ?= anvil
YOUR_ADDRESS ?= $(YOUR_ADDRESS)
ETHERSCAN_VERIFY_API_KEY ?= $(ETHERSCAN_VERIFY_API_KEY)

anvilUser ?= 0
ifeq ($(anvilUser),1)
  PRIVATE_KEY := $(DEFAULT_ACCOUNT_ONE_ANVIL_SK)
else ifeq ($(anvilUser),2)
  PRIVATE_KEY := $(DEFAULT_ACCOUNT_TWO_ANVIL_SK)
endif

# Conditional logic for RPC_URL and other parameters based on the chain
ifeq ($(CHAIN),sepolia)
  PRIVATE_KEY = yourKey
  RPC_URL := $(RPC_URL_ENDPOINT_SEPOLIA)
  DEPLOY_COMMAND := forge script script/DeployERC721Delegatable.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --etherscan-api-key $(ETHERSCAN_VERIFY_API_KEY) --verify
  MINT_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --sig "mint()"
  BURN_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --sig "burn(uint256)" -- $(nftId)
  TRANSFER_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --sig "transfer(address,uint256)" -- $(to) $(nftId)
  DELEGATE_TO_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --sig "delegateTo(address,uint256)" -- $(to) $(nftId)
  UNDELEGATE_FROM_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --sig "undelegateFrom(address,uint256)" -- $(to) $(nftId)
  UNDELEGATE_FROM_ALL_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --broadcast --sig "undelegateFromAll()"
  IS_DELEGATEE_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --account $(PRIVATE_KEY) --sender $(YOUR_ADDRESS) --sig "isDelegatee(address,address,uint256)" -- $(delegator) $(to) $(nftId)
else
  DEPLOY_COMMAND := forge script script/DeployERC721Delegatable.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast
  MINT_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --sig "mint()"
  BURN_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --sig "burn(uint256)" -- $(nftId)
  TRANSFER_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --sig "transfer(address,uint256)" -- $(to) $(nftId)
  DELEGATE_TO_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --sig "delegateTo(address,uint256)" -- $(to) $(nftId)
  UNDELEGATE_FROM_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --sig "undelegateFrom(address,uint256)" -- $(to) $(nftId)
  UNDELEGATE_FROM_ALL_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --sig "undelegateFromAll()"
  IS_DELEGATEE_COMMAND := forge script script/CollectionScript.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --sig "isDelegatee(address,address,uint256)" -- $(delegator) $(to) $(nftId)
endif

# Default target if no action is specified
all:
	@echo ""
	@echo "\033[1;32mAvailable Actions:\033[0m"
	@echo "  - deploy"
	@echo "  - mint"
	@echo "  - burn"
	@echo "  - transfer"
	@echo "  - delegateTo"
	@echo "  - undelegateFrom"
	@echo "  - undelegateFromAll"
	@echo "  - isDelegatee"
	@echo ""
	@echo "\033[1;33mParameters:\033[0m"
	@echo "  - Use \033[1mto=theAddress\033[0m , \033[1mnftId=aNumber\033[0m and \033[1mdelegator=address\033[0m to specify an NFT or address for actions requiring it."
	@echo "  - Use \033[1manvilUser=0\033[0m, \033[1manvilUser=1\033[0m, or \033[1manvilUser=2\033[0m to choose \033[1mmsg.sender\033[0m."
	@echo " (see parameter details for each action in the main README of the repo) "	
	@echo ""
	@echo "\033[1;34mAnvil Addresses for easy use:\033[0m"
	@echo "  - 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
	@echo "  - 1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
	@echo "  - 2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
	@echo ""
	@echo "\033[1;36mExample Command:\033[0m"
	@echo "  - \033[0;33mmake transfer to=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC nftId=1 anvilUser=2\033[0m"
	@echo "  - \033[0;33mmake isDelegatee delegator=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 to=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC nftId=1\033[0m"
	@echo ""
	@echo "This command would transfer NFT with ID 1 to address 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC using the Anvil address 2."
	@echo ""

# Define actions with conditional execution
deploy:
	@$(DEPLOY_COMMAND)

mint:
	@$(MINT_COMMAND)

burn:
	@$(BURN_COMMAND)

transfer:
	@$(TRANSFER_COMMAND)

delegateTo:
	@$(DELEGATE_TO_COMMAND)

undelegateFrom:
	@$(UNDELEGATE_FROM_COMMAND)

undelegateFromAll:
	@$(UNDELEGATE_FROM_ALL_COMMAND)

isDelegatee:
	@$(IS_DELEGATEE_COMMAND)

.PHONY: deploy mint burn transfer delegateTo undelegateFrom undelegateFromAll
