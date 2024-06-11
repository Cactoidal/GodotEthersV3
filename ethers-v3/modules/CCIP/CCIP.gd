extends Node


# A CCIP interface.

# Add Chronomancer bridge

# Router and BnM token contracts need to be added

func _ready():
	var address = Ethers.get_address("test_keystore2")
	
	# Calls drip faucet for BnM tokens
	# Needs to be on a button
	#get_test_tokens(address, "Base Sepolia")
	
	var amount = Ethers.convert_to_bignum("0.01")
	
	# Automatically approves the router's spend allowance,
	# gets the native gas fee, and sends the CCIP message.
	# Needs to be on a button
	bridge("test_keystore2", "Base Sepolia", "Arbitrum Sepolia", "0x88A2d74F47a237a62e7A51cdDa67270CE381555e", amount)


func bridge(account, from_network, to_network, token, amount):
	
	var address = Ethers.get_address(account)
	
	var EVMTokenAmount = [
		token,
		amount
	]
	
	var EVMExtraArgsV2 = [
		"900000", # Destination gas limit
		true # Allow out of order execution
	]
	
	# This will send, but something is broken
	# What is this object actually supposed to look like?
	# On-chain, it uses abi.encodeWithSelector 
	var extra_args = "0x181dcf10" + Calldata.abi_encode( [{"type": "tuple", "components":[{"type": "uint256"}, {"type": "bool"}]}], [EVMExtraArgsV2] )
	
	var EVM2AnyMessage = [
		Calldata.abi_encode( [{"type": "address"}], [address] ), # ABI-encoded recipient address
		Calldata.abi_encode( [{"type": "string"}], [""] ), # Data payload, as bytes
		[EVMTokenAmount], # EVMTokenAmounts
		"0x0000000000000000000000000000000000000000", # Fee address (address(0) = native token)
		extra_args # Extra args
	]
	
	var chain_selector = ccip_network_info[to_network]["chain_selector"]
	
	var callback_args = {
		"EVM2AnyMessage": EVM2AnyMessage,
		"chain_selector": chain_selector}
	callback_args["account"] = account
	callback_args["network"] = from_network
	
	var router = ccip_network_info[from_network]["router"]
	callback_args["contract"] = router
	
	Ethers.approve_erc20_allowance(account, from_network, token, router, self, "get_native_fee", callback_args)


func get_native_fee(callback):
	if callback["success"]:
		var callback_args = callback["callback_args"]
		var EVM2AnyMessage = callback_args["EVM2AnyMessage"]
		var chain_selector = callback_args["chain_selector"]
		var network = callback_args["network"]
		var contract = callback_args["contract"]
		var calldata = Ethers.get_calldata("READ", CCIP_ROUTER, "getFee", [chain_selector, EVM2AnyMessage])
		Ethers.read_from_contract(network, contract, calldata, self, "ccip_bridge", callback_args)


func ccip_bridge(callback):

	if callback["success"]:
	
		var callback_args = callback["callback_args"]
		var EVM2AnyMessage = callback_args["EVM2AnyMessage"]
		var chain_selector = callback_args["chain_selector"]
		var account = callback_args["account"]
		var network = callback_args["network"]
		var contract = callback_args["contract"]
		var fee = callback["result"][0]
		
		var calldata = Ethers.get_calldata("WRITE", CCIP_ROUTER, "ccipSend", [chain_selector, EVM2AnyMessage])
		
		Ethers.send_transaction(account, network, contract, calldata, self, "get_receipt", {}, "900000", fee)


func get_receipt(callback):
	print(callback)


func get_test_tokens(address, network):
	var contract
	match network:
		"Base Sepolia": contract = "0x88A2d74F47a237a62e7A51cdDa67270CE381555e"
	
	# An example of how to manually construct calldata, even without an ABI.
	
	var function_selector = {
		"name": "drip",
		"inputs": [{"type": "address"}]
	}
	
	var calldata = {
		"calldata": Calldata.get_function_selector(function_selector) + Calldata.abi_encode( [{"type": "address"}], [address] )
		}
		
	Ethers.send_transaction("test_keystore2", network, contract, calldata, self, "get_receipt")





var ccip_network_info = {
	
	"Ethereum Sepolia": 
		{
		"chain_id": "11155111",
		"rpc": "https://ethereum-sepolia-rpc.publicnode.com",
		"gas_balance": "0", 
		"onramp_contracts": ["0xe4Dd3B16E09c016402585a8aDFdB4A18f772a07e", "0x69CaB5A0a08a12BaFD8f5B195989D709E396Ed4d", "0x2B70a05320cB069e0fB55084D402343F832556E7"],
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
				}
			
		],
		"endpoint_contract": "0xFFA6c081b6A7F5F3816D9052C875E4C6B662137a",
		"monitored_tokens": [], 
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"latest_block": "latest",
		"order_processor": null,
		"scan_url": "https://sepolia.etherscan.io/",
		"logo": "res://assets/Ethereum.png"
		},
		
	"Arbitrum Sepolia": 
		{
		"chain_id": "421614",
		"chain_selector": "3478487238524512106",
		"rpc": "https://sepolia-rollup.arbitrum.io/rpc",
		"gas_balance": "0", 
		"onramp_contracts": ["0x4205E1Ca0202A248A5D42F5975A8FE56F3E302e9", "0x701Fe16916dd21EFE2f535CA59611D818B017877", "0x7854E73C73e7F9bb5b0D5B4861E997f4C6E8dcC6"],
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
				}
			
		],
		"endpoint_contract": "0xcA57f7b1FDfD3cbD513954938498Fe6a9bc8FF63",
		"monitored_tokens": [],
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"latest_block": "latest",
		"order_processor": null,
		"scan_url": "https://sepolia.arbiscan.io/",
		"logo": "res://assets/Arbitrum.png"
		},
		
	"Optimism Sepolia": {
		"chain_id": "11155420",
		"rpc": "https://sepolia.optimism.io",
		"gas_balance": "0", 
		"onramp_contracts": ["0xC8b93b46BF682c39B3F65Aa1c135bC8A95A5E43a", "0x1a86b29364D1B3fA3386329A361aA98A104b2742", "0xe284D2315a28c4d62C419e8474dC457b219DB969"],
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
				}
			
		],
		"endpoint_contract": "0x04Ba932c452ffc62CFDAf9f723e6cEeb1C22474b",
		"monitored_tokens": [],
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"latest_block": "latest",
		"order_processor": null,
		"scan_url": "https://sepolia-optimism.etherscan.io/",
		"logo": "res://assets/Optimism.png"
	},
	
	"Base Sepolia": {
		"chain_id": "84532",
		"rpc": "https://sepolia.base.org",
		"gas_balance": "0",
		"router": "0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93",
		"onramp_contracts": ["0x6486906bB2d85A6c0cCEf2A2831C11A2059ebfea", "0x58622a80c6DdDc072F2b527a99BE1D0934eb2b50", "0x3b39Cd9599137f892Ad57A4f54158198D445D147"],
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
				}
			
		],
		"endpoint_contract": "0xD7e4A13c7896edA172e568eB6E35Da68d3572127",
		"monitored_tokens": [],
		"minimum_gas_threshold": 0.0002,
		"maximum_gas_fee": "",
		"latest_block": "latest",
		"order_processor": null,
		"scan_url": "https://sepolia.basescan.org/",
		"logo": "res://assets/Base.png"
	}
}



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
