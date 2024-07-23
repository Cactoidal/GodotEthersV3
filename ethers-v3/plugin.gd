@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("Ethers", "res://addons/cactus.godotethers/singletons/Ethers.gd")
	add_autoload_singleton("Transaction", "res://addons/cactus.godotethers/singletons/Transaction.gd")
	add_autoload_singleton("Contract", "res://addons/cactus.godotethers/singletons/Contract.gd")
	add_autoload_singleton("Calldata", "res://addons/cactus.godotethers/singletons/Calldata.gd")


func _exit_tree():
	remove_autoload_singleton("Ethers")
	remove_autoload_singleton("Transaction")
	remove_autoload_singleton("Contract")
	remove_autoload_singleton("Calldata")
