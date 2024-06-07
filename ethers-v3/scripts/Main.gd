extends Control

#do erc20 implementation

var token_contract = "0x779877A7B0D9E8603169DdbD7836e478b4624789"

func _ready():
	if !Ethers.account_exists("test_keystore"):
		Ethers.create_account("test_keystore", "test_password")
	
	Ethers.login("test_keystore", "test_password")
	
	print(Ethers.get_address("test_keystore"))
	
	Ethers.read_from_contract("Ethereum Sepolia", token_contract, "get_token_decimals", [], self, "get_decimals", {})
	
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
func update_gas_balance(callback):
	print(callback)

#DEBUG
func get_decimals(callback):
	if callback["success"]:
		var result = callback["result"]
		print(result)
		print(Ethers.decode_uint256(result))
