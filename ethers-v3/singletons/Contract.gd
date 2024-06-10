extends Node



var CalldataTester = [
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


var ERC20 = [
	{
		"inputs": [
			{
				"internalType": "uint256",
				"name": "initialSupply",
				"type": "uint256"
			}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "allowance",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "needed",
				"type": "uint256"
			}
		],
		"name": "ERC20InsufficientAllowance",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "balance",
				"type": "uint256"
			},
			{
				"internalType": "uint256",
				"name": "needed",
				"type": "uint256"
			}
		],
		"name": "ERC20InsufficientBalance",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "approver",
				"type": "address"
			}
		],
		"name": "ERC20InvalidApprover",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "receiver",
				"type": "address"
			}
		],
		"name": "ERC20InvalidReceiver",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "sender",
				"type": "address"
			}
		],
		"name": "ERC20InvalidSender",
		"type": "error"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			}
		],
		"name": "ERC20InvalidSpender",
		"type": "error"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "Approval",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"indexed": true,
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"indexed": false,
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "Transfer",
		"type": "event"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "owner",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "spender",
				"type": "address"
			}
		],
		"name": "allowance",
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
				"internalType": "address",
				"name": "spender",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "approve",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "account",
				"type": "address"
			}
		],
		"name": "balanceOf",
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
		"name": "decimals",
		"outputs": [
			{
				"internalType": "uint8",
				"name": "",
				"type": "uint8"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "name",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "symbol",
		"outputs": [
			{
				"internalType": "string",
				"name": "",
				"type": "string"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalSupply",
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
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "transfer",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{
				"internalType": "address",
				"name": "from",
				"type": "address"
			},
			{
				"internalType": "address",
				"name": "to",
				"type": "address"
			},
			{
				"internalType": "uint256",
				"name": "value",
				"type": "uint256"
			}
		],
		"name": "transferFrom",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]
