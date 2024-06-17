![GodotEthers](https://github.com/Cactoidal/GodotEthersV3/blob/main/GodotEthers.png?raw=true)
# GodotEthers
Ethers for Godot 4.3, built with Godot Rust and Ethers-rs.  Featuring [implementation](https://github.com/Cactoidal/GodotEthersV3/blob/main/ethers-v3/singletons/Calldata.gd) of the Ethereum ABI encoding/decoding [specification](https://docs.soliditylang.org/en/latest/abi-spec.html).

[About](https://github.com/Cactoidal/GodotEthersV3/blob/main/README.md#about) | Docs  - coming soon!

___

### A Note on Security

This is experimental, alpha software, in a state of ongoing development, intended for usage on testnets.  

When exporting a project, __*do not*__ "Export With Debug".  If you decide to recompile the Rust library, use the --release tag when building.

___

Using GodotEthers is pretty straightforward.  To interact with a contract, you just need to slap an ABI somewhere in your project, use `get_calldata()` for the function you want, then call `read_from_contract()` or `send_transaction()`.  That's it!  Encoding calldata and decoding the RPC response is all taken care of for you.

You can also use `perform_request()` to call any Ethereum method.  For example, you could use this to monitor a contract's activity with `eth_getLogs`.

Every function mentioned on this page is defined in the `Ethers.gd` singleton, and can be accessed by calling the singleton, e.g. `Ethers.get_calldata()`.

---

## Usage Example

```

# Read from a contract

func get_hello(network, contract, ABI):
	
	var calldata = Ethers.get_calldata("READ", ABI, "helloWorld", [])
		
	Ethers.read_from_contract(
		network, 
		contract, 
		calldata, 
		self, 
		"hello_world",
		{}
		)



# Receive the callback from the contract read

func hello_world(callback):
	if callback["success"]:
		print(callback["result"])



# Create an encrypted keystore with an account name and password

func create_account(account, password):
	if !Ethers.account_exists(account):
		Ethers.create_account(account, password)
		password = Ethers.clear_memory()
		password.clear()



# An account must be logged in to send transactions

func login(account, password):
	Ethers.login(account, password)
	password = Ethers.clear_memory()
	password.clear()



# Send a transaction

func say_hello(account, network, contract, ABI):
	
	var calldata = Ethers.get_calldata("WRITE", ABI, "sayHello", ["hello"])

	Ethers.send_transaction(
			account, 
			network, 
			contract, 
			calldata, 
			self, 
			"get_receipt", 
			{}
			)



# Receive the callback from a successful transaction

func get_receipt(callback):
	if callback["success"]:
		print(callback["result"])

```

___

### `get_calldata(read_or_write, ABI, function_name, args=[])`

`read_or_write` is a String: "READ" or "WRITE".  Use "READ" if you intend to call a view/pure function with `read_from_contract()`.

`ABI` is your contract's ABI.  It needs to be pasted somewhere into a .gd file as a variable, so you can call it.  The `Contract.gd` singleton is available for this purpose, if you'd like to use it.

`function_name` is the contract function you want to call.

`args` is an array containing your contract function's arguments.  Here are the expected types:

* __uint8/16/32/64/128/256__ as STRING

* __int8/16/32/64/128/256__ as STRING

* __address__ as STRING

* __bytes__ as hex STRING (or, optionally, as PackedByteArray).  Do not preface with "0x"

* __bool__ as STRING (or, optionally, as a bool)

* __enum__ as STRING

* __array__ as ARRAY

* __tuple__ (struct) as ARRAY containing any of these types

You will notice that everything must be passed as either a String, Array of Strings, or Array of Arrays, with only a couple (optional) exceptions.

This function returns a dictionary containing the following fields:

"calldata": the ABI-encoded calldata for the function you want to call

"outputs": the output types, which GodotEthers will use to automatically decode the RPC response.  This field will only be present if you specified "READ" in `read_or_write` above.

___

### A Note on Numbers

You can use `convert_to_smallnum()` to convert a BigNumber into a more readable form, and use `convert_to_bignum()` before passing the value as an argument in `get_calldata()`.  You must transport BigNumbers as Strings, otherwise they will overflow.

___

### `read_from_contract(network, contract, calldata, callback_node, callback_function, callback_args={})`

`network` is the name of the network you're calling, as a String.

`contract` is the contract address.

`calldata` is the calldata-containing dictionary you got from get_calldata().

`callback_node` is the Godot node (typically self) that will receive the decoded RPC result.

`callback_function` is the function that will be called on the callback node.

`callback_args` is a dictionary of optional arguments that will be available for use in the callback function.  The default value is an empty dictionary.

___

### A Note on Callback Functions

Callback functions should take a single argument: `callback`, which will be a dictionary containing the following fields:

"success": true or false

"result":  the decoded RPC response, if success is true

"callback_args": the dictionary of callback args you defined 

___

### `send_transaction(account, network, contract, calldata, callback_node, callback_function, callback_args={}, gas_limit="900000", value="0")`

`account` is the name of a user-created account.  See the note below for more information.

`network`, `contract`, `calldata`, and the `callback` parameters are all the same as they are for `read_from_contract()`.  When receiving a successful callback, note that the "result" field will be the transaction receipt.

`gas_limit` is the transaction gas limit, and by default is set for 900,000, which is quite high.  You can adjust this default as needed.

`value` is the amount of Ether to send with the transaction, typically 0.

___

### A Note on Accounts

Check if a keystore exists using `account_exists()`, then call `create_account()` to name a new keystore and encrypt it with a password.


You then must use `login()` with the name and password.  Once the account is logged in, you can use it to call functions like `get_address()` and `send_transaction()`.

___

### `perform_request(method, params, network, callback_node, callback_function, callback_args={}, specified_rpc=false, retries=3)`

`method` is the ethereum method you want to call.

`params` is an array containing the arguments passed for the method.

`network` and the `callback` parameters are the same as they are for `read_from_contract()` and `send_transaction()`.  Note that `perform_request()` is a lower level function call, and therefore will *not* automatically decode the RPC result.  You will need to process the result in your callback function.

`specified_rpc` overrides the rpc cycling mechanism, using the chosen RPC node for the request.  Useful when using something like `eth_newBlockFilter`, which will produce a filter id that needs to be mapped to a specific RPC.

`retries` is the number of times the application will try to perform the request until it receives a successful response code.  The default number of attempts is 3. Note that in addition to retries, GodotEthers is programmed to reduce RPC load and dependency by automatically cycling through all the RPC nodes listed for a given network.



___

### A Note on Built-ins

You can use `transfer()` to send ETH.  The ERC20 ABI is also present by default, in the `Contract.gd` singleton.   You can call `get_erc20_info()` to get a token's name, decimals, and balance for a supplied address, all in one call.  You can also use `approve_erc20()` to grant the maximum spend allowance to a contract, and you can use `transfer_erc20()` to send tokens.

The default networks are the following testnets: Ethereum Sepolia, Optimism Sepolia, Arbitrum Sepolia, Base Sepolia, and Avalanche Fuji.

You can edit `default_network_info` at the bottom of `Ethers.gd` to add more networks or change their configurations.  Be aware that after running the program at least once, your network defaults will be saved into a config file, and you will need to edit `check_for_network_info()` so that it will overwrite the config file with your new defaults.

___

## About

GodotEthers combines the orchestration abilities of Godot with the signing capability of Ethers-rs, made possible by Godot Rust.  

The ABI encoding and decoding algorithms are written in pure gdscript.  Rust is used for encoding and decoding the elementary types after they have been sorted.  

The Rust library is also responsible for RLP encoding, ECDSA signing, address calculation, Keccak hashing, and BigNumber handling.  These five critical functions are all "drop-in", meaning they could be replaced by any other module providing the same functionality.  

There are benefits, however, to using Ethers-rs and its successor, Alloy.  Namely that they have been well-tested, and they contain additional features that could be added into the Rust library later.  Having a Rust library also gives GodotEthers access to Rust crates containing useful cryptographic primitives, such as circom and openssl.

For example, the pbkdf2 crate is used to derive the keystore encryption/decryption key from an account password.

In addition to games, GodotEthers can be used to decentralize dApp interfaces.  Instead of connecting to a website and using a web wallet, a contract interface can now be easily built in Godot and distributed to users in open source format.  Blockchain bots can also be made more accessible, with user-friendly interfaces.
