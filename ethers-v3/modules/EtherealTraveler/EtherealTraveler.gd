extends Node3D


# An Ethereum Sepolia visualizer that receives block hashes and 
# their transaction counts.

var rpc_filter_ids = []
var received_hashes = {}
var block_timer = 0.1

# DEBUG
var ccip_module = preload("res://modules/CCIP/CCIP.tscn")

func _ready():
	# DEBUG
	# Quick read/write checker
	
	#Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore5"), "0x88A2d74F47a237a62e7A51cdDa67270CE381555e", self, "get_erc20_info")
	#Ethers.login("test_keystore5", "test_password")
	#var ccip = ccip_module.instantiate()
	#add_child(ccip)
	
	
	# We still want to cycle RPCs, but we also want to map the RPC
	# nodes to specific block filter ids.  We can do this by
	# specifying the RPC when calling perform_request(), populating
	# our own array of RPCs, and cycling through them
	# ourselves.
	
	for rpc in Ethers.network_info["Ethereum Sepolia"]["rpcs"]:
		Ethers.perform_request(
					"eth_newBlockFilter", 
					[], 
					"Ethereum Sepolia", 
					self, 
					"get_filter_id",
					{},
					rpc  # Overrides the automatic RPC cycling.
					)


func get_filter_id(callback):
	if callback["success"]:
		var rpc = callback["specified_rpc"]
		var filter_id = callback["result"]
		
		# Adds the RPC node and its filter id to an array.
		rpc_filter_ids.push_back(
			{
				"rpc": rpc,
				"filter_id": filter_id
			}
		)


func _process(delta):
	
	prune_blocks(delta)
	
	block_timer -= delta
	if block_timer < 0:
		
		# Sets the polling speed.
		block_timer = 1
		
		if !rpc_filter_ids.is_empty():
			var _rpc = rpc_filter_ids[0]
			var rpc = _rpc["rpc"]
			var filter_id = _rpc["filter_id"]
			
			# Cycles the RPC.
			rpc_filter_ids.push_back(rpc_filter_ids.pop_front())
			
			# Checks for new block hashes.
			Ethers.perform_request(
					"eth_getFilterChanges", 
					[filter_id], 
					"Ethereum Sepolia", 
					self, 
					"get_new_block_hashes",
					{},
					rpc
					)


func get_new_block_hashes(callback):
	if callback["success"]:
		var block_hashes = callback["result"]
		
		# Fast chains or slow polling speeds may result in
		# the return of multiple blocks, so we loop
		# through the result.
		for hash in block_hashes:
			if !hash in received_hashes.keys():
				
				# Block hashes are added to the "received_hashes" dictionary
				# to prevent blocks from being read multiple times.
				received_hashes[hash] = 20  # This number will be used as a pruning timer.
				
				# Gets the transaction count for the given block.
				Ethers.perform_request(
						"eth_getBlockTransactionCountByHash", 
						[hash], 
						"Ethereum Sepolia", 
						self, 
						"get_block_transaction_count",
						{"hash": hash}
						) # The automatic RPC cycling is not overriden here,
						  # because eth_getBlockTransactionCountByHash does 
						  # not require a specific filter id.


# Updates the current state using
# the new block's transaction count.
func get_block_transaction_count(callback):
	if callback["success"]:
		var hash = callback["callback_args"]["hash"]
		var tx_count = callback["result"].hex_to_int()
		print("Hash: " + hash)
		print("Tx Count: " + str(tx_count))
		
		generate_block(hash, tx_count)


# Blocks are eventually pruned from the "received_hashes" 
# dictionary to free up memory.
func prune_blocks(delta):
	if !received_hashes.keys().is_empty():
		var prunable_hashes = []
		for hash in received_hashes.keys():
			received_hashes[hash] -= delta
			if received_hashes[hash] < 0:
				
				# When sorting arrays and dictionaries to prune, first
				# push the filtered items to a "deletion array".
				prunable_hashes.push_back(hash)
		
		# Then loop through the deletion array, and erase the item
		# from the actual array/dictionary you want to modify.
		for hash in prunable_hashes:
			received_hashes.erase(hash)


# Visualizer that spawns meshes to represent 
# transactions, and colors them randomly 
# using the block hash as a seed.
func generate_block(hash, tx_count):
	pass








# DEBUG
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
