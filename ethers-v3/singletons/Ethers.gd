extends Node

var network_info

var eth_http_request = preload("res://scenes/EthRequest.tscn")
var header = "Content-Type: application/json"

var error

# Stores env-enc encrypted passwords mapped to account names
var logins = {}

func _ready():
	
	check_for_network_info()

	# New env-enc created each session
	FileAccess.open("user://env_enc_key", FileAccess.WRITE).store_buffer(Crypto.new().generate_random_bytes(32))
	FileAccess.open("user://env_enc_iv", FileAccess.WRITE).store_buffer(Crypto.new().generate_random_bytes(16))


#########  KEY MANAGEMENT  #########

# DEBUG
# NOTE
# In addition to implementing an env-enc key/iv for encrypting the user's password,
# I've also limited the overall usage of get_key(), and tried to avoid declaring  
# the unencrypted password, env-enc key/iv, and private key as local variables.  
# The program will also generate a random one-time key whenever reading from contracts. 
# I don't know if these measures enhance security, but presumably they don't make it worse.

func account_exists(account):
	var path = "user://" + account
	if FileAccess.file_exists(path):
		return true
	else:
		return false


func create_account(account, _password):
	if _password.length() > 15 || _password.length() < 8:
		emit_error("Password of invalid length for " + account)
		return
	var path = "user://" + account
	FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _password).store_buffer(Crypto.new().generate_random_bytes(32))


func login(account, _password):
	var path = "user://" + account
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _password)
	if file:
		var aes = AESContext.new()
		aes.start(
			AESContext.MODE_CBC_ENCRYPT, 
			FileAccess.open("user://env_enc_key", FileAccess.READ).get_buffer(32), 
			FileAccess.open("user://env_enc_iv", FileAccess.READ).get_buffer(16)
			)
		var encrypted_password = aes.update(pad(_password).to_utf8_buffer())
		aes.finish()
		logins[account] = encrypted_password
	else:
		emit_error("Incorrect password for " + account)


func get_key(account):
	if account in logins.keys():
		var path = "user://" + account
		var _password = logins[account]
		var aes = AESContext.new()
		aes.start(
			AESContext.MODE_CBC_DECRYPT, 
			FileAccess.open("user://env_enc_key", FileAccess.READ).get_buffer(32), 
			FileAccess.open("user://env_enc_iv", FileAccess.READ).get_buffer(16)
			)
			
		return FileAccess.open_encrypted_with_pass(
			path, 
			FileAccess.READ,
			unpad(aes.update(_password).get_string_from_utf8())
			).get_buffer(32)
		
		
	else:
		emit_error(account + " does not exist")


func pad(password):
	var padding_length = 16%password.length()
	padding_length -= 1
	for zero in range(padding_length):
		password += "0"
	password += str(padding_length)
	return password


func unpad(password):
	var padding_length = int(password.right(1))
	padding_length += 1
	var password_length = 16 - padding_length
	password = password.left(password_length)
	return password




#########  NETWORK MANAGEMENT  #########

func check_for_network_info():
	var json = JSON.new()
	if FileAccess.file_exists("user://network_info") != true:
		network_info = default_network_info.duplicate()
		var file = FileAccess.open("user://network_info", FileAccess.WRITE)
		file.store_string(json.stringify(network_info.duplicate()))
		file.close()
	else:
		var file = FileAccess.open("user://network_info", FileAccess.READ)
		network_info = json.parse_string(file.get_as_text()).duplicate()


func update_rpcs(network, rpcs):
	network_info[network]["rpcs"] = rpcs
	network_info[network]["rpc_cycle"] = 0


func add_network(network, chain_id, rpcs, scan_url, logo=""):
	var new_network = {
		"chain_id": String(chain_id),
		"rpcs": rpcs,
		"rpc_cycle": 0,
		"gas_balance": "0",
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": scan_url,
		"logo": logo
	}
	network_info[network] = new_network
	
	
func update_network_info():
	var json = JSON.new()
	var file = FileAccess.open("user://network_info", FileAccess.WRITE)
	file.store_string(json.stringify(network_info.duplicate()))
	file.close()


func get_rpc(network):
	if !network in network_info.keys():
		return false
		
	var rpcs = network_info[network]["rpcs"]
	var rpc_cycle = network_info[network]["rpc_cycle"]
	var rpc = rpcs[rpc_cycle]
	
	rpc_cycle += 1
	if rpc_cycle == rpcs.size():
		rpc_cycle = 0
	
	network_info[network]["rpc_cycle"] = rpc_cycle
	
	return rpc





#########  HIGH LEVEL API  #########

func get_address(account):
	return GodotSigner.get_address(get_key(account))
	

func get_gas_balance(network, account, callback_node):
	var user_address = get_address(account)
	perform_request(
					"eth_getBalance", 
					[user_address, "latest"], 
					network, 
					callback_node, 
					"update_gas_balance", 
					{"network": network,
					"account": account}
					)


func read_from_contract(network, contract, contract_function, contract_args, callback_node, callback_function, callback_args={}):
	var random_key = Crypto.new().generate_random_bytes(32)
	var calldata = get_read_calldata(random_key, network, contract, contract_function, contract_args)
	Ethers.perform_request(
		"eth_call", 
		[{"to": contract, "input": calldata}, "latest"], 
		network, 
		callback_node,
		callback_function, 
		callback_args,
		0 #default "retries" value
		)



func send_transaction(account, network, contract, contract_function, contract_args, callback_node, callback_function, callback_args={}):
	Transaction.start_transaction(
		account, 
		network, 
		contract, 
		contract_function, 
		contract_args, 
		callback_node, 
		callback_function, 
		callback_args, 
		true #default "autoconfirm" value
		)




#########  DECODING  #########

func decode_string(hex):
	return GodotSigner.decode_string(hex)
	
func decode_address(hex):
	return GodotSigner.decode_address(hex)

func decode_bytes(hex):
	return GodotSigner.decode_bytes(hex)

func decode_uint256(hex):
	return GodotSigner.decode_uint256(hex)

func decode_uint8(hex):
	return GodotSigner.decode_uint8(hex)

func decode_bool(hex):
	return GodotSigner.decode_bool(hex)




#########  LOW LEVEL API  #########

func get_read_calldata(random_key, network, contract, contract_function, contract_args=[]):
	var chain_id = network_info[network]["chain_id"]
	var rpc = network_info[network]["rpcs"][0]
	var params = [random_key, chain_id, rpc, contract]
	for arg in contract_args:
		params.push_back(arg)
	var calldata = GodotSigner.callv(contract_function, params)
			
	return calldata


func perform_request(method, params, network, callback_node, callback_function, callback_args={}, retries=0):
	
	var callback = {
		"callback_node": callback_node,
		"callback_function": callback_function,
		"callback_args": callback_args,
		"network": network,
		"method": method,
		"params": params,
		"success": false,
		"retries": retries,
		"result": "error"
	}
	
	var rpc = get_rpc(network)
	
	if !rpc:
		emit_error("Network " + network + " not listed in network info")
		return
	
	var http_request = eth_http_request.instantiate()
	
	http_request.callback = callback
	http_request.request_completed.connect(http_request.resolve_ethereum_request)
	add_child(http_request)
	
	var tx = {"jsonrpc": "2.0", "method": method, "params": params, "id": 7}

	http_request.request(rpc, 
	[header], 
	HTTPClient.METHOD_POST, 
	JSON.new().stringify(tx))




#########  UTILITY  #########

func get_biguint(number, token_decimals):
	if number.begins_with("."):
		number = "0" + number
		
	var zero_filler = int(token_decimals)
	var decimal_index = number.find(".")
	var big_uint = number
	if decimal_index != -1:
		zero_filler -= number.right(decimal_index+1).length()
		big_uint.erase(decimal_index,decimal_index)
			
	for zero in range(zero_filler):
		big_uint += "0"
	
	var zero_parse_index = 0
	if big_uint.begins_with("0"):
		for digit in big_uint:
			if digit == "0":
				zero_parse_index += 1
			else:
				break
	big_uint = big_uint.right(zero_parse_index)

	if big_uint == "":
		big_uint = "0"

	return big_uint


func convert_to_smallnum(bignum, token_decimals):
	var size = bignum.length()
	var smallnum = ""
	if size <= int(token_decimals):
		smallnum = "0."
		var fill_length = int(token_decimals) - size
		for zero in range(fill_length):
			smallnum += "0"
		smallnum += String(bignum)
	elif size > 18:
		smallnum = bignum
		var decimal_index = size - 18
		smallnum = smallnum.insert(decimal_index, ".")
	
	var index = 0
	var zero_parse_index = 0
	var prune = false
	for digit in smallnum:
		if digit == "0":
			if !prune:
				zero_parse_index = index
				prune = true
		else:
			prune = false
		index += 1
	if prune:
		smallnum = smallnum.left(zero_parse_index).trim_suffix(".")
	
	return smallnum


func emit_error(error_string):
	error = error_string
	print(error)





#########  NETWORK DEFAULTS #########	

var default_network_info = {
	
	"Ethereum Sepolia": 
		{
		"chain_id": "11155111",
		"rpcs": ["https://ethereum-sepolia-rpc.publicnode.com"],
		"rpc_cycle": 0,
		"gas_balance": "0", 
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.etherscan.io/",
		"logo": "res://assets/Ethereum.png"
		},
		
	"Arbitrum Sepolia": 
		{
		"chain_id": "421614",
		"rpcs": ["https://sepolia-rollup.arbitrum.io/rpc"],
		"rpc_cycle": 0,
		"gas_balance": "0", 
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.arbiscan.io/",
		"logo": "res://assets/Arbitrum.png"
		},
		
	"Optimism Sepolia": {
		"chain_id": "11155420",
		"rpcs": ["https://sepolia.optimism.io"],
		"rpc_cycle": 0,
		"gas_balance": "0", 
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia-optimism.etherscan.io/",
		"logo": "res://assets/Optimism.png"
	},
	
	"Base Sepolia": {
		"chain_id": "84532",
		"rpcs": ["https://sepolia.base.org"],
		"rpc_cycle": 0,
		"gas_balance": "0", 
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.basescan.org/",
		"logo": "res://assets/Base.png"
	},
	
	"Avalanche Fuji": {
		"chain_id": "43113",
		"rpcs": ["https://avalanche-fuji-c-chain-rpc.publicnode.com"],
		"rpc_cycle": 0,
		"gas_balance": "0", 
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://testnet.snowtrace.io",
		"logo": "res://assets/Avalanche.png"
	}
}


#########  DOCS  #########


#Ethers.read_from_contract(network, contract, function, [], self, "get_data", {})
#Ethers.send_transaction(account, network, contract, function, [], self, "check_receipt". {})

#read_from_contract(
	#account, STRING name of the account
	#network, STRING name of the network 
	#contract, STRING contract address
	#contract_function, STRING name of contract function in Rust library
	#contract_args, (ARRAY of contract function arguments, [] to leave blank)
	#callback_node, (NODEPATH, typically "self")
	#callback_function, (STRING, name of callback function on callback node)
	#callback_args, (OPTIONAL; DICTIONARY of callback function arguments)
#)
#
#send_transaction(
	#account,
	#network,
	#contract,
	#contract_function, 
	#contract_args, ([] to leave blank)
	#callback_node,
	#callback_function,
	#callback_args, (OPTIONAL)
#)
