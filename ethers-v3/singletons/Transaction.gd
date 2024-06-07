extends Node

var pending_transactions = {}
var error


func pending_transaction(network):
	if network in pending_transactions.keys():
		return true
	else:
		return false


func start_transaction(
	account,
	network,
	contract, 
	contract_function, 
	contract_args,
	callback_node, 
	callback_function, 
	callback_args={}, 
	auto_confirm=true
	):
		
		if !pending_transaction(network):
			
			var transaction = {
			"callback_node": callback_node,
			"callback_function": callback_function,
			"callback_args": callback_args,
			"network": network,
			"account": account,
			"contract": contract,
			"contract_function": contract_function,
			"contract_args": contract_args,
			"auto_confirm": auto_confirm,
			"initialized": false,
			"tx_count": 0,
			"gas_price": 0,
			"tx_hash": "",
			"check_for_receipt": false,
			"tx_receipt_poll_timer": 4
			}
		
			pending_transactions[network] = transaction



func _process(delta):
	for network in pending_transactions.keys():
		var transaction = pending_transactions[network]
		if !transaction["initialized"]:
			transaction["initialized"] = true
			initiate(transaction)
		elif transaction["check_for_receipt"]:
			check_for_tx_receipt(transaction, delta)


func initiate(transaction):
	var user_address = Ethers.get_address(transaction["account"])
	Ethers.perform_request(
					"eth_getBalance", 
					[user_address, "latest"], 
					transaction["network"], 
					self, 
					"update_gas_balance", 
					{"transaction": transaction}
					)


func update_gas_balance(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	
	if callback["success"]:
		var balance = str(callback["result"].hex_to_int())
		balance = Ethers.convert_to_smallnum(balance, 18)
		
		Ethers.network_info[network]["gas_balance"] = balance
		
		var network_info = Ethers.network_info.duplicate()
		
		var user_address = Ethers.get_address(transaction["account"])
		
		if float(balance) > float(network_info[network]["minimum_gas_threshold"]):
				Ethers.perform_request(
					"eth_getTransactionCount", 
					[user_address, "latest"], 
					network, 
					self, 
					"get_tx_count", 
					{"transaction": transaction}
					)
		else:
			emit_error("Not enough gas", network)
	else:
		emit_error("RPC error: Failed to update gas balance", network)


func get_tx_count(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	
	if callback["success"]:
		transaction["tx_count"] = callback["result"].hex_to_int()
		Ethers.perform_request(
			"eth_gasPrice", 
			[], 
			network, 
			self, 
			"get_gas_price", 
			{"transaction": transaction}
			)
	else:
		emit_error("RPC error: Failed to get TX count", network)


func get_gas_price(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	
	if callback["success"]:
		transaction["gas_price"] = int(ceil((callback["result"].hex_to_int() * 1.1))) #adjusted up
		
		var network_info = Ethers.network_info.duplicate()
		var chain_id = network_info[network]["chain_id"]
		var maximum_gas_fee = network_info[network]["maximum_gas_fee"]
		var rpc = network_info[network][0]
		
		if maximum_gas_fee != "":
			if transaction["gas_price"] > int(maximum_gas_fee):
				emit_error("Gas fee too high", network)
				return
		
		var params = ["key_placeholder", chain_id, transaction["contract"], rpc, transaction["gas_price"], transaction["tx_count"]]
		for arg in transaction["contract_args"]:
			params.push_back(arg)
		temp_account = transaction["account"]
		var calldata = "0x" + GodotSigner.callv(transaction["contract_function"], params.map(merge))
		
		if transaction["autoconfirm"]:
			Ethers.perform_request(
				"eth_sendRawTransaction", 
				[calldata], 
				network, 
				self, 
				"get_transaction_hash", 
				{"transaction": transaction}
				)
		else:
			# DEBUG
			# Option is here to provide pop-up to confirm manually
			pass
	else:
		emit_error("RPC error: Failed to get gas price", network)

# Workaround to avoid declaring the private key as a local variable, while still
# retaining the ability to use callv()
var temp_account
func merge(value):
	if value == "key_placeholder":
		return Ethers.get_key(temp_account)
	else:
		return value

func get_transaction_hash(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	
	if callback["success"]:
			transaction["tx_hash"] = callback["result"]
			transaction["check_for_receipt"] = true
	else:
		emit_error("RPC error: Failed to get TX hash", network)


func check_for_tx_receipt(transaction, delta):
	transaction["tx_receipt_poll_timer"] -= delta
	if transaction["tx_receipt_poll_timer"] < 0:
		transaction["tx_receipt_poll_timer"] = 4
		Ethers.perform_request(
			"eth_getTransactionReceipt", 
			[transaction["tx_hash"]], 
			transaction["network"], 
			self, 
			"check_transaction_receipt",
			{}
			)


func check_transaction_receipt(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
		
	if callback["success"]:
		if callback["result"] != null:
			
			var tx_callback_node = transaction["callback_node"]
			var tx_callback_function = transaction["callback_function"]
			var tx_callback_args = transaction["callback_args"]
	
			var tx_callback = {
				"success" = false,
				"receipt" = "",
				"callback_args" = tx_callback_args
			}

			#var block_number = callback["result"]["blockNumber"]
			tx_callback["receipt"] = callback["result"]
			var success = callback["result"]["status"]
			if success == "0x1":
				tx_callback["success"] = true
		
			tx_callback_node.call(tx_callback_function, tx_callback)
			finish_transaction(network)
	else:
		emit_error("RPC error: Failed to get TX receipt", network)
		
		

func finish_transaction(network):
	pending_transactions.erase(network)


func emit_error(error_string, network):
	error = error_string
	print(error + " on " + network)
	finish_transaction(network)
