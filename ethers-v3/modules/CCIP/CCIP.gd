extends Node3D

# An interface for the Cross-Chain Interoperability Protocol.

# The ccip_network_info, containing things like the OnRamp and
# Router contracts, can be found at the bottom of this script.
# It is meant to be used in conjunction with Ethers.network_info.

# Account, OnRamp monitoring, and transaction management variables
var networks
var active_account
var transaction_history = {}
var recent_transactions = {}
var previous_blocks = {}
var logged_messages = []
var poll_speed = 0.1

# Interface variables
var new_messages = 0
var downshift = 0

# Slider position constants
const log_down_y = 470
const log_up_y = 0
const bridge_up_y = 498
const bridge_down_y = 614


func _process(delta):

	poll_speed -= delta
	if poll_speed < 0:
		poll_speed = 1
		# Monitors OnRamps for new outgoing CCIP messages
		observe_onramps()
	
	# Checks Ethers.recent_transactions for new transaction hashes
	look_for_hashes()
	
	# Spins shiny things around
	$FogVolume.rotate_y(delta)
	$Transporter/Pivot.rotate_y(delta/3)
	$Transporter/ReversePivot.rotate_y(-delta/3)
	


#####     ACCOUNT SETUP     #####
	
func create_account():
	var name = "TEST_KEYSTORE7"
	var password = $Login/Password.text
	# Check if an account name exists before creating it.
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
	
	active_account = account
	$Address/Address.text = Ethers.get_address(active_account)
	
	$Login.visible = false
	fade_in($Address)
	fade_in($Balances)
	fade_in($Bridge)
	
	# Get the gas and CCIP-BnM token balances for the account.
	update_balances()
	


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
			"get_erc20_info"
			)


# Process the callback result in your callback function.
func get_gas_balance(callback):
	var _network = callback["network"]
	var account = callback["account"]
	if callback["success"]:
		# The gas balance returns as a single, decoded String.
		var balance = callback["result"]
		for network in $Balances/Networks.get_children():
			if network.name == _network:
				# Remove excess trailing decimals with .left()
				network.get_node("Gas").text = "Gas: " + balance.left(6)


func get_erc20_info(callback):
	var _network = callback["network"]
	var callback_args = callback["callback_args"]
	var address = callback_args["address"]
	if callback["success"]:
		# The ERC20 info returns as an array of values.
		var erc20_name = callback["result"][0]
		var decimals = callback["result"][1]
		var balance = callback["result"][2]
		for network in $Balances/Networks.get_children():
			if network.name == _network:
				network.get_node("Token").text = "BnM: " + balance.left(6)




#####      ONRAMP MONITORING      #####

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
			var to_network = ""
			
			# The list of onramp contracts is duplicated to avoid changes from
			# propagating to the ccip_network_info dictionary.
			var onramp_list = ccip_network_info[network]["onramp_contracts_by_network"].duplicate()
			
			for _onramp in onramp_list:
				var onramp = _onramp.duplicate()
				# Some RPC nodes return contract addresses with lowercase letters,
				# while some do not.
				if onramp["contract"] != onramp_contract:
					onramp["contract"] = onramp["contract"].to_lower()
				if onramp["contract"] == onramp_contract:
					to_network = onramp["network"]
				
			# The message data will be an EVM2EVM message in the form of
			# ABI encoded bytes.
			var message = event["data"]
			
			# You can ABI encode and decode values manually by using
			# the Calldata singleton.  You must provide the input
			# or output types along with the values to encode/decode.
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
			
			# The ABI Decoder will return an array containing the tuple, which
			# can be accessed at index 0.  Once accessed, the 13 elements of the 
			# EVM2EVM message can be accessed by their index.
			var decoded_message = Calldata.abi_decode([EVM2EVMMessage], message)[0]
			
			# Check that this message hasn't already been recorded.
			var messageId = decoded_message[12]
			
			if messageId in logged_messages:
				return
			else:
				logged_messages.push_back(messageId)
			
			# Prepare the log dictionary.
			var sender = decoded_message[1]
			var receiver = decoded_message[2]
			
			var _callback_args = {
				"from_network": network,
				"to_network": to_network,
				"sender": sender,
				"receiver": receiver,
				"messageId": messageId,
				"contains_tokens": false
			}
			
			# Some CCIP messages do not transmit tokens.
			var tokenAmounts = decoded_message[10]
			if !tokenAmounts.is_empty():
				_callback_args["contains_tokens"] = true
				# Right now, only checks for a single token.
				var token_contract = tokenAmounts[0][0]
				_callback_args["amount"] = tokenAmounts[0][1]
				
				# Get the sent token's info.
				Ethers.get_erc20_info(
					network, 
					sender, 
					token_contract, 
					self, 
					"print_ccip_message",
					_callback_args
					)
			else:
				print_ccip_message(
					{"callback_args": _callback_args}
					)


func print_ccip_message(callback):
	var callback_args = callback["callback_args"]
	var from_network = callback_args["from_network"]
	var to_network = callback_args["to_network"]
	var sender = callback_args["sender"]
	var receiver = callback_args["receiver"]
	var messageId = callback_args["messageId"]
	var token_name = ""
	var amount = ""
	
	if callback_args["contains_tokens"]:
		token_name = callback_args["name"]
		var decimals = callback_args["decimals"]
		amount = Ethers.convert_to_smallnum(callback_args["amount"], decimals)
	
	var message_string = (
		from_network + " to " + to_network + 
		":\n" + sender + "\nsent " + amount +
		" " + token_name + "\nto " + receiver + "\nMessage ID: " + messageId + "\n\n"
		)
 	
	new_messages += 1
	$Log.text = "CCIP Message Log (" + str(new_messages) + ")"
	$Log/Log.text += message_string




#####      BRIDGING      #####

# Automatically approves the router's spend allowance,
# gets the CCIP fee, and sends the CCIP message.
func initiate_bridge():
	# Starts by checking whether the given networks and 
	# gas/token balances are valid.
	var selected_sender_network = $Bridge/Sender.text
	var selected_destination_network = $Bridge/Destination.text
	
	if !selected_sender_network in ccip_network_info.keys():
		print_bridge_error("Invalid Sender")
		return
	if !selected_destination_network in ccip_network_info.keys():
		print_bridge_error("Invalid Destination")
		return
	if selected_sender_network == selected_destination_network:
		print_bridge_error("Same Network")
		return
	
	var sender = $Balances/Networks.get_node(selected_sender_network)
	var gas_balance = float(sender.get_node("Gas").text.right(5))
	var token_balance = float(sender.get_node("Token").text.right(5))
	
	if gas_balance < 0.001:
		print_bridge_error("Insufficient Gas")
		return
	if token_balance < 0.01:
		print_bridge_error("Insufficient Tokens")
		return
	
	var token_contract = ccip_network_info[selected_sender_network]["token_contract"]
	# Convert decimals to BigNumbers before sending.
	var amount = Ethers.convert_to_bignum("0.01")
	
	bridge(
		active_account,
		selected_sender_network,
		selected_destination_network,
		token_contract,
		amount)
	
	print_bridge_error("Sending...")
	

func bridge(account, from_network, to_network, token, amount):
	
	var address = Ethers.get_address(account)
	
	# When encoding, structs are declared as arrays 
	# containing their expected types.
	var EVMTokenAmount = [
		token,
		amount
	]
	
	var EVMExtraArgsV1 = [
		"90000" # Destination gas limit
	]
	
	# EVM2Any messages expect some of their parameters to 
	# be ABI encoded and sent as bytes.
	var extra_args = "97a657c9" + Calldata.abi_encode( [{"type": "tuple", "components":[{"type": "uint256"}]}], [EVMExtraArgsV1] )
	
	var EVM2AnyMessage = [
		Calldata.abi_encode( [{"type": "address"}], [address] ), # ABI-encoded recipient address
		Calldata.abi_encode( [{"type": "string"}], ["eeee"] ), # Data payload, as bytes
		[EVMTokenAmount], # EVMTokenAmounts
		"0x0000000000000000000000000000000000000000", # Fee address (address(0) = native token)
		extra_args # Extra args
	]
	
	var chain_selector = ccip_network_info[to_network]["chain_selector"]
	
	# Since the token spend allowance must be approved 
	# and the CCIP fee must be estimated before the transaction 
	# can be sent, the transaction parameters will be stored in the 
	# callback_args for later use.
	
	var callback_args = {
		"EVM2AnyMessage": EVM2AnyMessage,
		"chain_selector": chain_selector,
		# The transaction type is specified here to allow get_receipt()
		# to initiate the next step: estimating the bridge fee.
		"transaction_type": "Approval"
		}
		
	callback_args["account"] = account
	callback_args["network"] = from_network
	
	var router = ccip_network_info[from_network]["router"]
	callback_args["contract"] = router
	
	# A built-in for granting spend allowances to a contract.
	Ethers.approve_erc20_allowance(account, from_network, token, router, "MAX", self, "get_receipt", callback_args)


# Successful callback to get_receipt() will bounce the transaction
# to the next step: get_native_fee(), which estimates how much
# ether to send along with the transaction.


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
		
		Ethers.read_from_contract(network, contract, calldata, self, "send_bridge_transaction", callback_args)


func send_bridge_transaction(callback):
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
		
		# Bump up the fee to decrease chances of a revert.
		# Excess value sent will be refunded by the CCIP router
		fee = float(Ethers.convert_to_smallnum(fee))
		fee *= 1.25
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



#####      TRANSACTION MANAGEMENT      #####

# Monitors Ethers.recent_transactions, a dictionary that maps the
# most recently sent transactions to the network on which they were sent.
func look_for_hashes():
	for network in networks:
		# Ethers tracks the most recent transaction for each network,
		# along with each transaction's callback_args.
		if network in Ethers.recent_transactions.keys():
			# Compare the transaction hashes to check for a new transaction.
			if Ethers.recent_transactions[network]["transaction_hash"] != recent_transactions[network]["transaction_hash"]:
				recent_transactions[network] = Ethers.recent_transactions[network]
				add_new_transaction(network, recent_transactions[network])


# Constructs new transaction objects and puts them in the transaction log,
# where their status can be updated later.
func add_new_transaction(network, transaction):
	var transaction_type = transaction["callback_args"]["transaction_type"]
	var transaction_hash = transaction["transaction_hash"]

	# Build a transaction node for the UI
	var transaction_object = instantiate_transaction(network, transaction_type, transaction_hash)
	
	# The new transaction node is mapped to the transaction hash, so
	# its status can later be updated by the transaction receipt.
	transaction_history[transaction_hash] = transaction_object
	
	$Transactions/Transactions.add_child(transaction_object)
	transaction_object.position.y += downshift
	$Transactions/Transactions.custom_minimum_size.y += 128
	downshift += 108
	transaction_object.modulate.a = 0
	var fadein = create_tween()
	fadein.tween_property(transaction_object,"modulate:a", 1, 2).set_trans(Tween.TRANS_LINEAR)
	fadein.play()


# The transaction receipt returns as a single value, a dictionary.
func get_receipt(callback):	
	if callback["success"]:
		
		# Update gas and token balances.
		update_balances()
		
		var transaction_hash = callback["result"]["transactionHash"]
		var status = callback["result"]["status"]
		var tx_object = transaction_history[transaction_hash]
	
		# Update a transaction object's status, and trigger
		# any transaction-dependent effects
		if status == "0x1":
			tx_object.get_node("Status").color = Color.GREEN
			if tx_object.get_node("Info").text.contains("CCIP"):
				beam_message()
			elif tx_object.get_node("Info").text.contains("Approval"):
				# After approval, proceeds into the next part of 
				# the bridging process: fee estimation
				get_native_fee(callback)
		else:
			tx_object.get_node("Status").color = Color.RED



#####      INTERFACE      #####


# Connects buttons and populates arrays/dictionaries
func _ready():
	$Back.connect("pressed", back)
	$Login/Login.connect("pressed", create_account)
	$Address/Copy.connect("pressed", copy_address)
	$Log.connect("pressed", slide_log)
	$Bridge.connect("pressed", slide_bridge)
	$Bridge/Initiate.connect("pressed", initiate_bridge)
	for network in $Balances/Networks.get_children():
		network.get_node("Button").connect("pressed", mint_test_tokens.bind(network.name))
	
	networks = Ethers.network_info.keys()
	for network in networks:
		
		recent_transactions[network] = {
			"transaction_hash": ""
		}
		
		previous_blocks[network] = "latest"
	
	var fadein = create_tween()
	fadein.tween_property($Fadein,"modulate:a", 0, 1).set_trans(Tween.TRANS_LINEAR)
	fadein.play()



func copy_address():
	var user_address = Ethers.get_address(active_account)
	DisplayServer.clipboard_set(user_address)
	$Address/Prompt.modulate.a = 1
	var fadeout = create_tween()
	fadeout.tween_property($Address/Prompt,"modulate:a", 0, 2.8).set_trans(Tween.TRANS_LINEAR)
	fadeout.play()


# Opens the passed url in the system's default browser
func open_link(url):
	OS.shell_open(url)


# Mints CCIP-BnM to use for bridging
func mint_test_tokens(network):
	var token_contract = ccip_network_info[network]["token_contract"]
	var address = Ethers.get_address(active_account)
	
	# An example of how to manually construct calldata, even without an ABI.
	# Get the function selector using the function name and inputs,
	# and concatenate the selector with the ABI encoded function arguments.
	var function_selector = {
		"name": "drip",
		"inputs": [{"type": "address"}]
	}
	
	var calldata = {
		"calldata": Calldata.get_function_selector(function_selector) + Calldata.abi_encode( [{"type": "address"}], [address] )
		}
		
	Ethers.send_transaction(active_account, network, token_contract, calldata, self, "get_receipt", {"transaction_type": "Mint"})



# Builds the transaction object node.

# It's much easier to simply build external scenes and instantiate
# them on demand.  Here however the transaction object is constructed in code,
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


func slide_log():
	$Log.text = "CCIP Message Log"
	new_messages = 0
	if $Log.position.y == log_down_y:
		slide($Log, log_up_y)
	elif $Log.position.y == log_up_y:
		slide($Log, log_down_y)


func slide_bridge():
	if $Bridge.position.y == bridge_down_y:
		slide($Bridge, bridge_up_y)
	elif $Bridge.position.y == bridge_up_y:
		slide($Bridge, bridge_down_y)


func print_bridge_error(error):
	if error != "Sending...":
		$Bridge/Error.text = "Error: " + error
	else:
		$Bridge/Error.text = error
	$Bridge/Error.modulate.a = 1
	var fadeout = create_tween()
	fadeout.tween_property($Bridge/Error,"modulate:a", 0, 2.8).set_trans(Tween.TRANS_LINEAR)
	fadeout.play()
	
	
func slide(node, pos):
	var slide_tween = create_tween()
	slide_tween.tween_property(node, "position:y", pos, 0.3).set_trans(Tween.TRANS_QUAD)
	slide_tween.play()


func fade_in(node):
	var fadein = create_tween()
	fadein.tween_property(node,"modulate:a", 1, 1).set_trans(Tween.TRANS_LINEAR)
	fadein.play()


func back():
	# Logging out will clear your encrypted password from memory,
	# and clear the transaction log.
	Ethers.logout()
	queue_free()



#####      BEAM VFX      #####

func beam_message():
	$Beam.visible = true
	var top_tween = create_tween()
	var bottom_tween = create_tween()
	top_tween.tween_property($Beam.mesh, "top_radius", 0.4, 0.1)
	bottom_tween.tween_property($Beam.mesh, "bottom_radius", 0.4, 0.1)
	bottom_tween.tween_callback(reduce_beam)
	top_tween.play()
	bottom_tween.play()


func reduce_beam():
	var top_tween = create_tween()
	var bottom_tween = create_tween()
	top_tween.tween_property($Beam.mesh, "top_radius", 0.001, 10)
	bottom_tween.tween_property($Beam.mesh, "bottom_radius", 0.001, 10)
	bottom_tween.tween_callback(invisible_beam)
	top_tween.play()
	bottom_tween.play()


func invisible_beam():
	$Beam.visible = false



#####      ABI      #####

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
