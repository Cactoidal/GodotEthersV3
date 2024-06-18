![GodotEthers](https://github.com/Cactoidal/GodotEthersV3/blob/main/GodotEthers.png?raw=true)
# GodotEthers
Ethers for Godot 4.3, built with Godot Rust and Ethers-rs.  Featuring [implementation](https://github.com/Cactoidal/GodotEthersV3/blob/main/ethers-v3/singletons/Calldata.gd) of the Ethereum ABI encoding/decoding [specification](https://docs.soliditylang.org/en/latest/abi-spec.html).

[About](https://github.com/Cactoidal/GodotEthersV3/blob/main/README.md#about) | [Docs](https://github.com/Cactoidal/GodotEthersV3/blob/main/DOCUMENTATION.md)

[Quickstart](https://github.com/Cactoidal/GodotEthersV3/blob/main/DOCUMENTATION.md#quickstart-1)
___

### A Note on Security

This is experimental, alpha software, in a state of ongoing development, intended for usage on testnets.  

When exporting a project, __*do not*__ "Export With Debug".  If you decide to recompile the Rust library, use the --release tag when building.
___

## Add GodotEthers to your Godot 4.3 Project

* Download the GodotEthers plugin ([cactus.godotethers](https://github.com/Cactoidal/GodotEthersV3/tree/main/addons/cactus.godotethers)) and add it to your project's `addons` folder.

* Inside `cactus.godotethers`, open the `gdextension` folder and give the dynamic library permission to open.  On MacOS, you can do this by right-clicking the `libgodot_ethers.dylib` file and opening it.  X11 uses `.so`, and Windows uses `.dll`.

* Inside the editor, open Project Settings, click Plugins, and activate GodotEthers.

* Restart the editor.
___

## How to Use

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

## About

GodotEthers combines the orchestration abilities of Godot with the signing capability of [Ethers-rs](https://github.com/gakonst/ethers-rs), made possible by [Godot Rust](https://godot-rust.github.io).  

Ethers-rs is responsible for RLP-encoding transaction data, ECDSA signing, address calculation, Keccak hashing, and BigNumber handling.  It also encodes and decodes the elementary Solidity types after they have been sorted by the Calldata singleton.

[Alloy](https://github.com/alloy-rs) is the succesor of Ethers-rs, and will replace it in a future update of GodotEthers.

Having a Rust library also gives GodotEthers access to Rust crates containing useful cryptographic primitives.  For example, the pbkdf2 crate is used to derive the keystore encryption/decryption key from an account password.  Crates like circom and openssl could also be easily integrated into the library, if needed.

In addition to games, GodotEthers can be used to decentralize dApp interfaces.  Instead of connecting to a website and using a web wallet, a contract interface can now be easily built in Godot and distributed to users in open source format.  Blockchain bots can also be made more accessible, with user-friendly interfaces.

[Check out the Documentation](https://github.com/Cactoidal/GodotEthersV3/blob/main/DOCUMENTATION.md)
