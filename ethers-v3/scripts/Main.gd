extends Control

var sepolia_link_contract = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
var base_bnm_contract = "0x88A2d74F47a237a62e7A51cdDa67270CE381555e"

var random_base_contract = "0x24a878dD7b154547A291F756048f29693aE2F073"

var recipient = "0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba"

# Approached with the philosophy that the "Ethers" singleton 
# should be the primary API for the developer


# continue implementing ABI spec:

# For fixed and nested arrays, check for "[]" and numbers enclosed by "[]"
# Figure out the correct way to handle bytes-type arguments
# I believe that buffers are expected, so convert to PackedByteArray before encoding
# Check out the bytes-handling code in the old library
# Fixed bytes will also need to pass their length to Rust so they can be encoded properly
# Determine the encoding rules for tuples and arrays that contain only static values
# Arrays are dynamic unless they are fixed
# Both will also need "deep checking" to make sure they are properly marked as dynamic
# if they contain any dynamic values at all
# And finally: test it with more ABIs



# multi-chain wallet; cross-chain functionality?




func _ready():
	if !Ethers.account_exists("test_keystore"):
		Ethers.create_account("test_keystore", "test_password")
	
	Ethers.login("test_keystore", "test_password")
	
	print(Ethers.get_address("test_keystore"))
	
	#Ethers.get_gas_balance("Base Sepolia", "test_keystore", self, "update_gas_balance")
	#Ethers.get_erc20_info("Ethereum Sepolia", Ethers.get_address("test_keystore"), sepolia_link_contract, self, "get_erc20_info")
	
	Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore"), base_bnm_contract, self, "get_erc20_info")
	
	var amount = Ethers.convert_to_big_uint("0.001", 18)
	#Ethers.transfer("test_keystore", "Base Sepolia", recipient, amount, self, "get_receipt")
	#Ethers.approve_erc20_allowance("test_keystore", "Base Sepolia", base_bnm_contract, random_base_contract, self, "get_receipt")
	#Ethers.transfer_erc20("test_keystore", "Base Sepolia", base_bnm_contract, recipient, amount, self, "get_receipt")
	#Ethers.transfer_erc20("test_keystore", "Base Sepolia", base_bnm_contract, random_base_contract, amount, self, "get_receipt")


	
	#var success = Calldata.get_function_calldata(Contract.IMAGINARY, "not_real", [Ethers.convert_to_big_uint("12", 18), [Ethers.convert_to_big_uint("120", 18), Ethers.convert_to_big_uint("0.01", 18), Ethers.convert_to_big_uint("9000", 18)], [["hello", Ethers.convert_to_big_uint("190", 18)], ["why", Ethers.convert_to_big_uint("7428624", 18)]]])
	#var success = Calldata.get_function_calldata(Contract.IMAGINARY, "not_real", ["recipient", true, ["amount", "meow", "merrow"], [true, "aiiieeargh", Ethers.convert_to_big_uint("120", 18)]])
	#if !success:
		#print("encoding failed")
	#else:
		#print("attempt: " + success)
	

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
