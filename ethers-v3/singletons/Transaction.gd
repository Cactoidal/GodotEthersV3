extends Node

var pending_transactions = {}
var error


func pending_transaction(account, network):
	if !account in pending_transactions.keys():
		pending_transactions[account] = {}
		return false
	
	if network in pending_transactions[account].keys():
		return true
	else:
		return false

func send_transaction(
	account,
	network,
	contract,
	maximum_gas_fee,
	value,
	calldata, 
	callback_node, 
	callback_function, 
	callback_args={},
	eth_transfer_args=false
	):
		
		if !pending_transaction(account, network):
			
			var transaction = {
			"callback_node": callback_node,
			"callback_function": callback_function,
			"callback_args": callback_args,
			"network": network,
			"account": account,
			"contract": contract,
			"gas_limit": "0",
			"maximum_gas_fee": maximum_gas_fee,
			"value": value,
			"calldata": calldata,
			"initialized": false,
			"tx_count": 0,
			"gas_price": 0,
			"transaction_hash": "",
			"transaction_receipt": "",
			"check_for_receipt": false,
			"tx_receipt_poll_timer": 4,
			"eth_transfer_args": eth_transfer_args,
			"tx_status": "PENDING",
			"local_id": Crypto.new().generate_random_bytes(32).hex_encode()
			}
			
			pending_transactions[account][network] = transaction
			
			# Ethers transmits transaction objects to all nodes that have
			# called register_transaction_log()
			Ethers.transmit_transaction_object(transaction.duplicate())


func _process(delta):
	for account in pending_transactions.keys():
		for network in pending_transactions[account].keys():
			var transaction = pending_transactions[account][network]
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
	var account = transaction["account"]
	
	if callback["success"]:
		var balance = str(callback["result"].hex_to_int())
		transaction["balance"] = balance
		
		var network_info = Ethers.network_info.duplicate()
		
		var user_address = Ethers.get_address(transaction["account"])
	
		Ethers.perform_request(
					"eth_getTransactionCount", 
					[user_address, "latest"], 
					network, 
					self, 
					"get_tx_count", 
					{"transaction": transaction}
					)
	
	else:
		emit_error("RPC error: Failed to update gas balance", account, network)


func get_tx_count(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	var account = transaction["account"]
	
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
		emit_error("RPC error: Failed to get TX count", account, network)


func get_gas_price(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	var account = transaction["account"]
	
	if callback["success"]:
		transaction["gas_price"] = int(ceil((callback["result"].hex_to_int() * 1.1))) 
		var gas_price_hex = "%x" % transaction["gas_price"]
		
		var to = transaction["contract"]
		var data = ""
		if transaction["eth_transfer_args"]:
			to = transaction["eth_transfer_args"][0]
		else:
			data = "0x" + transaction["calldata"]
		
		var params = [{
			"to": to,
			"from": Ethers.get_address(account),
			"gas": "0x0",
			"value": "0x" + transaction["value"],
			"data": data
		}, "latest", 
		# State override of the balance is required 
		# to estimate gas for complex transactions (I guess?)
		{Ethers.get_address(account) : {"balance": "0x" + Ethers.convert_to_bignum("7777777", 18)}}]
		
		Ethers.perform_request(
			"eth_estimateGas", 
			params, 
			network, 
			self, 
			"estimate_gas_fee", 
			{"transaction": transaction}
			)


func estimate_gas_fee(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	var account = transaction["account"]
	
	if callback["success"]:
		
		transaction["gas_limit"] = str(   int(callback["result"].hex_to_int() * 1.1)  )
		
		var predicted_gas_cost = Ethers.big_uint_math(transaction["gas_limit"], "MULTIPLY", str(transaction["gas_price"]))
		
		# Check gas cost against balance
		if Ethers.big_uint_math(transaction["balance"], "LESS THAN", predicted_gas_cost):
			emit_error("Gas fee " + str(predicted_gas_cost) + " greater than gas balance", account, network)
			return
		
		# Check gas cost against maximum gas fee
		if transaction["maximum_gas_fee"] != "":
			var maximum_gas_fee = Ethers.convert_to_bignum(transaction["maximum_gas_fee"])
			if Ethers.big_uint_math(predicted_gas_cost, "GREATER THAN", maximum_gas_fee):
				emit_error("Gas fee " + str(predicted_gas_cost) + " too high", account, network)
				return
		
		var network_info = Ethers.network_info.duplicate()
		var chain_id = network_info[network]["chain_id"]
		var rpc = network_info[network]["rpcs"][0]
		
		if !transaction["eth_transfer_args"]:
			
			# Contract Interaction
			
			var params = [Ethers.get_key(account), chain_id, transaction["contract"], rpc, transaction["gas_limit"], transaction["gas_price"], transaction["tx_count"], transaction["value"], transaction["calldata"]]
			var signed_calldata = "0x" + GodotSigner.callv("sign_raw_calldata", params)
			params = Ethers.clear_memory()
			params.clear()
			
			Ethers.perform_request(
				"eth_sendRawTransaction", 
				[signed_calldata], 
				network, 
				self, 
				"get_transaction_hash", 
				{"transaction": transaction}
				)
				
			return
		
		# ETH transfer
		
		var params = [Ethers.get_key(account), chain_id, transaction["contract"], rpc, transaction["gas_price"], transaction["tx_count"]]
		for arg in transaction["eth_transfer_args"]:
			params.push_back(arg)
		
		var calldata = "0x" + GodotSigner.callv("transfer", params)
		params = Ethers.clear_memory()
		params.clear()
		
		Ethers.perform_request(
			"eth_sendRawTransaction", 
			[calldata], 
			network, 
			self, 
			"get_transaction_hash", 
			{"transaction": transaction}
			)
	
	else:
		emit_error("RPC error: Failed to estimate gas fee", account, network)


func get_transaction_hash(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	var account = transaction["account"]
	var scan_url = Ethers.network_info[network]["scan_url"]
	
	if callback["success"]:
			transaction["transaction_hash"] = callback["result"]
			Ethers.transmit_transaction_object(transaction.duplicate())

			transaction["check_for_receipt"] = true
	else:
		emit_error("RPC error: Failed to get TX hash", account, network)


func check_for_tx_receipt(transaction, delta):
	transaction["tx_receipt_poll_timer"] -= delta
	if transaction["tx_receipt_poll_timer"] < 0:
		transaction["tx_receipt_poll_timer"] = 4
		Ethers.perform_request(
			"eth_getTransactionReceipt", 
			[transaction["transaction_hash"]], 
			transaction["network"], 
			self, 
			"check_transaction_receipt",
			{"transaction": transaction}
			)


func check_transaction_receipt(callback):
	var transaction = callback["callback_args"]["transaction"]
	var network = transaction["network"]
	var account = transaction["account"]
	
		
	if callback["success"]:
		if callback["result"] != null:
			
			var tx_callback_node = transaction["callback_node"]
			var tx_callback_function = transaction["callback_function"]
			var tx_callback_args = transaction["callback_args"]
	
			var tx_callback = {
				"success": true,
				"result": callback["result"],
				"status": callback["result"]["status"],
				"callback_args": tx_callback_args,
				"network": network,
				"account": account
			}
			
			transaction["transaction_receipt"] = callback["result"]
			transaction["tx_status"] = "SUCCESS"
			finish_transaction(account, network, transaction)
			if is_instance_valid(tx_callback_node):
				tx_callback_node.call(tx_callback_function, tx_callback)
			
	else:
		emit_error("RPC error: Failed to get TX receipt", account, network)
		
		

func finish_transaction(account, network, transaction):
	Ethers.transmit_transaction_object(transaction.duplicate())
	pending_transactions[account].erase(network)


func emit_error(error_string, account, network):
	error = error_string
	print(error + " on " + network)
	var transaction = pending_transactions[account][network]
	transaction["tx_status"] = error
	finish_transaction(account, network, transaction)
