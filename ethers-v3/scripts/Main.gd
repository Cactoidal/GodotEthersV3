extends Control

var sepolia_link_contract = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
var base_bnm_contract = "0x88A2d74F47a237a62e7A51cdDa67270CE381555e"

var random_base_contract = "0x24a878dD7b154547A291F756048f29693aE2F073"

var recipient = "0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba"

# Approached with the philosophy that the "Ethers" singleton 
# should be the primary API for the developer


# multi-chain wallet; cross-chain functionality?




func _ready():
	if !Ethers.account_exists("test_keystore"):
		Ethers.create_account("test_keystore", "test_password")
	
	Ethers.login("test_keystore", "test_password")
	
	print(Ethers.get_address("test_keystore"))
	
	#Ethers.get_gas_balance("Base Sepolia", "test_keystore", self, "update_gas_balance")
	#Ethers.get_erc20_info("Ethereum Sepolia", Ethers.get_address("test_keystore"), sepolia_link_contract, self, "get_erc20_info")
	
	Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore"), base_bnm_contract, self, "get_erc20_info")
	
	#var amount = Ethers.convert_to_big_uint("0.000000001", 18)
	var amount = Ethers.convert_to_big_uint("0.001", 18)
	#Ethers.transfer("test_keystore", "Base Sepolia", recipient, amount, self, "get_receipt")
	Ethers.approve_erc20_allowance("test_keystore", "Base Sepolia", base_bnm_contract, random_base_contract, self, "get_receipt")
	#Ethers.transfer_erc20("test_keystore", "Base Sepolia", base_bnm_contract, recipient, amount, self, "get_receipt")
	#Ethers.transfer_erc20("test_keystore", "Base Sepolia", base_bnm_contract, random_base_contract, amount, self, "get_receipt")

	# DEBUG
	# EXPERIMENTAL
	
	#var success = Calldata.sort_args_for_encoding(Contract.IMAGINARY, "not_real", [Ethers.convert_to_big_uint("12", 18), [Ethers.convert_to_big_uint("120", 18), Ethers.convert_to_big_uint("0.01", 18), Ethers.convert_to_big_uint("9000", 18)], [["hello", Ethers.convert_to_big_uint("190", 18)], ["why", Ethers.convert_to_big_uint("7428624", 18)]]])
	#var success = Calldata.sort_args_for_encoding(Contract.IMAGINARY, "not_real", ["recipient", true, ["amount", "meow", "merrow"], [true, "aiiieeargh", Ethers.convert_to_big_uint("120", 18)]])
	#if !success:
		#print("encoding failed")
	#else:
		#print("attempt: " + success)
	
	#var calldata = Ethers.get_calldata(Contract.ERC20, "transfer", [recipient, amount])
	#print("target: " + calldata)
	#Ethers.send_raw_transaction("test_keystore", "Base Sepolia", base_bnm_contract, calldata, self, "get_receipt")


func update_gas_balance(callback):
	var network = callback["callback_args"]["network"]
	var account = callback["callback_args"]["account"]
	if callback["success"]:
		var balance = callback["result"]
		print(account + " has gas balance of " + balance + " on " + network)
	

func get_erc20_info(callback):
	var callback_args = callback["callback_args"]
	var network = callback_args["network"]
	var address = callback_args["address"]
	if callback["success"]:
		var erc20_name = callback_args["name"]
		var decimals = callback_args["decimals"]
		var balance = callback_args["balance"]
		print(address + " has " + balance + " " + erc20_name + " tokens with " + decimals + " decimals on " + network)
#

func get_receipt(callback):
	print(callback)




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
