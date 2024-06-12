extends Node3D

# An Ethereum Sepolia visualizer that receives block hashes and 
# their transaction counts.

var rpc_filter_ids = []
var received_hashes = {}
var block_timer = 0.1
var blocks = []


func _ready():
	
	$Back.connect("pressed", back)
	
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
	
	if $Fadein.modulate.a > 0:
		$Fadein.modulate.a -= delta
		if $Fadein.modulate.a < 0:
			$Fadein.modulate.a = 0
	
	prune_block_hashes(delta)
	move_blocks(delta)
	
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
func prune_block_hashes(delta):
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
# transactions.
func generate_block(hash, tx_count):
	$Blockhash.text = hash
	$Blockhash.modulate.a = 0
	var new_block = Node3D.new()
	$Blockspace.add_child(new_block)
	blocks.push_back(new_block)
	for tx in range(tx_count):
		var new_tx = MeshInstance3D.new()
		new_tx.set_mesh(BoxMesh.new())
		new_tx.mesh.size = Vector3(1,1,1)
		new_block.add_child(new_tx)
		new_tx.transform.origin = Vector3(
			randi_range(0,7),
			randi_range(0,7),
			randi_range(0,7)
		)


# Blocks are eventually pruned once they move out
# of the camera's line of sight.
func move_blocks(delta):
	
	if $Blockhash.modulate.a < 1:
		$Blockhash.modulate.a += delta
		if $Blockhash.modulate.a > 1:
			$Blockhash.modulate.a = 1
	
	var deletion_queue = []
	for block in blocks:
		block.global_transform.origin.y += 2*delta
		
		if block.global_transform.origin.y > 200:
			deletion_queue.push_back(block)
	
	for block in deletion_queue:
		blocks.erase(block)
		block.queue_free()

func back():
	queue_free()
