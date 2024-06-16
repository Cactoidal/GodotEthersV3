extends Node3D

# An interface for the Cross-Chain Interoperability Protocol.

# ccip_network_info, containing things like the OnRamp and
# Router contracts, can be found at the bottom of this script.
# It is meant to be used in conjunction with Ethers.network_info.

var networks
var active_account
var selected_sender_network
var selected_destination_network
var transaction_history = {}
var recent_transactions = {}
var previous_blocks = {}
var downshift = 0
var balance_update_timer = 10
# DEBUG
var beam_timer = 2

func _ready():
	
	#DEBUG 
	# How to convert bytes back to a string
	#var from_hex = "6565656565".hex_decode()
	#print(from_hex.get_string_from_utf8())
	
	var fadein = create_tween()
	fadein.tween_property($Fadein,"modulate:a", 0, 1).set_trans(Tween.TRANS_LINEAR)
	fadein.play()
	
	$Back.connect("pressed", back)
	$Login/Login.connect("pressed", create_account)
	$Key/Copy.connect("pressed", copy_address)
	networks = Ethers.network_info.keys()
	for network in networks:
		
		recent_transactions[network] = {
			"transaction_hash": ""
		}
		
		previous_blocks[network] = "latest"


var poll_speed = 0.1
func _process(delta):
	
	# DEBUG
	#beam_timer -= delta
	#if beam_timer < 0:
		#beam_timer = 0
		#beam_message()
	
	poll_speed -= delta
	if poll_speed < 0:
		poll_speed = 1
		
		# DEBUG
		observe_onramps()
	
	# DEBUG
	if active_account:
		balance_update_timer -= delta
		if balance_update_timer < 0:
			balance_update_timer = 10
			update_balances()
	
	$FogVolume.rotate_y(delta)
	$Transporter/Pivot.rotate_y(delta/3)
	$Transporter/ReversePivot.rotate_y(-delta/3)
	
	look_for_hashes()
	
	
func create_account():
	var name = "TEST_KEYSTORE7"
	var password = $Login/Password.text
	# Check if an account name exists before creating it.
	# Otherwise, the original will be overwritten.
	if !Ethers.account_exists(name):
		# Accounts are created by generating cryptographically 
		# secure bytes, and encrypting them with a key
		# derived from your password using the PBKDF2 algorithm.
		# The encrypted bytes are saved into a file with the
		# same name as the account name.
		Ethers.create_account(name, password)
	
	login(name, password)

	# Remove passwords from memory by overwriting them
	# with random bytes, and clearing the bytes.
	$Login/Password.text = ""
	password = Ethers.clear_memory()
	password.clear()


# An account must be logged in to send transactions.
func login(account, password):
	if !Ethers.login(account, password):
		return
	password = Ethers.clear_memory()
	password.clear()
	$Login.visible = false
	var fadein = create_tween()
	fadein.tween_property($Key,"modulate:a", 1, 1).set_trans(Tween.TRANS_LINEAR)
	fadein.play()
	
	active_account = account
	$Key/Address.text = Ethers.get_address(active_account)
	
	# DEBUG
	#update_balances()
	
	
	
	#selected_sender_network = "Base Sepolia"
	#selected_destination_network = "Arbitrum Sepolia"
	#var amount = Ethers.convert_to_bignum("0.01")
	#initiate_bridge(amount)
	#var token_contract = ccip_network_info["Base Sepolia"]["token_contract"]
	
	# DEBUG
	#bridge(active_account, selected_sender_network, selected_destination_network, token_contract, amount)


func update_balances():
	for network in networks:
		
		# A built-in for retrieving and decoding the account gas balance
		# for a given network.
		Ethers.get_gas_balance(
			network, 
			active_account, 
			self, 
			"get_gas_balance"
			)
		
		var token_contract = ccip_network_info[network]["token_contract"]
		var user_address = Ethers.get_address(active_account)
		
		# A built-in that obtains the name and decimals of a given
		# ERC20 token, along with the token balance for a provided address.
		Ethers.get_erc20_info(
			network, 
			user_address, 
			token_contract, 
			self, 
			"get_erc20_info",
			)


# Process the callback result in your callback function.
func get_gas_balance(callback):
	var network = callback["network"]
	var account = callback["account"]
	if callback["success"]:
		# The gas balance returns as a single, decoded String.
		var balance = callback["result"]
		print(account + " has gas balance of " + balance + " on " + network)


func get_erc20_info(callback):
	var network = callback["network"]
	var callback_args = callback["callback_args"]
	var address = callback_args["address"]
	if callback["success"]:
		# The ERC20 info returns as an array of values.
		var erc20_name = callback["result"][0]
		var decimals = callback["result"][1]
		var balance = callback["result"][2]
		print(address + " has " + balance + " " + erc20_name + " tokens with " + decimals + " decimals on " + network)


func another_test_transaction():
	
	var why = [
		"849289742389",
		"0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba",
		"0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba",
		"34665",
		"34783264742",
		false,
		"46724",
		"2Bd1324482B9036708a7659A3FCe20DfaDD455ba",
		"23477823647862347",
		"e0e0e0e0e0",
		[ 
			["0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba", "3247678246"]
		],
			[],
			"e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0"
	]
	
	var calldata = Ethers.get_calldata("WRITE", TEST_ABI, "ok", [why])
	
	Ethers.send_transaction(
		active_account, 
		"Base Sepolia", 
		"0xd2e6c713dB06B38734a3d3358EF20d45E2e97071",
		calldata,
		self,
		"get_receipt",
		{"transaction_type": "TEST"})
	#print(calldata)


func decode2():
	var calldata = "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000c5bd9d08350000000000000000000000002bd1324482b9036708a7659a3fce20dfadd455ba0000000000000000000000002bd1324482b9036708a7659a3fce20dfadd455ba000000000000000000000000000000000000000000000000000000000000876900000000000000000000000000000000000000000000000000000008193e7fe60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b6840000000000000000000000002bd1324482b9036708a7659a3fce20dfadd455ba000000000000000000000000000000000000000000000000005368f4caa14e4b00000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000240e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000005e0e0e0e0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000002bd1324482b9036708a7659a3fce20dfadd455ba00000000000000000000000000000000000000000000000000000000c193a3260000000000000000000000000000000000000000000000000000000000000000"
	var function = Calldata.get_function(TEST_ABI, "ok")
	var inputs = Calldata.get_function_inputs(function)
	var decoded = Calldata.abi_decode(inputs, calldata)
	print(decoded)
	
	


func observe_onramps():
	# First, get the current block number for each chain.
	# It will be used to set the block range, since a variable
	# number of blocks may have occurred between polls.
	for network in networks:
		Ethers.perform_request(
		"eth_blockNumber", 
		[], 
		network, 
		self, 
		"get_ccip_messages"
		)
	
	

func get_ccip_messages(callback):
	if callback["success"]:
		
		var latest_block = callback["result"]
		var network = callback["network"]
		
		if latest_block == previous_blocks[network]:
			return
		
		var previous_block = previous_blocks[network]
		var params = {
			"fromBlock": previous_block, 
			# The array of onramp contracts
			"address": ccip_network_info[network]["onramp_contracts"].duplicate(), 
			# The "CCIPSendRequested" event topic hash
			"topics": ["0xd0c3c799bf9e2639de44391e7f524d229b2b55f5b1ea94b2bf7da42f7243dddd"]
			}
		
		
		# Set the block range.
		if previous_block != "latest":
			params["toBlock"] = latest_block
		
		previous_blocks[network] = latest_block
		
		Ethers.perform_request(
			"eth_getLogs", 
			[params],
			network,
			self,
			"decode_EVM2EVM_message"
			)
	


func decode_EVM2EVM_message(callback):
	if callback["success"]:
		var network = callback["network"]
		for event in callback["result"]:
			
			# First, check the destination chain by determining which
			# OnRamp sent the message.
			var onramp_contract = event["address"]
			var to_network
			var onramp_list = ccip_network_info[network]["onramp_contracts_by_network"]
			for sender in onramp_list:
				# Some RPC nodes return contract addresses with lowercase letters,
				# while some do not.
				if sender["contract"] != onramp_contract:
					onramp_contract = onramp_contract.to_lower()
				if sender["contract"] == onramp_contract:
					to_network = sender["network"]
				
			# The message data will be an EVM2EVM message in the form of
			# ABI encoded bytes.
			#var message = event["data"]
			var _message = event["data"]#.trim_prefix("0x0000000000000000000000000000000000000000000000000000000000000020")
			
			#var message = Calldata.abi_decode([{"type": "bytes"}], _message)
			
			
			var EVM2EVMMessage = {
				"type": "tuple",
				
				"components": [
					{"type": "uint64"}, # sourceChainSelector
					{"type": "address"}, # sender
					{"type": "address"}, # receiver
					{"type": "uint64"}, # sequenceNumber
					{"type": "uint256"}, # gasLimit
					{"type": "bool"}, # strict
					{"type": "uint64"}, # nonce
					{"type": "address"}, # feeToken
					{"type": "uint256"}, # feeTokenAmount
					{"type": "bytes"}, # data
					{"type": "tuple[]", # tokenAmounts
					"components": [
						{"type": "address"}, # token
						{"type": "uint256"} # amount
						]},
					{"type": "bytes[]"}, # sourceTokenData
					{"type": "bytes32"} # messageId
				]
				
				}
			
			var decoded_message = Calldata.abi_decode([EVM2EVMMessage], _message)
			print(decoded_message)
			$Log.text += network + str(decoded_message)
			
			#$Log.text += network + str(message)





func decode():
	var calldata = "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000008f90b8876dee65380000000000000000000000000c09808315aaae86cfebb54d124ae065439d16040000000000000000000000000c09808315aaae86cfebb54d124ae065439d16040000000000000000000000000000000000000000000000000000000000000dab0000000000000000000000000000000000000000000000000000000000015f9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000420000000000000000000000000000000000000600000000000000000000000000000000000000000000000000007e3125b4e77000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000002806a62d41616855c8d434ff5c97686e1368128993431099e0308c39f9bde74ddaf0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000056565656565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000088a2d74f47a237a62e7a51cdda67270ce381555e000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000"
	
	#calldata = calldata.trim_prefix("0x0000000000000000000000000000000000000000000000000000000000000020")
	
	var EVM2EVMMessage = {
				"type": "tuple",
				
				"components": [
					{"type": "uint64"}, # sourceChainSelector
					{"type": "address"}, # sender
					{"type": "address"}, # receiver
					{"type": "uint64"}, # sequenceNumber
					{"type": "uint256"}, # gasLimit
					{"type": "bool"}, # strict
					{"type": "uint64"}, # nonce
					{"type": "address"}, # feeToken
					{"type": "uint256"}, # feeTokenAmount
					{"type": "bytes"}, # data
					{"type": "tuple[]", # tokenAmounts
					"components": [
						{"type": "address"}, # token
						{"type": "uint256"} # amount
						]},
					{"type": "bytes[]"}, # sourceTokenData
					{"type": "bytes32"} # messageId
				]
				
				}
	print("ganbatte")
	var decoded_message = Calldata.abi_decode([EVM2EVMMessage], calldata)



func encode():
	
	var EVMTokenAmount = [
		"0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba",
		"3476332"
	]
	

	var EVM2EVMMessage = [
		"34762", 
		"0x0c09808315aaae86cfebb54d124ae065439d1604",
		"0x0c09808315aaae86cfebb54d124ae065439d1604", 
		"237", 
		"32476723",
		true,
		"4633",
		"0x114A20A10b43D4115e5aeef7345a1A71d2a60C57",
		"463636534",
		"e0e0e0e0",
		[EVMTokenAmount],
		[""],
		"6a62d41616855c8d434ff5c97686e1368128993431099e0308c39f9bde74ddaf"
	]
	
	var calldata = Ethers.get_calldata("WRITE", CALLDATA_TESTER, "ok", [EVM2EVMMessage])
	print(calldata)




# Automatically approves the router's spend allowance,
# gets the CCIP fee, and sends the CCIP message.
func initiate_bridge(amount):
	var token_contract = ccip_network_info[selected_sender_network]["token_contract"]
	
	bridge(
		active_account,
		selected_sender_network,
		selected_destination_network,
		token_contract,
		amount)
	

func bridge(account, from_network, to_network, token, amount):
	
	var address = Ethers.get_address(account)
	
	# Structs are declared as arrays containing
	# their expected types.
	var EVMTokenAmount = [
		token,
		amount
	]
	
	var EVMExtraArgsV1 = [
		"90000" # Destination gas limit
	]
	
	# You can ABI encode and decode values directly by using
	# the Calldata singleton.  You must provide the input
	# or output types along with the values to encode/decode.
	var extra_args = "97a657c9" + Calldata.abi_encode( [{"type": "tuple", "components":[{"type": "uint256"}]}], [EVMExtraArgsV1] )
	
	var EVM2AnyMessage = [
		Calldata.abi_encode( [{"type": "address"}], [address] ), # ABI-encoded recipient address
		Calldata.abi_encode( [{"type": "string"}], ["eeeeeOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO"] ), # Data payload, as bytes
		[EVMTokenAmount], # EVMTokenAmounts
		"0x0000000000000000000000000000000000000000", # Fee address (address(0) = native token)
		extra_args # Extra args
	]
	
	var chain_selector = ccip_network_info[to_network]["chain_selector"]
	
	var callback_args = {
		"EVM2AnyMessage": EVM2AnyMessage,
		"chain_selector": chain_selector,
		"transaction_type": "Approval"
		}
		
	callback_args["account"] = account
	callback_args["network"] = from_network
	
	var router = ccip_network_info[from_network]["router"]
	callback_args["contract"] = router
	
	# A built-in for granting spend allowances to a contract.
	Ethers.approve_erc20_allowance(account, from_network, token, router, self, "get_receipt", callback_args)


# Estimates the CCIP fee before sending the message.
func get_native_fee(callback):
	if callback["success"]:
		var network = callback["network"]
		var callback_args = callback["callback_args"]
		var EVM2AnyMessage = callback_args["EVM2AnyMessage"]
		var chain_selector = callback_args["chain_selector"]
		var contract = callback_args["contract"]
		
		# A built-in for constructing calldata using the ABI,
		# (here called CCIP_ROUTER), the contract function name,
		# and the input values expected by the function.
		
		# Since we're specifying "READ", this request will 
		# automatically decode the response from the RPC node.
		var calldata = Ethers.get_calldata("READ", CCIP_ROUTER, "getFee", [chain_selector, EVM2AnyMessage])
		
		Ethers.read_from_contract(network, contract, calldata, self, "ccip_bridge", callback_args)


func ccip_bridge(callback):
	if callback["success"]:
		var network = callback["network"]
		var callback_args = callback["callback_args"]
		var EVM2AnyMessage = callback_args["EVM2AnyMessage"]
		var chain_selector = callback_args["chain_selector"]
		var account = callback_args["account"]
		var contract = callback_args["contract"]
		
		# Because a contract read can return multple values,
		# successful returns from "read_from_contract()" will 
		# always arrive as an array of decoded outputs.
		var fee = callback["result"][0]
		fee = float(Ethers.convert_to_smallnum(fee))
		fee *= 1.1
		fee = Ethers.convert_to_bignum(str(fee))
		
		# Get calldata again, this time specifying "WRITE"
		# since we intend to send a transaction.
		var calldata = Ethers.get_calldata("WRITE", CCIP_ROUTER, "ccipSend", [chain_selector, EVM2AnyMessage])
		
		# The fee value acquired above is passed as the "value" parameter.
		Ethers.send_transaction(
			account, 
			network, 
			contract, 
			calldata, 
			self, 
			"get_receipt", 
			{"transaction_type": "CCIP"}, 
			"900000", 
			fee
			)


func look_for_hashes():
	for network in networks:
		# Ethers tracks the most recent transaction for each network,
		# along with each transaction's callback_args.
		if network in Ethers.recent_transactions.keys():
			# Compare the transaction hashes to check for a new transaction.
			if Ethers.recent_transactions[network]["transaction_hash"] != recent_transactions[network]["transaction_hash"]:
				recent_transactions[network] = Ethers.recent_transactions[network]
				add_new_transaction(network, recent_transactions[network])


func add_new_transaction(network, transaction):
	var transaction_type = transaction["callback_args"]["transaction_type"]
	var transaction_hash = transaction["transaction_hash"]

	var transaction_object = instantiate_transaction(network, transaction_type, transaction_hash)
	
	# The transaction object is mapped to the transaction hash, so
	# its status can later be updated by the transaction receipt.
	transaction_history[transaction_hash] = transaction_object
	
	$Transactions/Transactions.add_child(transaction_object)
	transaction_object.position.y += downshift
	$Transactions/Transactions.custom_minimum_size.y += 108
	downshift += 108
	transaction_object.modulate.a = 0
	var fadein = create_tween()
	fadein.tween_property(transaction_object,"modulate:a", 1, 2).set_trans(Tween.TRANS_LINEAR)
	fadein.play()


# The transaction receipt returns as a single value, a dictionary.
func get_receipt(callback):	
	if callback["success"]:
		
		var transaction_hash = callback["result"]["transactionHash"]
		var status = callback["result"]["status"]
		var tx_object = transaction_history[transaction_hash]
		
		if status == "0x1":
			tx_object.get_node("Status").color = Color.GREEN
			if tx_object.get_node("Info").text.contains("CCIP"):
				beam_message()
			elif tx_object.get_node("Info").text.contains("Approval"):
				get_native_fee(callback)
		else:
			tx_object.get_node("Status").color = Color.RED


# Opens the passed url in the system's default browser
func open_link(url):
	OS.shell_open(url)


func choose_sender_network():
	pass


func choose_destination_network():
	pass
	
	
func get_test_tokens(network):
	var token_contract = ccip_network_info[network]["token_contract"]
	var address = Ethers.get_address(active_account)
	# An example of how to manually construct calldata, even without an ABI.
	
	var function_selector = {
		"name": "drip",
		"inputs": [{"type": "address"}]
	}
	
	var calldata = {
		"calldata": Calldata.get_function_selector(function_selector) + Calldata.abi_encode( [{"type": "address"}], [address] )
		}
		
	Ethers.send_transaction(active_account, network, token_contract, calldata, self, "get_receipt", {"transaction_type": "Mint"})


func copy_address():
	var user_address = Ethers.get_address(active_account)
	DisplayServer.clipboard_set(user_address)
	$Key/Prompt.modulate.a = 1
	var fadein = create_tween()
	fadein.tween_property($Key/Prompt,"modulate:a", 0, 2.8).set_trans(Tween.TRANS_LINEAR)
	fadein.play()


func back():
	# Logging out will clear your encrypted password from memory,
	# and clear the transaction log.
	Ethers.logout()
	queue_free()


func beam_message():
	$Beam.visible = true
	var top_tween = create_tween()
	var bottom_tween = create_tween()
	top_tween.tween_property($Beam.mesh, "top_radius", 0.4, 0.1)
	bottom_tween.tween_property($Beam.mesh, "bottom_radius", 0.4, 0.1)
	top_tween.play()
	bottom_tween.play()



# It's much easier to simply build external scenes as needed and instantiate
# them on demand.  Here however I construct the transaction object in code,
# to comply with the hypothetical "1 scene, 1 script" rule for modules.

# In practice, it may be easier to audit multiple simple scenes (within reason)
# than to sort through dense blocks of node-building code.
func instantiate_transaction(network, transaction_type, transaction_hash):
	var scan_url = Ethers.network_info[network]["scan_url"]
	var new_transaction = Panel.new()
	new_transaction.size = Vector2(146,104)
	var info = Label.new()
	var scan_link = Button.new()
	var ccip_link = Button.new()
	var status = ColorRect.new()
	info.name = "Info"
	status.size = Vector2(15,15)
	status.name = "Status"
	info.text = transaction_type + ":\n" + network
	scan_link.text = "Scan"
	ccip_link.text = "CCIP"
	scan_link.connect("pressed", open_link.bind(scan_url + "tx/" + transaction_hash))
	ccip_link.connect("pressed", open_link.bind("https://ccip.chain.link/tx/" + transaction_hash))
	scan_link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ccip_link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	new_transaction.add_child(info)
	new_transaction.add_child(scan_link)
	new_transaction.add_child(ccip_link)
	new_transaction.add_child(status)
	info.position = Vector2(5,4)
	scan_link.position = Vector2(12,65)
	ccip_link.position = Vector2(86,65)
	status.position = Vector2(127,3)
	if transaction_type != "CCIP":
		ccip_link.visible = false
	return new_transaction


#####   ABI   #####

var CCIP_ROUTER = [
  {
	"inputs": [],
	"name": "InsufficientFeeTokenAmount",
	"type": "error"
  },
  {
	"inputs": [],
	"name": "InvalidMsgValue",
	"type": "error"
  },
  {
	"inputs": [
	  {
		"internalType": "uint64",
		"name": "destChainSelector",
		"type": "uint64"
	  }
	],
	"name": "UnsupportedDestinationChain",
	"type": "error"
  },
  {
	"inputs": [
	  {
		"internalType": "uint64",
		"name": "destinationChainSelector",
		"type": "uint64"
	  },
	  {
		"components": [
		  {
			"internalType": "bytes",
			"name": "receiver",
			"type": "bytes"
		  },
		  {
			"internalType": "bytes",
			"name": "data",
			"type": "bytes"
		  },
		  {
			"components": [
			  {
				"internalType": "address",
				"name": "token",
				"type": "address"
			  },
			  {
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			  }
			],
			"internalType": "struct Client.EVMTokenAmount[]",
			"name": "tokenAmounts",
			"type": "tuple[]"
		  },
		  {
			"internalType": "address",
			"name": "feeToken",
			"type": "address"
		  },
		  {
			"internalType": "bytes",
			"name": "extraArgs",
			"type": "bytes"
		  }
		],
		"internalType": "struct Client.EVM2AnyMessage",
		"name": "message",
		"type": "tuple"
	  }
	],
	"name": "ccipSend",
	"outputs": [
	  {
		"internalType": "bytes32",
		"name": "",
		"type": "bytes32"
	  }
	],
	"stateMutability": "payable",
	"type": "function"
  },
  {
	"inputs": [
	  {
		"internalType": "uint64",
		"name": "destinationChainSelector",
		"type": "uint64"
	  },
	  {
		"components": [
		  {
			"internalType": "bytes",
			"name": "receiver",
			"type": "bytes"
		  },
		  {
			"internalType": "bytes",
			"name": "data",
			"type": "bytes"
		  },
		  {
			"components": [
			  {
				"internalType": "address",
				"name": "token",
				"type": "address"
			  },
			  {
				"internalType": "uint256",
				"name": "amount",
				"type": "uint256"
			  }
			],
			"internalType": "struct Client.EVMTokenAmount[]",
			"name": "tokenAmounts",
			"type": "tuple[]"
		  },
		  {
			"internalType": "address",
			"name": "feeToken",
			"type": "address"
		  },
		  {
			"internalType": "bytes",
			"name": "extraArgs",
			"type": "bytes"
		  }
		],
		"internalType": "struct Client.EVM2AnyMessage",
		"name": "message",
		"type": "tuple"
	  }
	],
	"name": "getFee",
	"outputs": [
	  {
		"internalType": "uint256",
		"name": "fee",
		"type": "uint256"
	  }
	],
	"stateMutability": "view",
	"type": "function"
  },
  {
	"inputs": [
	  {
		"internalType": "uint64",
		"name": "chainSelector",
		"type": "uint64"
	  }
	],
	"name": "getSupportedTokens",
	"outputs": [
	  {
		"internalType": "address[]",
		"name": "tokens",
		"type": "address[]"
	  }
	],
	"stateMutability": "view",
	"type": "function"
  },
  {
	"inputs": [
	  {
		"internalType": "uint64",
		"name": "chainSelector",
		"type": "uint64"
	  }
	],
	"name": "isChainSupported",
	"outputs": [
	  {
		"internalType": "bool",
		"name": "supported",
		"type": "bool"
	  }
	],
	"stateMutability": "view",
	"type": "function"
  }
]



#####   NETWORK INFO   #####

var ccip_network_info = {
	
	"Ethereum Sepolia": 
		{
		"chain_selector": "16015286601757825753",
		"router": "0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59",
		"token_contract": "0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05",
		"onramp_contracts": ["0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e", "0x69CaB5A0a08a12BaFD8f5B195989D709E396Ed4d", "0x2B70a05320cB069e0fB55084D402343F832556E7", "0x0477cA0a35eE05D3f9f424d88bC0977ceCf339D4"],
		"onramp_contracts_by_network": 
			[
				{
					"network": "Arbitrum Sepolia",
					"contract": "0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e"
				},
				{
					"network": "Optimism Sepolia",
					"contract": "0x69CaB5A0a08a12BaFD8f5B195989D709E396Ed4d"
				},
				{
					"network": "Base Sepolia",
					"contract": "0x2B70a05320cB069e0fB55084D402343F832556E7"
				},
				{
					"network": "Avalanche Fuji",
					"contract": "0x0477cA0a35eE05D3f9f424d88bC0977ceCf339D4"
				}
			
		],
		"endpoint_contract": "0xFFA6c081b6A7F5F3816D9052C875E4C6B662137a",
		"monitored_tokens": []
		},
		
	"Arbitrum Sepolia": 
		{
		"chain_selector": "3478487238524512106",
		"router": "0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165",
		"token_contract": "0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D",
		"onramp_contracts": ["0x4205E1Ca0202A248A5D42F5975A8FE56F3E302e9", "0x701Fe16916dd21EFE2f535CA59611D818B017877", "0x7854E73C73e7F9bb5b0D5B4861E997f4C6E8dcC6", "0x1Cb56374296ED19E86F68fA437ee679FD7798DaA"],
		"onramp_contracts_by_network": 
			[
				{
					"network": "Ethereum Sepolia",
					"contract": "0x4205E1Ca0202A248A5D42F5975A8FE56F3E302e9"
				},
				{
					"network": "Optimism Sepolia",
					"contract": "0x701Fe16916dd21EFE2f535CA59611D818B017877"
				},
				{
					"network": "Base Sepolia",
					"contract": "0x7854E73C73e7F9bb5b0D5B4861E997f4C6E8dcC6"
				},
				{
					"network": "Avalanche Fuji",
					"contract": "0x1Cb56374296ED19E86F68fA437ee679FD7798DaA"
				}
			
		],
		"endpoint_contract": "0xcA57f7b1FDfD3cbD513954938498Fe6a9bc8FF63",
		"monitored_tokens": []
		},
		
	"Optimism Sepolia": {
		"chain_selector": "5224473277236331295",
		"router": "0x114A20A10b43D4115e5aeef7345a1A71d2a60C57",
		"token_contract": "0x8aF4204e30565DF93352fE8E1De78925F6664dA7",
		"onramp_contracts": ["0xC8b93b46BF682c39B3F65Aa1c135bC8A95A5E43a", "0x1a86b29364D1B3fA3386329A361aA98A104b2742", "0xe284D2315a28c4d62C419e8474dC457b219DB969", "0x6b38CC6Fa938D5AB09Bdf0CFe580E226fDD793cE"],
		"onramp_contracts_by_network": 
			[
				{
					"network": "Ethereum Sepolia",
					"contract": "0xC8b93b46BF682c39B3F65Aa1c135bC8A95A5E43a"
				},
				{
					"network": "Arbitrum Sepolia",
					"contract": "0x1a86b29364D1B3fA3386329A361aA98A104b2742"
				},
				{
					"network": "Base Sepolia",
					"contract": "0xe284D2315a28c4d62C419e8474dC457b219DB969"
				},
				{
					"network": "Avalanche Fuji",
					"contract": "0x6b38CC6Fa938D5AB09Bdf0CFe580E226fDD793cE"
				}
			
		],
		"endpoint_contract": "0x04Ba932c452ffc62CFDAf9f723e6cEeb1C22474b",
		"monitored_tokens": []
	},
	
	"Base Sepolia": {
		"chain_selector": "10344971235874465080",
		"router": "0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93",
		"token_contract": "0x88A2d74F47a237a62e7A51cdDa67270CE381555e",
		"onramp_contracts": ["0x6486906bB2d85A6c0cCEf2A2831C11A2059ebfea", "0x58622a80c6DdDc072F2b527a99BE1D0934eb2b50", "0x3b39Cd9599137f892Ad57A4f54158198D445D147", "0xAbA09a1b7b9f13E05A6241292a66793Ec7d43357"],
		"onramp_contracts_by_network": 
			[
				{
					"network": "Ethereum Sepolia",
					"contract": "0x6486906bB2d85A6c0cCEf2A2831C11A2059ebfea"
				},
				{
					"network": "Arbitrum Sepolia",
					"contract": "0x58622a80c6DdDc072F2b527a99BE1D0934eb2b50"
				},
				{
					"network": "Optimism Sepolia",
					"contract": "0x3b39Cd9599137f892Ad57A4f54158198D445D147"
				},
				{
					"network": "Avalanche Fuji",
					"contract": "0xAbA09a1b7b9f13E05A6241292a66793Ec7d43357"
				}
			
		],
		"endpoint_contract": "0xD7e4A13c7896edA172e568eB6E35Da68d3572127",
		"monitored_tokens": []
	},
	
	"Avalanche Fuji": {
		"chain_selector": "14767482510784806043",
		"router": "0xF694E193200268f9a4868e4Aa017A0118C9a8177",
		"token_contract": "0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4",
		"onramp_contracts": ["0x5724B4Cc39a9690135F7273b44Dfd3BA6c0c69aD", "0x8bB16BEDbFd62D1f905ACe8DBBF2954c8EEB4f66", "0xC334DE5b020e056d0fE766dE46e8d9f306Ffa1E2", "0x1A674645f3EB4147543FCA7d40C5719cbd997362"],
		"onramp_contracts_by_network": 
			[
				{
					"network": "Ethereum Sepolia",
					"contract": "0x5724B4Cc39a9690135F7273b44Dfd3BA6c0c69aD"
				},
				{
					"network": "Arbitrum Sepolia",
					"contract": "0x8bB16BEDbFd62D1f905ACe8DBBF2954c8EEB4f66"
				},
				{
					"network": "Optimism Sepolia",
					"contract": "0xC334DE5b020e056d0fE766dE46e8d9f306Ffa1E2"
				},
				{
					"network": "Base Sepolia",
					"contract": "0x1A674645f3EB4147543FCA7d40C5719cbd997362"
				}
			
		],
		"endpoint_contract": "N/A",
		"monitored_tokens": []
	}
}





# # ExtraArgsV2 appears to be broken, at least on the Base Sepolia -> Arbitrum Sepolia lane.
	# Or I'm missing something.
	
	#var EVMExtraArgsV2 = [
		#"90000", # Destination gas limit
		#false # Allow out of order execution
	#]
	#
	#var extra_args = "181dcf10" + Calldata.abi_encode( [{"type": "tuple", "components":[{"type": "uint256"}, {"type": "bool"}]}], [EVMExtraArgsV2] )
	
	
	# ExtraArgsV1 works, however.




var CALLDATA_TESTER = [
	{
		"inputs": [],
		"name": "_13",
		"outputs": [
			{
				"internalType": "bytes13",
				"name": "",
				"type": "bytes13"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_27",
		"outputs": [
			{
				"internalType": "bytes27",
				"name": "",
				"type": "bytes27"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_32",
		"outputs": [
			{
				"internalType": "bytes32",
				"name": "",
				"type": "bytes32"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_8",
		"outputs": [
			{
				"internalType": "bytes8",
				"name": "",
				"type": "bytes8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "challengeCleared",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "cooled",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "didThing",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "fixedNestedStructArrayReturn",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "num1",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "coolBool",
						"type": "bool"
					},
					{
						"internalType": "uint16",
						"name": "amazingNum",
						"type": "uint16"
					}
				],
				"internalType": "struct CallDataTester.staticTuple[2][2]",
				"name": "",
				"type": "tuple[2][2]"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "fixedStructArrayReturn",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "num1",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "coolBool",
						"type": "bool"
					},
					{
						"internalType": "uint16",
						"name": "amazingNum",
						"type": "uint16"
					}
				],
				"internalType": "struct CallDataTester.staticTuple[2]",
				"name": "",
				"type": "tuple[2]"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[][3][]",
				"name": "",
				"type": "string[][3][]"
			}
		],
		"name": "funnyArray",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "gauntletCleared",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[][][]",
				"name": "_many",
				"type": "string[][][]"
			}
		],
		"name": "manyDynamicNested",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "messageId",
		"outputs": [
			{
				"internalType": "bytes32",
				"name": "",
				"type": "bytes32"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "muhData",
		"outputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "myDifficultTuple",
		"outputs": [
			{
				"internalType": "string",
				"name": "indeed",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "myDynamicTuple",
		"outputs": [
			{
				"internalType": "string",
				"name": "niceString",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "awooga",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "impressiveString",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "myStaticTuple",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "num1",
				"type": "uint256"
			},
			{
				"internalType": "bool",
				"name": "coolBool",
				"type": "bool"
			},
			{
				"internalType": "uint16",
				"name": "amazingNum",
				"type": "uint16"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "nestedFriend",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint64",
						"name": "sourceChain",
						"type": "uint64"
					},
					{
						"internalType": "address",
						"name": "sender",
						"type": "address"
					},
					{
						"internalType": "address",
						"name": "receiver",
						"type": "address"
					},
					{
						"internalType": "uint64",
						"name": "number",
						"type": "uint64"
					},
					{
						"internalType": "uint256",
						"name": "gas",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "strict",
						"type": "bool"
					},
					{
						"internalType": "uint64",
						"name": "count",
						"type": "uint64"
					},
					{
						"internalType": "address",
						"name": "token",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "bytes",
						"name": "data",
						"type": "bytes"
					},
					{
						"components": [
							{
								"internalType": "address",
								"name": "token",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "amount",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.tokenAmounts[]",
						"name": "tokens",
						"type": "tuple[]"
					},
					{
						"internalType": "bytes[]",
						"name": "sourceData",
						"type": "bytes[]"
					},
					{
						"internalType": "bytes32",
						"name": "why",
						"type": "bytes32"
					}
				],
				"internalType": "struct CallDataTester.thinger",
				"name": "_thinger",
				"type": "tuple"
			}
		],
		"name": "ok",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[2][]",
				"name": "_okay",
				"type": "string[2][]"
			}
		],
		"name": "okay",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[][2]",
				"name": "_oof",
				"type": "string[][2]"
			}
		],
		"name": "oof",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "structReturn",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "num1",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "coolBool",
						"type": "bool"
					},
					{
						"internalType": "uint16",
						"name": "amazingNum",
						"type": "uint16"
					}
				],
				"internalType": "struct CallDataTester.staticTuple",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "bytes[]",
						"name": "why_not",
						"type": "bytes[]"
					},
					{
						"components": [
							{
								"internalType": "string",
								"name": "niceString",
								"type": "string"
							},
							{
								"internalType": "uint256",
								"name": "awooga",
								"type": "uint256"
							},
							{
								"internalType": "string",
								"name": "impressiveString",
								"type": "string"
							}
						],
						"internalType": "struct CallDataTester.dynamicTuple",
						"name": "_dynamic",
						"type": "tuple"
					},
					{
						"components": [
							{
								"internalType": "uint256",
								"name": "num1",
								"type": "uint256"
							},
							{
								"internalType": "bool",
								"name": "coolBool",
								"type": "bool"
							},
							{
								"internalType": "uint16",
								"name": "amazingNum",
								"type": "uint16"
							}
						],
						"internalType": "struct CallDataTester.staticTuple",
						"name": "_static",
						"type": "tuple"
					},
					{
						"components": [
							{
								"internalType": "string[]",
								"name": "why",
								"type": "string[]"
							},
							{
								"internalType": "uint256[]",
								"name": "yes",
								"type": "uint256[]"
							},
							{
								"internalType": "string",
								"name": "indeed",
								"type": "string"
							}
						],
						"internalType": "struct CallDataTester.difficultTuple",
						"name": "_difficult",
						"type": "tuple"
					}
				],
				"internalType": "struct CallDataTester.ultraTuple[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"name": "theChallenge",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[2][2]",
				"name": "_what",
				"type": "string[2][2]"
			}
		],
		"name": "what",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "why",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]



var TEST_ABI = [
	{
		"anonymous": false,
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint64",
						"name": "sourceChain",
						"type": "uint64"
					},
					{
						"internalType": "address",
						"name": "sender",
						"type": "address"
					},
					{
						"internalType": "address",
						"name": "receiver",
						"type": "address"
					},
					{
						"internalType": "uint64",
						"name": "number",
						"type": "uint64"
					},
					{
						"internalType": "uint256",
						"name": "gas",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "strict",
						"type": "bool"
					},
					{
						"internalType": "uint64",
						"name": "count",
						"type": "uint64"
					},
					{
						"internalType": "address",
						"name": "token",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "bytes",
						"name": "data",
						"type": "bytes"
					},
					{
						"components": [
							{
								"internalType": "address",
								"name": "token",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "amount",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.tokenAmounts[]",
						"name": "tokens",
						"type": "tuple[]"
					},
					{
						"internalType": "bytes[]",
						"name": "sourceData",
						"type": "bytes[]"
					},
					{
						"internalType": "bytes32",
						"name": "why",
						"type": "bytes32"
					}
				],
				"indexed": false,
				"internalType": "struct CallDataTester.thinger",
				"name": "",
				"type": "tuple"
			}
		],
		"name": "myCoolEvent",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "string[][3][]",
				"name": "",
				"type": "string[][3][]"
			}
		],
		"name": "funnyArray",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "why",
						"type": "uint256"
					},
					{
						"internalType": "address",
						"name": "WHY",
						"type": "address"
					},
					{
						"internalType": "bytes",
						"name": "indeed",
						"type": "bytes"
					},
					{
						"components": [
							{
								"internalType": "address",
								"name": "_static",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "STATIC",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.staticStruct[]",
						"name": "WHY_",
						"type": "tuple[]"
					},
					{
						"internalType": "bytes[]",
						"name": "whynot",
						"type": "bytes[]"
					},
					{
						"internalType": "bytes32",
						"name": "_okay",
						"type": "bytes32"
					}
				],
				"internalType": "struct CallDataTester.oooo",
				"name": "_struct",
				"type": "tuple"
			}
		],
		"name": "makeooo",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "why",
						"type": "uint256"
					},
					{
						"internalType": "address",
						"name": "WHY",
						"type": "address"
					},
					{
						"internalType": "address",
						"name": "okay",
						"type": "address"
					},
					{
						"internalType": "uint64",
						"name": "_why",
						"type": "uint64"
					},
					{
						"internalType": "bytes",
						"name": "indeed",
						"type": "bytes"
					},
					{
						"components": [
							{
								"internalType": "address",
								"name": "_static",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "STATIC",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.staticStruct[]",
						"name": "WHY_",
						"type": "tuple[]"
					},
					{
						"components": [
							{
								"internalType": "bytes",
								"name": "_dynamic",
								"type": "bytes"
							},
							{
								"internalType": "uint256",
								"name": "dynamic",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.dynamicStruct[]",
						"name": "AAAA",
						"type": "tuple[]"
					},
					{
						"internalType": "bytes[]",
						"name": "whynot",
						"type": "bytes[]"
					},
					{
						"internalType": "bytes32",
						"name": "_okay",
						"type": "bytes32"
					}
				],
				"internalType": "struct CallDataTester.myOtherStruct",
				"name": "_struct",
				"type": "tuple"
			}
		],
		"name": "makeOtherStruct",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "why",
						"type": "uint256"
					},
					{
						"internalType": "address",
						"name": "WHY",
						"type": "address"
					},
					{
						"internalType": "address",
						"name": "okay",
						"type": "address"
					},
					{
						"internalType": "uint64",
						"name": "_why",
						"type": "uint64"
					},
					{
						"components": [
							{
								"internalType": "address",
								"name": "_static",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "STATIC",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.staticStruct[]",
						"name": "WHY_",
						"type": "tuple[]"
					},
					{
						"components": [
							{
								"internalType": "bytes",
								"name": "_dynamic",
								"type": "bytes"
							},
							{
								"internalType": "uint256",
								"name": "dynamic",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.dynamicStruct[]",
						"name": "AAAA",
						"type": "tuple[]"
					},
					{
						"internalType": "bytes[]",
						"name": "whynot",
						"type": "bytes[]"
					}
				],
				"internalType": "struct CallDataTester.myGreatStruct",
				"name": "_struct",
				"type": "tuple"
			}
		],
		"name": "makeStruct",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[][][]",
				"name": "_many",
				"type": "string[][][]"
			}
		],
		"name": "manyDynamicNested",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "uint64",
						"name": "sourceChain",
						"type": "uint64"
					},
					{
						"internalType": "address",
						"name": "sender",
						"type": "address"
					},
					{
						"internalType": "address",
						"name": "receiver",
						"type": "address"
					},
					{
						"internalType": "uint64",
						"name": "number",
						"type": "uint64"
					},
					{
						"internalType": "uint256",
						"name": "gas",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "strict",
						"type": "bool"
					},
					{
						"internalType": "uint64",
						"name": "count",
						"type": "uint64"
					},
					{
						"internalType": "address",
						"name": "token",
						"type": "address"
					},
					{
						"internalType": "uint256",
						"name": "amount",
						"type": "uint256"
					},
					{
						"internalType": "bytes",
						"name": "data",
						"type": "bytes"
					},
					{
						"components": [
							{
								"internalType": "address",
								"name": "token",
								"type": "address"
							},
							{
								"internalType": "uint256",
								"name": "amount",
								"type": "uint256"
							}
						],
						"internalType": "struct CallDataTester.tokenAmounts[]",
						"name": "tokens",
						"type": "tuple[]"
					},
					{
						"internalType": "bytes[]",
						"name": "sourceData",
						"type": "bytes[]"
					},
					{
						"internalType": "bytes32",
						"name": "why",
						"type": "bytes32"
					}
				],
				"internalType": "struct CallDataTester.thinger",
				"name": "_thinger",
				"type": "tuple"
			}
		],
		"name": "ok",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[2][]",
				"name": "_okay",
				"type": "string[2][]"
			}
		],
		"name": "okay",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[][2]",
				"name": "_oof",
				"type": "string[][2]"
			}
		],
		"name": "oof",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"components": [
					{
						"internalType": "bytes[]",
						"name": "why_not",
						"type": "bytes[]"
					},
					{
						"components": [
							{
								"internalType": "string",
								"name": "niceString",
								"type": "string"
							},
							{
								"internalType": "uint256",
								"name": "awooga",
								"type": "uint256"
							},
							{
								"internalType": "string",
								"name": "impressiveString",
								"type": "string"
							}
						],
						"internalType": "struct CallDataTester.dynamicTuple",
						"name": "_dynamic",
						"type": "tuple"
					},
					{
						"components": [
							{
								"internalType": "uint256",
								"name": "num1",
								"type": "uint256"
							},
							{
								"internalType": "bool",
								"name": "coolBool",
								"type": "bool"
							},
							{
								"internalType": "uint16",
								"name": "amazingNum",
								"type": "uint16"
							}
						],
						"internalType": "struct CallDataTester.staticTuple",
						"name": "_static",
						"type": "tuple"
					},
					{
						"components": [
							{
								"internalType": "string[]",
								"name": "why",
								"type": "string[]"
							},
							{
								"internalType": "uint256[]",
								"name": "yes",
								"type": "uint256[]"
							},
							{
								"internalType": "string",
								"name": "indeed",
								"type": "string"
							}
						],
						"internalType": "struct CallDataTester.difficultTuple",
						"name": "_difficult",
						"type": "tuple"
					}
				],
				"internalType": "struct CallDataTester.ultraTuple[]",
				"name": "",
				"type": "tuple[]"
			}
		],
		"name": "theChallenge",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "string[2][2]",
				"name": "_what",
				"type": "string[2][2]"
			}
		],
		"name": "what",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_13",
		"outputs": [
			{
				"internalType": "bytes13",
				"name": "",
				"type": "bytes13"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_27",
		"outputs": [
			{
				"internalType": "bytes27",
				"name": "",
				"type": "bytes27"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_32",
		"outputs": [
			{
				"internalType": "bytes32",
				"name": "",
				"type": "bytes32"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "_8",
		"outputs": [
			{
				"internalType": "bytes8",
				"name": "",
				"type": "bytes8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "challengeCleared",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "cooled",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "didThing",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "fixedNestedStructArrayReturn",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "num1",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "coolBool",
						"type": "bool"
					},
					{
						"internalType": "uint16",
						"name": "amazingNum",
						"type": "uint16"
					}
				],
				"internalType": "struct CallDataTester.staticTuple[2][2]",
				"name": "",
				"type": "tuple[2][2]"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "fixedStructArrayReturn",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "num1",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "coolBool",
						"type": "bool"
					},
					{
						"internalType": "uint16",
						"name": "amazingNum",
						"type": "uint16"
					}
				],
				"internalType": "struct CallDataTester.staticTuple[2]",
				"name": "",
				"type": "tuple[2]"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "gauntletCleared",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "messageId",
		"outputs": [
			{
				"internalType": "bytes32",
				"name": "",
				"type": "bytes32"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "muhData",
		"outputs": [
			{
				"internalType": "bytes",
				"name": "",
				"type": "bytes"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "myDifficultTuple",
		"outputs": [
			{
				"internalType": "string",
				"name": "indeed",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "myDynamicTuple",
		"outputs": [
			{
				"internalType": "string",
				"name": "niceString",
				"type": "string"
			},
			{
				"internalType": "uint256",
				"name": "awooga",
				"type": "uint256"
			},
			{
				"internalType": "string",
				"name": "impressiveString",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "myStaticTuple",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "num1",
				"type": "uint256"
			},
			{
				"internalType": "bool",
				"name": "coolBool",
				"type": "bool"
			},
			{
				"internalType": "uint16",
				"name": "amazingNum",
				"type": "uint16"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "nestedFriend",
		"outputs": [
			{
				"internalType": "uint256",
				"name": "",
				"type": "uint256"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "structReturn",
		"outputs": [
			{
				"components": [
					{
						"internalType": "uint256",
						"name": "num1",
						"type": "uint256"
					},
					{
						"internalType": "bool",
						"name": "coolBool",
						"type": "bool"
					},
					{
						"internalType": "uint16",
						"name": "amazingNum",
						"type": "uint16"
					}
				],
				"internalType": "struct CallDataTester.staticTuple",
				"name": "",
				"type": "tuple"
			}
		],
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "why",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	}
]
