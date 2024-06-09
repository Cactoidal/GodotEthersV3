extends Control

var sepolia_link_contract = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
var base_bnm_contract = "0x88A2d74F47a237a62e7A51cdDa67270CE381555e"

var random_base_contract = "0x24a878dD7b154547A291F756048f29693aE2F073"

var recipient = "0x2Bd1324482B9036708a7659A3FCe20DfaDD455ba"


var calldata_tester_contract = "0x6a574550b12c159736D7386c7793707b31Af694F"

# Approached with the philosophy that the "Ethers" singleton 
# should be the primary API for the developer


# implement nested arrays
# implement decoding
# do more testing

# drop the autoconfirm idea; transactions could have a popup before
# ever sending data to the Transaction.gd lane.  Transaction.gd's sole 
# purpose is to send out a transaction as quickly as possible.  It is 
# assumed that any transaction that gets in there does so because
# the developer intended it, manual confirms or not.



# multi-chain wallet; cross-chain functionality?




func _ready():
	if !Ethers.account_exists("test_keystore"):
		Ethers.create_account("test_keystore", "test_password")
	
	Ethers.login("test_keystore", "test_password")
	
	print(Ethers.get_address("test_keystore"))
	
	#Ethers.get_gas_balance("Base Sepolia", "test_keystore", self, "update_gas_balance")
	#Ethers.get_erc20_info("Ethereum Sepolia", Ethers.get_address("test_keystore"), sepolia_link_contract, self, "get_erc20_info")
	
	#Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore"), base_bnm_contract, self, "get_erc20_info")
	
	var amount = Ethers.convert_to_big_uint("0.001", 18)
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
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "sendStrings", [["hello", "why", "meow"]])
	
	#sendNums - works!
	#sendNumsFixed - works!
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "sendNums", [["11111", "47632784", "1032848238"]])

	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "enumAndBoolWithString", ["2", "haoollo", true])
	
	
	#setStaticTuple - works!
	#setDynamicTuple - works.!
	#setDifficultTuple - works!
	#intakeBytes - works!
	#intakeFixedBytes - works!
	
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "setStaticTuple", [["2324727", true, "3467"]])
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "setDynamicTuple", [["hi", "3476237846", "hello"]])
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "setDifficultTuple", [[ ["hi", "meow", "hello"],  ["3748642", "45", "4876243"],  "helloooo"]])
	
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "fixedBytes8", ["e0e0e0e0e0e0e0e0"])
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "fixedBytes32", ["e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0"])
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "intakeFixedBytes", ["e0e0e0e"])
	
	
	var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "nestedStringsAndFriend", [[["hello","meow"],["why", "why", "aaiiieee"],["ok"]], "374673264"])
	print(calldata)
	# theChallenge - works!
	#var calldata = Calldata.get_function_calldata(Contract.CalldataTester, "theChallenge", [   
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
	
	#var success = Calldata.get_function_calldata(Contract.IMAGINARY, "not_real", [Ethers.convert_to_big_uint("12", 18), [Ethers.convert_to_big_uint("120", 18), Ethers.convert_to_big_uint("0.01", 18), Ethers.convert_to_big_uint("9000", 18)], [["hello", Ethers.convert_to_big_uint("190", 18)], ["why", Ethers.convert_to_big_uint("7428624", 18)]]])
	#var success = Calldata.get_function_calldata(Contract.IMAGINARY, "not_real", ["recipient", true, ["amount", "meow", "merrow"], [true, "aiiieeargh", Ethers.convert_to_big_uint("120", 18)]])
	#if !success:
		#print("encoding failed")
	#else:
		#print("attempt: " + success)
	

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
