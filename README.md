# GodotEthersV3
Ethers for Godot 4.3

Docs

___

Using GodotEthers is pretty straightforward.  To interact with a contract, you just have to slap an ABI somewhere in your project, use `get_calldata()` for the function you want, then call `read_from_contract()` or `send_transaction()`.  That's it!  Encoding calldata and decoding the RPC response is all taken care of for you.

You can also use `perform_request()` to call any Ethereum method.  For example, you could use this to monitor a contract's activity with `eth_getLogs`.

Note that every function mentioned on this page is defined in the `Ethers.gd` singleton, and can be accessed by calling the singleton, e.g. `Ethers.get_calldata()`.
___

### `get_calldata(ABI, function_name, args=[])`

`ABI` is your contract's ABI.  It needs to be pasted into a .gd file somewhere so you can call it.

`function_name` is the contract function you want to call.

`args` is an array containing your contract function's arguments.  Here are the expected types:

* __uint8/16/32/64/128/256__ as STRING

* __int8/16/32/64/128/256__ as STRING

* __address__ as STRING

* __bytes__ as hex STRING (or, optionally, as PackedByteArray)

* __bool__ as STRING (or, optionally, as a bool)

* __enum__ as STRING

* __array__ as ARRAY

* __tuple__ (struct) as ARRAY containing any of these types

You will notice that everything must be passed as either a String, Array of Strings, or Array of Arrays, with only a couple (optional) exceptions.

___

### A Note on Numbers

You can use `convert_to_smallnum()` to convert a BigNumber into a more readable form, and use `convert_to_bignum()` before passing the value as an argument in `get_calldata()`.  You must transport BigNumbers as Strings, otherwise they will overflow.

___

### `read_from_contract(network, contract, calldata, callback_node, callback_function, callback_args={})`

`network` is the name of the network you're calling, as a String.

`contract` is the contract address.

`calldata` is the calldata you got from get_calldata().

`callback_node` is the Godot node that will receive the decoded RPC result (typically self)

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

### `perform_request(method, params, network, callback_node, callback_function, callback_args={}, retries=3)`

`method` is the ethereum method you want to call.

`params` is an array containing the arguments passed for the method.

`network` and the `callback` parameters are the same as they are for `read_from_contract()` and `send_transaction()`.  Note that `perform_request()` is a lower level function call, and therefore will * *not* * automatically decode the RPC result.  You will need to process the result in your callback function.

`retries` is the number of times the application will try to call an RPC node until it receives a successful response code.  3 is the default number of attempts. Note that in addition to retries, GodotEthers is programmed to automatically cycle through all the RPC nodes listed for a given network.

___

### A Note on Built-ins

You can use `transfer()` to send ETH.  The ERC20 ABI is also present by default, in the `Contract.gd` singleton.   You can call `get_erc20_info()` to get a token's name, decimals, and balance for a supplied address, all in one call.  You can also use `approve_erc20()` to grant the maximum spend allowance to a contract, and you can use `transfer_erc20()` to send tokens.

