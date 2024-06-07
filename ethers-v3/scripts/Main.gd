extends Control

var token_contract = "0x779877A7B0D9E8603169DdbD7836e478b4624789"

func _ready():
	if !Ethers.account_exists("test_keystore"):
		Ethers.create_account("test_keystore", "test_password")
	
	Ethers.login("test_keystore", "test_password")
	
	print(Ethers.get_address("test_keystore"))
	
	Ethers.get_gas_balance("Ethereum Sepolia", "test_keystore", self, "update_gas_balance")
	Ethers.get_erc20_info("Ethereum Sepolia", "test_keystore", token_contract, self, "get_erc20_info")


func update_gas_balance(callback):
	var network = callback["callback_args"]["network"]
	var account = callback["callback_args"]["account"]
	if callback["success"]:
		var balance = callback["result"]
		print(account + " has gas balance of " + balance + " on " + network)
	

func get_erc20_info(callback):
	var erc20_name = callback["callback_args"]["name"]
	var decimals = callback["callback_args"]["decimals"]
	var network = callback["callback_args"]["network"]
	var account = callback["callback_args"]["account"]
	if callback["success"]:
		var balance = callback["result"]
		print(account + " has " + balance + " " + erc20_name + " tokens with " + decimals + " decimals on " + network)
#






#DEBUG
#Ethers.read_from_contract("Ethereum Sepolia", token_contract, "get_token_decimals", [], self, "get_erc20_decimals", {})

	# DEBUG
	#Ethers.perform_request(
		#"eth_call", 
		#[{"to": token_contract, "input": calldata}, "latest"], 
		#"Ethereum Sepolia", 
		#self,
		#"get_erc20_name", 
		#{}
		#)
	#Ethers.perform_request(
		#"eth_blockNumber", 
		#[], 
		#"Ethereum Sepolia", 
		#self,
		#"get_erc20_name", 
		#{}
		#)
	#Ethers.get_gas_balance("Ethereum Sepolia", "new_key", self)
	


#DEBUG


#func old_get_erc20_info(network, account, contract):
	#Ethers.get_erc20_name(network, contract, self, "get_erc20_name", {"network": network, "account": account, "contract": contract})
#
#
#func get_erc20_name(callback):
	#var callback_args = callback["callback_args"]
	#if callback["success"]:
		#callback_args["name"] = callback["result"]
		#Ethers.get_erc20_decimals("Ethereum Sepolia", token_contract, self, "get_erc20_decimals", callback_args)
#
#
#func get_erc20_decimals(callback):
	#var callback_args = callback["callback_args"]
	#if callback["success"]:
		#var decimals = callback["result"]
		#callback_args["decimals"] = decimals
		#var address = Ethers.get_address("test_keystore")
		#Ethers.get_erc20_balance(address, decimals, "Ethereum Sepolia", token_contract, self, "get_erc20_balance", callback_args)
#
#
#func get_erc20_balance(callback):
	#var erc20_name = callback["callback_args"]["name"]
	#var network = callback["callback_args"]["network"]
	#var account = callback["callback_args"]["account"]
	#if callback["success"]:
		#var balance = callback["result"]
		#print(account + " has " + balance + " " + erc20_name + " tokens on " + network)
