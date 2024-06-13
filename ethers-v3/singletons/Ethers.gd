extends Node

var network_info

var header = "Content-Type: application/json"

var error

var logins = {}

var env_enc_key
var env_enc_iv


func _ready():
	
	# New env-enc created each session
	env_enc_key = Crypto.new().generate_random_bytes(32)
	env_enc_iv = Crypto.new().generate_random_bytes(16)
	
	check_for_network_info()
	

# Env-enc wiped on quit
func _notification(quit):
	if quit == NOTIFICATION_WM_CLOSE_REQUEST:
		
		env_enc_key = clear_memory()
		env_enc_key.clear()
		env_enc_iv = clear_memory()
		env_enc_iv.clear()
		for account in logins:
			account = clear_memory()
			account.clear()
		
		get_tree().quit()


func clear_memory():
	return Crypto.new().generate_random_bytes(256)


#########  KEY MANAGEMENT  #########


func account_exists(account):
	var path = "user://" + account
	if FileAccess.file_exists(path):
		return true
	else:
		return false


func create_account(account, _password, use_enclave=true):
	var path = "user://" + account
	var private_key
	
	# Generate a new private key
	if use_enclave:
		var enclave = EnclaveContext.new()
		add_child(enclave)
		private_key = PackedByteArray(enclave.generate_key())
		enclave.queue_free()
	else:
		private_key = Crypto.new().generate_random_bytes(32)
	
	var salt = Crypto.new().generate_random_bytes(32)
	var iv = Crypto.new().generate_random_bytes(16)
	var address = calculate_address(private_key)
	
	# PBKDF2 Key Derivation
	var encryption_key = GodotSigner.derive_key(_password, salt.hex_encode())
	
	# Encrypt the private key with the password-derived encryption key
	var encrypted_keystore = encrypt(encryption_key, iv, private_key)
	
	private_key = clear_memory()
	private_key.clear()
	_password = clear_memory()
	_password.clear()
	encryption_key = clear_memory()
	encryption_key.clear()
	
	FileAccess.open(path, FileAccess.WRITE).store_buffer(encrypted_keystore)
	FileAccess.open(path + "_SALT", FileAccess.WRITE).store_buffer(salt)
	FileAccess.open(path + "_IV", FileAccess.WRITE).store_buffer(iv)
	FileAccess.open(path + "_ADDRESS", FileAccess.WRITE).store_string(address)


func login(account, _password):
	var path = "user://" + account
	var _private_key = FileAccess.open(path, FileAccess.READ).get_buffer(32)
	var salt = FileAccess.open(path + "_SALT", FileAccess.READ).get_buffer(32)
	var iv = FileAccess.open(path + "_IV", FileAccess.READ).get_buffer(16)
	var address = FileAccess.open(path + "_ADDRESS", FileAccess.READ).get_as_text()
	
	# Check if the password is correct
	var encryption_key = GodotSigner.derive_key(_password, salt.hex_encode())
	var private_key = decrypt(encryption_key, iv, _private_key)
	var _address = calculate_address(private_key)
	
	if address == _address:
		private_key = clear_memory()
		private_key.clear()
		
		# Encrypt the password-derived decryption key using the session env-enc keys
		logins[account] = encrypt(env_enc_key, env_enc_iv, encryption_key)
		
		_password = clear_memory()
		_password.clear()
		encryption_key = clear_memory()
		encryption_key.clear()
		return true

	else:
		emit_error("Incorrect password for " + account)
		return false
	
	encryption_key = clear_memory()
	encryption_key.clear()
	return false


func get_key(account):
	if account in logins.keys():
		var path = "user://" + account
		
		var _private_key = FileAccess.open(path, FileAccess.READ).get_buffer(32)
		var salt = FileAccess.open(path + "_SALT", FileAccess.READ).get_buffer(32)
		var iv = FileAccess.open(path + "_IV", FileAccess.READ).get_buffer(16)
	
		# Decrypt the decryption key, using the session env-enc keys
		var decryption_key = decrypt(env_enc_key, env_enc_iv, logins[account])
		
		# Decrypt the private key
		var private_key = decrypt(decryption_key, iv, _private_key)
		
		decryption_key = clear_memory()
		decryption_key.clear()
		
		return private_key

	else:
		emit_error(account + " does not exist")


func calculate_address(key):
	var address = GodotSigner.get_address(key)
	key = clear_memory()
	key.clear()
	return address


func get_address(account):
	var path = "user://" + account
	var address = FileAccess.open(path + "_ADDRESS", FileAccess.READ).get_as_text()
	return address


func encrypt(_key, _iv, _data):
	var aes = AESContext.new()
	aes.start(
		AESContext.MODE_CBC_ENCRYPT, 
		_key, 
		_iv
		)
	var encrypted = aes.update(_data)
	_data = clear_memory()
	_data.clear()
	_key = clear_memory()
	_key.clear()
	return encrypted


func decrypt(_key, _iv, _data):
	var aes = AESContext.new()
	aes.start(
		AESContext.MODE_CBC_DECRYPT, 
		_key, 
		_iv
		)
	var decrypted = aes.update(_data)
	_key = clear_memory()
	_key.clear()
	return decrypted



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


func get_gas_balance(network, account, callback_node, callback_function, callback_args={}):
	var user_address = get_address(account)
	callback_args["network"] = network
	callback_args["account"] = account
	perform_request(
					"eth_getBalance", 
					[user_address, "latest"], 
					network, 
					self, 
					"return_gas_balance", 
					{"network": network,
					"account": account,
					"callback_node": callback_node,
					"callback_function": callback_function,
					"callback_args": callback_args}
					)


func return_gas_balance(_callback):
	var callback_node = _callback["callback_args"]["callback_node"]
	var callback_function = _callback["callback_args"]["callback_function"]
	
	var next_callback = {
		"callback_args": _callback["callback_args"]["callback_args"],
		"success": false,
		"result": ""
	}
	
	if _callback["success"]:
		next_callback["success"] = true
		var balance = str(_callback["result"].hex_to_int())
		next_callback["result"] = convert_to_smallnum(balance, 18)
	
	callback_node.call(callback_function, next_callback)




#########  TRANSACTION API  #########


func get_calldata(read_or_write, abi, function_name, function_args=[]):
	var calldata = {
		"calldata": "0x" + Calldata.get_function_calldata(abi, function_name, function_args)
	}
	if read_or_write in ["read", "READ"]:
		calldata["outputs"] = get_outputs(abi, function_name)
	
	return(calldata)


func get_outputs(abi, function_name):
	var function = Calldata.get_function(abi, function_name)
	var outputs = Calldata.get_function_outputs(function)
	return outputs
	

func read_from_contract(network, contract, _calldata, callback_node, callback_function, _callback_args={}):
	var calldata = _calldata["calldata"]
	var outputs = _calldata["outputs"]
	var callback_args = {
		"_callback_node": callback_node,
		"_callback_function": callback_function,
		"_callback_args": _callback_args,
		
		# Used to decode the RPC response 
		"_function_outputs": outputs
	}
	
	Ethers.perform_request(
		"eth_call", 
		[{"to": contract, "input": calldata}, "latest"], 
		network, 
		self,
		"decode_rpc_response", 
		callback_args
		)


func decode_rpc_response(_callback):
	var _callback_args = _callback["callback_args"]
	var callback_node = _callback_args["_callback_node"]
	var callback_function = _callback_args["_callback_function"]
	var callback_args = _callback_args["_callback_args"]
	var outputs = _callback_args["_function_outputs"]
	
	var callback = {
		"success": _callback["success"],
		"callback_args": callback_args
		}
	
	if _callback["success"]:
		# The decoded_result will be an array containing the decoded values.
		var decoded_result = Calldata.abi_decode(outputs, _callback["result"])
		callback["result"] = decoded_result
		
	callback_node.call(callback_function, callback)


func pending_transaction(network):
	if Transaction.pending_transaction(network):
		return Transaction.pending_transactions[network]
	else:
		return false


func send_transaction(account, network, contract, _calldata, callback_node, callback_function, callback_args={}, gas_limit="900000", value="0"):
	var calldata = _calldata["calldata"]
	calldata = calldata.trim_prefix("0x")
	Transaction.send_transaction(account, network, contract, gas_limit, value, calldata, callback_node, callback_function, callback_args)


# For ETH transfers
func transfer(account, network, recipient, amount, callback_node, callback_function, callback_args={}):
	Transaction.start_eth_transfer(
		account,
		network,
		"placeholder",
		"transfer",
		[recipient, amount],
		callback_node,
		callback_function,
		callback_args
	)


func perform_request(method, params, network, callback_node, callback_function, callback_args={}, specified_rpc=false, retries=3):
	
	var callback = {
		"callback_node": callback_node,
		"callback_function": callback_function,
		"callback_args": callback_args,
		"network": network,
		"method": method,
		"params": params,
		"success": false,
		"retries": retries,
		"result": "error",
		"specified_rpc": false
	}

	var rpc = specified_rpc
	
	if !rpc:
		rpc = get_rpc(network)
	else:
		callback["specified_rpc"] = rpc
	
	if !rpc:
		emit_error("Network " + network + " not listed in network info")
		return
	
	var http_request = EthRequest.new()
	
	http_request.callback = callback
	http_request.request_completed.connect(http_request.resolve_ethereum_request)
	add_child(http_request)
	
	var tx = {"jsonrpc": "2.0", "method": method, "params": params, "id": 7}

	http_request.request(rpc, 
	[header], 
	HTTPClient.METHOD_POST, 
	JSON.new().stringify(tx))





#########  ERC20 API  #########


# "get_erc20_info" bounces through three calls: name(), decimals(), and balanceOf() for a supplied 
# address, and returns all 3 values as part of the callback_args sent to the callback_node
func get_erc20_info(network, address, contract, callback_node, callback_function):
	var callback_args = {
		"network": network, 
		"address": address, 
		"contract": contract,
		"callback_node": callback_node,
		"callback_function": callback_function,
		}
	get_erc20_name(network, contract, self, "return_erc20_name", callback_args)


func get_erc20_name(network, contract, callback_node, callback_function, callback_args={}):
	var calldata = get_calldata("READ", Contract.ERC20, "name")
	read_from_contract(network, contract, calldata, self, "return_erc20_name", callback_args)


func return_erc20_name(callback):
	var callback_args = callback["callback_args"]
	var contract = callback_args["contract"]
	var network = callback_args["network"]

	if callback["success"]:
		callback_args["name"] = callback["result"][0]
		get_erc20_decimals(network, contract, self, "get_erc20_decimals", callback_args)


func get_erc20_decimals(network, contract, callback_node, callback_function, callback_args={}):
	var calldata = get_calldata("READ", Contract.ERC20, "decimals")
	read_from_contract(network, contract, calldata, self, "return_erc20_decimals", callback_args)


func return_erc20_decimals(callback):
	var callback_args = callback["callback_args"]
	var contract = callback_args["contract"]
	var network = callback_args["network"]
	
	if callback["success"]:
		var decimals = callback["result"][0]
		callback_args["decimals"] = decimals
		var address = callback_args["address"]
		get_erc20_balance(address, decimals, network, contract, self, "get_erc20_balance", callback_args)


func get_erc20_balance(address, decimals, network, contract, callback_node, callback_function, callback_args={}):
	var calldata = get_calldata("READ", Contract.ERC20, "balanceOf", [address])
	read_from_contract(network, contract, calldata, self, "return_erc20_balance", callback_args)


func return_erc20_balance(callback):
	var callback_args = callback["callback_args"]
	var callback_node = callback_args["callback_node"]
	var callback_function = callback_args["callback_function"]
	var name = callback_args["name"]
	var decimals = callback_args["decimals"]
	
	var next_callback = {
		"callback_args": callback_args,
		"success": false,
		"result": ""
	}
	
	if callback["success"]:
		next_callback["success"] = true
		var balance = convert_to_smallnum(callback["result"][0], decimals)
		next_callback["result"] = [name, str(decimals), balance]
		next_callback["callback_args"]["balance"] = balance
	
	callback_node.call(callback_function, next_callback)


func transfer_erc20(account, network, token_address, recipient, amount, callback_node, callback_function, callback_args={}):
	var calldata = get_calldata("WRITE", Contract.ERC20, "transfer", [recipient, amount])
	send_transaction(account, network, token_address, calldata, callback_node, callback_function, callback_args, "50000")

# Right now configured to approve the maximum uint256 value
func approve_erc20_allowance(account, network, token_address, spender_address, callback_node, callback_function, callback_args={}):
	var calldata = get_calldata("WRITE", Contract.ERC20, "approve", [spender_address, "115792089237316195423570985008687907853269984665640564039457584007913129639935"])
	send_transaction(account, network, token_address, calldata, callback_node, callback_function, callback_args, "50000")



#########  UTILITY  #########

func convert_to_bignum(number, token_decimals=18):
	if number.begins_with("."):
		number = "0" + number
		
	var zero_filler = int(token_decimals)
	var decimal_index = number.find(".")
	
	var bignum = number
	if decimal_index != -1:
		var segment = number.right(-(decimal_index+1) )
		zero_filler -= segment.length()
		bignum = bignum.erase(decimal_index,decimal_index)

	for zero in range(zero_filler):
		bignum += "0"
	
	var zero_parse_index = 0
	if bignum.begins_with("0"):
		for digit in bignum:
			if digit == "0":
				zero_parse_index += 1
			else:
				break
	if zero_parse_index > 0:
		bignum = bignum.right(-zero_parse_index)

	if bignum == "":
		bignum = "0"

	return bignum


func convert_to_smallnum(bignum, token_decimals=18):
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
		"rpcs": ["https://ethereum-sepolia-rpc.publicnode.com", "https://rpc2.sepolia.org"],
		"rpc_cycle": 0,
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
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.arbiscan.io/",
		"logo": "res://assets/Arbitrum.png"
		},
		
	"Optimism Sepolia": {
		"chain_id": "11155420",
		"rpcs": ["https://sepolia.optimism.io"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia-optimism.etherscan.io/",
		"logo": "res://assets/Optimism.png"
	},
	
	"Base Sepolia": {
		"chain_id": "84532",
		"rpcs": ["https://sepolia.base.org"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://sepolia.basescan.org/",
		"logo": "res://assets/Base.png"
	},
	
	"Avalanche Fuji": {
		"chain_id": "43113",
		"rpcs": ["https://avalanche-fuji-c-chain-rpc.publicnode.com"],
		"rpc_cycle": 0,
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"scan_url": "https://testnet.snowtrace.io/",
		"logo": "res://assets/Avalanche.png"
	}
}
