extends Control

var sepolia_link_contract = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
var base_bnm_contract = "0x88A2d74F47a237a62e7A51cdDa67270CE381555e"

var random_base_contract = "0x24a878dD7b154547A291F756048f29693aE2F073"

var recipient = "0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba"


var calldata_tester_contract = "0xBb3199D5822eA17Fb12a6e467C44Adc1339062E0"

# Approached with the philosophy that the "Ethers" singleton 
# should be the primary API for the developer

# implement decoding
# do more testing


# multi-chain wallet; cross-chain functionality?
# If I deploy "entry point" contracts on each testnet, I could
# implement a bridge() function that abstracts everything into a 
# a single, simple call.  Is there a way to check on-chain
# if a given token is compatible with CCIP?

# I'll need to add approve_bridge().

# If I deploy endpoints, I could also implement a chronomancer_bridge() function.

# This can be an add-on that someone can include in the template if they want.




func _ready():
	if !Ethers.account_exists("test_keystore"):
		Ethers.create_account("test_keystore", "test_password")
	
	Ethers.login("test_keystore", "test_password")
	
	print(Ethers.get_address("test_keystore"))
	
	#Ethers.get_gas_balance("Base Sepolia", "test_keystore", self, "update_gas_balance")
	#Ethers.get_erc20_info("Ethereum Sepolia", Ethers.get_address("test_keystore"), sepolia_link_contract, self, "get_erc20_info")
	
	#Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore"), base_bnm_contract, self, "get_erc20_info")

	var amount = Ethers.convert_to_bignum("0.001", 18)
	#Ethers.transfer("test_keystore", "Base Sepolia", recipient, amount, self, "get_receipt")
	#Ethers.approve_erc20_allowance("test_keystore", "Base Sepolia", base_bnm_contract, random_base_contract, self, "get_receipt")
	#Ethers.transfer_erc20("test_keystore", "Base Sepolia", base_bnm_contract, recipient, amount, self, "get_receipt")
	#Ethers.transfer_erc20("test_keystore", "Base Sepolia", base_bnm_contract, random_base_contract, amount, self, "get_receipt")


	#var number_32 = GodotSigner.decode_uint256("0000000000000000000000000000000000000000000000000000000000000020")
	#print(number_32)
	#"0xbd3c82b00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000568656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003776879000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046d656f7700000000000000000000000000000000000000000000000000000000"
	#print("96")
	#var mystery_number = GodotSigner.decode_uint256("00000000000000000000000000000000000000000000000000000000000000a0")
	#print(mystery_number)
	#var another_number = GodotSigner.decode_uint256("00000000000000000000000000000000000000000000000000000000000000e0")
	#print(another_number)
	#print("32")
	#print("________")
	
	
	#sendStrings - works!
	#sendStringsFixed - works!
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "sendStrings", [["hello", "why", "meow"]])
	
	#sendNums - works!
	#sendNumsFixed - works!
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "sendNums", [["11111", "47632784", "1032848238"]])

	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "enumAndBoolWithString", ["2", "haoollo", true])
	
	var calldata = Ethers.get_calldata("READ", Contract.CalldataTester, "structReturn", [])
	Ethers.read_from_contract("Base Sepolia", calldata_tester_contract, calldata, self, "get_decoded_result", {})
	
	#setStaticTuple - works!
	#setDynamicTuple - works.!
	#setDifficultTuple - works!
	#intakeBytes - works!
	#intakeFixedBytes - works!
	
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "setStaticTuple", [["2324727", true, "3467"]])
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "setDynamicTuple", [["hi", "3476237846", "hello"]])
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "setDifficultTuple", [[ ["hi", "meow", "hello"],  ["3748642", "45", "4876243"],  "helloooo"]])
	
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "fixedBytes8", ["e0e0e0e0e0e0e0e0"])
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "fixedBytes32", ["e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0"])
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "intakeFixedBytes", ["e0e0e0e"])
	
	#nestedStringsAndFriend - works!
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "nestedStringsAndFriend", [[["hello","meow"],["why", "why", "aaiiieee"],["ok"]], "374673264"])
	
	
	#var calldata = Ethers.get_calldata("WRITE", ontract.CalldataTester, "anotherNesteFriend", 
	#[  
		#[  ["hello","meow", "why"]  ,   ["why", "why", "aaiiieee"]  ], 
		#
		#"374673264", 
		#
		#[   ["346374", "4762784"], ["4276237", "134123"], ["31267", "4376327"]  ]
		#
	#] )
	
	# fails on oof and okay
	# oof: string[][2]
	# okay: string[2][]
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "okay", [[["yes","ok"],["aiie","ooaj"]]])
	#print(calldata)
	
	#var calldata = "0x7d6138280000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000003796573000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026f6b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000004616969650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046f6f616a00000000000000000000000000000000000000000000000000000000"
	#var chunk_amount = (calldata.length() - 8) / 64
	#for chunk in range(chunk_amount):
		#var index = chunk * 64
		#print(calldata.substr(index, 64))
		
		
	#Ethers.send_transaction("test_keystore", "Base Sepolia", calldata_tester_contract, calldata, self, "get_receipt")
	#manyDynamicNested - works!
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "manyDynamicNested", [                      
		#[
			#[
				#[
					#"why",
					#"whee",
					#"whoo"
				#],
				#[
					#"whey",
					#"wee",
					#"weuao",
					#"weean"
				#]
				#
			#],
			#[
				#[
					#"woo",
					#"woaah",
					#"waaagh"
					#
				#],
				#[
					#"weeeoo"
				#]
				#
				#
			#],
			#[
				#[
					#"weeeas",
					#"weeree"
				#],
				#[
					#"waaaasaaa",
					#"wooohhhoo",
					#"weeaaarrgh",
					#"weeeai",
					#"weoaoaosas"
					#
				#],
				#[
					#"weeyeyhf",
					#"weyeyad"
				#]
				#
				#
			#]
			#
			#
			#
			#
		#]
		#
		#
	#])
	
	# theChallenge - works!
	#var calldata = Ethers.get_calldata("WRITE", Contract.CalldataTester, "theChallenge", [   
		#
		#
				#[ 
					#
					#
					#[ ["e0e0e0e0e0e0e0e0", "e0e0e0e0e0e0e0e0"],["fhbshb", "2374672384", "sjshjff"],["4723847", true, "374"],[ ["sjfhdsj", "fiuhd", "dsfjhbds"], ["348723", "2746274"], "ewfwhjb"] ],   
					#[ ["e0e0e0e0e0e0e0e0", "e0e0e0e0e0e0e0e0"],["fhbshb", "2374672384", "sjshjff"],["4723847", true, "374"],[ ["sjfhdsj", "fiuhd", "dsfjhbds"], ["348723", "2746274"], "ewfwhjb"] ],   
					#[ ["e0e0e0e0e0e0e0e0", "e0e0e0e0e0e0e0e0"],["fhbshb", "2374672384", "sjshjff"],["4723847", true, "374"],[ ["sjfhdsj", "fiuhd", "dsfjhbds"], ["348723", "2746274"], "ewfwhjb"] ]           
					#
					#
					#]      
				#
				#
				#])
	
	#Ethers.send_transaction("test_keystore", "Base Sepolia", calldata_tester_contract, calldata, self, "get_receipt")
	

func get_decoded_result(callback):
	if callback["success"]:
		print(callback["result"][0])
	else:
		print("nope")


func update_gas_balance(callback):
	var network = callback["callback_args"]["network"]
	var account = callback["callback_args"]["account"]
	if callback["success"]:
		var balance = callback["result"]
		print(account + " has gas balance of " + balance + " on " + network)
	

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

func get_receipt(callback):
	print(callback)
