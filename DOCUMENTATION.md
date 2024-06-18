
# GodotEthers Documentation

_**GodotEthers is in active development, and functions listed here will likely change in the future.
If you have suggestions, feature requests, or bug reports, feel free to let me know.**_

```
A Note on Security:
This is experimental, alpha software, intended for usage on testnets.

When exporting a project, do not "Export With Debug". If you decide to recompile the Rust library,
use the --release tag when building.
```

### [Quickstart](#Quickstart)
- [Add GodotEthers to Your Project](#Add-GodotEthers-to-Your-Project)
- [How to Use](#how-to-use)
- [Example Usage](#Example-Usage)
- [Key Management](#Key-Management)
- [General Purpose Functions](#General-Purpose-Functions)

### [Built-ins](#built-ins-1)

### [Singletons](#singletons-1)
- (Ethers)[#ethers-1]
- [Transaction](#transaction-1)
- Calldata[#calldata-1]
- GodotSigner

_________

# Quickstart

## Add GodotEthers to Your Project

* Download the GodotEthers plugin ([cactus.godotethers](https://github.com/Cactoidal/GodotEthersV3/tree/main/addons/cactus.godotethers)) and add it to your project's `addons` folder.

* Inside `cactus.godotethers`, open the `gdextension` folder and give the dynamic library permission to open.  On MacOS, you can do this by right-clicking the `libgodot_ethers.dylib` file and opening it.  X11 uses `.so`, and Windows uses `.dll`.

* Inside the editor, open Project Settings, click Plugins, and activate GodotEthers.

* Restart the editor.

_________

## How to Use

To interact with a contract, you just need to put an ABI somewhere in your project, use `get_calldata()` for the function you want, then call `read_from_contract()` or `send_transaction()`. That's it! Encoding calldata and decoding the RPC response is all taken care of for you.

You can also use `perform_request()` to call any Ethereum method. For example, you could use this to monitor a contract's activity with `eth_getLogs`.

The `Ethers.gd` singleton is the primary interface of GodotEthers.  The other singletons contain lower level functions.  To read more about them and how to use them, check out the [Singletons](#singletons-1) section.

_________

## Example Usage


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

_________

## Key Management

Accounts are created by deriving an encryption key from a password and salt using the PBKDF2 algorithm.

This key will encrypt a sequence of 32 random bytes generated using the MBed-TLS library and system entropy.  The encrypted keystore is saved to disk.

To "log in", the account password must be provided to Ethers, which will encrypt the password with a session encryption key and keep the encrypted password in memory.

The password is decrypted, and subsequently used to decrypt the keystore, whenever the application needs to sign a transaction.  

The encrypted password and session keys are wiped from memory when the application is closed, or when `Ethers.logout()` is called.

_____
* #### `Ethers.create_account(account, password)`
_____

`account` is the name of a new account, as a String.  This function will automatically revert if the account already exists.  You can use `Ethers.account_exists(account)` to check beforehand whether the name is already in use.


`password` is the account password, as a String.  It will be combined with a randomly generated salt and iv to encrypt a new private key.

_____

* #### `Ethers.login(account, password)`
_____

Like above, `account` and `password` are strings.  The password will be checked for validity, encrypted with a session key, and kept encrypted in memory for use during the session.

An account must be logged in before it can send transactions.

_____

* #### `Ethers.clear_memory()`
_____

To the furthest extent possible, it's important to clean up sensitive information like unencrypted passwords and private keys out of memory.  

After using a sensitive value in a variable, set the variable equal to `Ethers.clear_memory()` to overwrite its value with 256 random bytes.

For further sanitization, you can call `clear()` on the variable afterward to zero out the byte array.

_____

## General Purpose Functions

The majority of applications will use the functions in this section to fill the needs of their dApp.

These general purpose functions can quickly and easily build calldata for transactions, read from contracts, send transactions, or call an RPC with an eth_method.

_____

* #### `Ethers.get_calldata(read_or_write, ABI, function_name, args=[])`
_____

```
Ethers.get_calldata(
              read_or_write, 
              ABI, 
              function_name, 
              args=[]
              )
```

`read_or_write` is a String: "READ" or "WRITE". Use "READ" if you intend to call a view/pure function with `Ethers.read_from_contract()`.

`ABI` is your contract's ABI. It needs to be pasted somewhere into a .gd file as a variable, so you can call it. The `Contract.gd` singleton is available for this purpose, if you'd like to use it.

`function_name` is the contract function you want to call, as a String.

`args` is an array containing your contract function's arguments. Here are the expected types:

* **uint8/16/32/64/128/256** as STRING

* **int8/16/32/64/128/256** as STRING

* **address** as STRING

* **bytes** as hex STRING (or, optionally, as PackedByteArray). Do not preface with "0x"

* **bool** as STRING (or, optionally, as a bool)

* **enum** as STRING

* **array** as ARRAY

* **tuple** (struct) as ARRAY containing any of these types

You will notice that everything must be passed as either a String, Array of Strings, or Array of Arrays, with only a couple (optional) exceptions.

This function returns a dictionary containing the following fields:

"calldata": the ABI-encoded calldata for the function you want to call

"outputs": the output types, which GodotEthers will use to automatically decode the RPC response. This field will only be present if you specified "READ" in `read_or_write` above.

_____

```
A Note on Numbers

You can use Ethers.convert_to_smallnum() to convert a BigNumber into a more readable form, and use 
Ethers.convert_to_bignum() before passing the value as an argument in get_calldata(). 
You must transport BigNumbers as Strings, otherwise they will overflow.
```
_____

* #### `Ethers.read_from_contract(network, contract, calldata, callback_node, callback_function, callback_args={})`
_____

```
Ethers.read_from_contract(
              network, 
              contract, 
              calldata, 
              callback_node,
              callback_function,
              callback_args={}
              )
```

`network` is the name of the network you're calling, as a String.

`contract` is the contract address, as a String.

`calldata` is the calldata-containing dictionary you got from `Ethers.get_calldata()`.

`callback_node` is the Godot node (typically self) that will receive the decoded RPC result.

`callback_function` is the function that will be called on the callback node, as a String.

`callback_args` is a dictionary of optional arguments that will be available for use in the callback function. The default value is an empty dictionary.

This function returns an array of decoded values in the `callback["result"]`.

_____

```
A Note on Callback Functions

Callback functions should take a single argument:
callback, which will be a dictionary containing the following fields:

"success": true or false

"result": the decoded RPC response, if success is true

"callback_args": the dictionary of callback args you defined
```
_____

* #### `Ethers.send_transaction(account, network, contract, calldata, callback_node, callback_function, callback_args={}, gas_limit="900000", value="0")`
_____

```
Ethers.send_transaction(
              account,
              network, 
              contract, 
              calldata, 
              callback_node,
              callback_function,
              callback_args={},
              gas_limit="900000",
              value="0"
              )
```

`account` is the name of a user-created account, as a String.

`network`, `contract`, `calldata`, and the `callback` parameters are all the same as they are for `Ethers.read_from_contract()`. 
When receiving a successful callback, note that the `callback["result"]` field will be the transaction receipt.

`gas_limit` is the transaction gas limit, as a String, and by default is set to 900,000, which is quite high. You can adjust this default as needed.

`value` is the amount of Ether to send with the transaction, typically 0, as a String.

_____

* #### `Ethers.perform_request(method, params, network, callback_node, callback_function, callback_args={}, specified_rpc=false, retries=3)`
_____

```
Ethers.perform_request(
              method,
              params, 
              network, 
              callback_node, 
              callback_function,
              callback_args={},
              specified_rpc=false,
              retries=3
              )
```

`method` is the ethereum method you want to call, as a String.

`params` is an array containing the arguments passed for the method.

`network` and the `callback` parameters are the same as they are for `Ethers.read_from_contract()` and `send_transaction()`. Note that `perform_request()` is a lower level function call, and therefore will not automatically decode the RPC result. You will need to process the result in your callback function.

`specified_rpc` overrides the rpc cycling mechanism, using the chosen RPC node for the request. Useful when using something like `eth_newBlockFilter`, which will produce a filter id that needs to be mapped to a specific RPC.

`retries` is the number of times the application will try to perform the request until it receives a successful response code. The default number of attempts is 3. Note that in addition to retries, GodotEthers is programmed to reduce RPC load and dependency by automatically cycling through all the RPC nodes listed for a given network.

This function will return the raw RPC response in the `callback["result"]`.

_____

* #### `Ethers.convert_to_bignum(number, token_decimals=18)`
_____

Takes a decimal value and returns it in BigNumber String format.

`number` is the decimal value, provided as a String.

`token_decimals` can be provided as String or an integer.  Native gas tokens typically use 18 decimals by default, as do many ERC20s.  
Some ERC20s do not use 18 decimals, however - which is why it's important to check unknown tokens with `Ethers.get_erc20_info()`.

_____

* #### `Ethers.convert_to_smallnum(bignum, token_decimals=18)`
_____

Takes a BigNumber String and returns it as a decimal value String.

_____

* #### `Ethers.get_address(account)`
_____

Returns the address of an existing account, as a String.

_____

# Built-ins

The Ethers singleton implements several common operations, such as transferring ETH, retrieving the user gas balance, and working with ERC20 tokens.
_____

* #### `Ethers.transfer(account, network, recipient, amount, callback_node, callback_function, callback_args={})`
_____

```
Ethers.transfer(
              account, 
              network, 
              recipient, 
              amount,
              callback_node,
              callback_function,
              callback_args={}
              )
```

`recipient` is the receiving address, as a String.

`amount` is the amount of ETH to transfer, expected as a BigNumber (Uint256) String with 18 decimals.

_____

* #### `Ethers.get_gas_balance(network, account, callback_node, callback_function, callback_args={})`
_____

```
Ethers.get_gas_balance(
              network, 
              account, 
              callback_node,
              callback_function,
              callback_args={}
              )
```
Returns the decoded gas balance as a string.

_____

* #### `Ethers.get_erc20_info(network, address, contract, callback_node, callback_function, callback_args={})`
_____

```
Ethers.get_erc20_info(
              network, 
              address,
              contract,
              callback_node,
              callback_function,
              callback_args={}
              )
```
 Queries the supplied `contract`, bouncing through three calls: ERC20.name(), ERC20.decimals(), and ERC20.balanceOf() for a supplied `address`, and returns all 3 decoded values.

_____

* #### `Ethers.transfer_erc20(account, network, token_address, recipient, amount, callback_node, callback_function, callback_args={})`
_____

```
Ethers.transfer_erc20(
              account, 
              network,
              token_address, 
              recipient, 
              amount,
              callback_node,
              callback_function,
              callback_args={}
              )
```
`token_address` is the address of the token contract, as a String.

`recipient` is the receiving address, as a String.

`amount` is the amount of tokens to transfer, expected as a BigNumber (Uint256) String with the token's appropriate number of decimals.

_____

* #### `Ethers.approve_erc20_allowance(account, network, token_address, spender_address, amount, callback_node, callback_function, callback_args={})`
_____

```
Ethers.approve_erc20_allowance(
              account, 
              network,
              token_address,
              spender_address,
              amount,
              callback_node,
              callback_function,
              callback_args={}
              )
```

`spender_address` is the address of the contract being given a spend allowance, as a String.

`amount` is the amount of tokens to approve, expected as a BigNumber (Uint256) String with the token's appropriate number of decimals.  
If you specify "MAX" or "MAXIMUM", the maximum spend allowance will be granted to the spender address.

_____

# Singletons

GodotEthers is built with five singletons:

- **Ethers**, the primary interface
- **Contract**, a simple repository for contract ABIs.  Contains no functions, and can serve as a convenient access point for any contract ABIs you want to include in your project.
- **Transaction**, the transaction manager
- **Calldata**, the ABI encoder/decoder
- **GodotSigner**, the Rust library

_____

## Ethers

Of note in `Ethers.gd` is a variable called `recent_transactions`, which is a dictionary that logs the most transaction hash the application has sent on each network.

If your application needs to know a transaction's hash before the transaction completes (if, for example, you want your UI to show that a transaction is pending), you can monitor the dictionary by checking whether `recent_transactions.keys()` contains the name of a given network, and then checking `recent_transactions[<network_name>]`.

Doing so will return a dictionary containing the transaction hash and the `callback_args` that were sent along with that transaction.

In addition to the key management, general purpose, and built-in functions listed above, Ethers also contains functions for network management.
The default testnets are: Ethereum Sepolia, Arbitrum Sepolia, Optimism Sepolia, Base Sepolia, and Avalanche Fuji.
All of the `default_network_info` can be found at the bottom of the `Ethers.gd` script.

Note that, when running a project for the first time, GodotEthers will automatically save the `default_network_info` into a network config file.  
On start-up, the contents of this config file are loaded into `network_info`, which Ethers will use as the source for network information.

If you want to manually edit `default_network_info`, you will need to also edit the `check_for_network_info()` function and allow it to overwrite the network config file.
Otherwise, you can use the functions below to create a system for updating `network_info` while the application is running.

_____

* #### `Ethers.update_rpcs(network, rpcs)`
_____

`network` is the name of a network in `network_info`, as a String.

`rpcs` is an array of RPC urls.

This function will overwrite the list of RPCs of a given network in `network_info`, but it will not update the network config file.


_____

* #### `Ethers.add_network(network, chain_id, rpcs, scan_url, logo="")`
_____

`network` is the name of a network.

`chain_id` is the network's chain ID, as a String.

`rpcs` is an array of RPC urls.

`scan_url` is the base URL for a block explorer indexing the given network.

`logo` is an optional parameter: the filepath to a logo image.

This function will add or overwrite a network in `network_info`, but it will not update the network config file.


_____

* #### `Ethers.update_network_info()`
_____

This function overwrites the network config file with whatever `network_info` currently contains.

_____

## Transaction

Primarily responsible for abstracting the transaction process, and preventing transactions from being submitted while one is already pending.

When a transaction is initiated, the singleton will get the account's network gas balance and transaction count, then the gas price estimate, and finally submit the transaction, at which point it will update `recent_transactions` in Ethers with the transaction hash.  It will then monitor the network until it receives the transaction receipt.

The Transaction singleton is multichain-capable, and will allow transactions to occur simultaneously across chains.  It will also automatically block transaction attempts for a given network if that network is still processing a transaction.

While Transaction is not designed to be an interface like Ethers, you can modify any part of the transaction sequence if you wish, and place additional logic-executing "hooks" in the sequence if your application demands it.

_____

## Calldata

ABI encoder/decoder
