extends Node

var ccip_module = preload("res://modules/CCIP/CCIP.tscn")
var ethereal_traveler_module = preload("res://modules/EtherealTraveler/EtherealTraveler.tscn")

# Simple interface for loading and deloading modules.

func _ready():
	# DEBUG
	# Quick read/write checker
	
	#Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore5"), "0x88A2d74F47a237a62e7A51cdDa67270CE381555e", self, "get_erc20_info")
	#Ethers.login("test_keystore5", "test_password")
	#var ccip = ccip_module.instantiate()
	#add_child(ccip)
	pass

func create_account():
	pass

func select_account():
	pass

func login():
	pass


func get_erc20_info(callback):
	var callback_args = callback["callback_args"]
	var network = callback_args["network"]
	var address = callback_args["address"]
	if callback["success"]:
		var erc20_name = callback_args["name"]
		var decimals = callback_args["decimals"]
		var balance = callback_args["balance"]
		print(address + " has " + balance + " " + erc20_name + " tokens with " + decimals + " decimals on " + network)
