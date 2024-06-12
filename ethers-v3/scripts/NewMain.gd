extends Node

var ccip_module = preload("res://modules/CCIP/CCIP.tscn")
var ethereal_traveler_module = preload("res://modules/EtherealTraveler/EtherealTraveler.tscn")

# Simple interface for loading modules.

var pending_module
var loaded_module = ""
@onready var confirm_panel = $Interface/Confirm

func _ready():
	# DEBUG
	# Quick read/write checker
	
	#Ethers.get_erc20_info("Base Sepolia", Ethers.get_address("test_keystore5"), "0x88A2d74F47a237a62e7A51cdDa67270CE381555e", self, "get_erc20_info")
	#Ethers.login("test_keystore5", "test_password")
	#var ccip = ccip_module.instantiate()
	#add_child(ccip)
	$Interface/Panel/Header/EtherealTraveler.connect("pressed", load_script.bind("Ethereal Traveler", ethereal_traveler_module))
	$Interface/Panel/Header/CCIP.connect("pressed", load_script.bind("Cross-Chain ERC20", ccip_module))
	confirm_panel.get_node("Yes").connect("pressed", load_module)
	confirm_panel.get_node("No").connect("pressed", clear_interface)


func _process(delta):
	if get_node_or_null(loaded_module):
		$Interface.visible = false
	else:
		$Interface.visible = true


func load_script(name, module):
	
	# Before instantiating the scene, checks that the scene
	# only has one script, attached to the root node, and 
	# rejects the script if it contains the "_init" function.
	if source_invalid(module):
		return
		
	pending_module = module.instantiate()
	var source = pending_module.get_script().source_code
	var module_scene_tree = get_node_scene_tree(pending_module, "")
	$Interface/Tree.text = module_scene_tree
	$Interface/Log.text = source
	confirm_panel.get_node("Prompt").text = 'Load module\n"' + name + '"?' 
	confirm_panel.visible = true


func source_invalid(module):
	
	var source = ""
	
	var packed_state = module.get_state()
	for node in range(packed_state.get_node_count()):
		for property in packed_state.get_node_property_count(node):
			var value = packed_state.get_node_property_value(node, property)
			
			# Checks if the property is an Object
			if typeof(value) == 24:
				if value.get_class() in ["GDScript", "Script", "CSharpScript", "ScriptExtension", "GodotSharp"]:
					if node != 0:
						print("Invalid source: Non-root node has script")
						return true
					else:
						source = packed_state.get_node_property_value(0, 0).source_code
	
	if source.contains("_init"):
		print("Invalid source: Contains _init() function")
		return true
		
	return false


func get_node_scene_tree(node, indent):
	var scene_tree = indent + "* " + node.get_class() + "\n"
	indent += "     "
	var tree = node.get_children()
	for child in tree:
		scene_tree += get_node_scene_tree(child, indent)
	return scene_tree


func load_module():
	clear_interface()
	add_child(pending_module)
	loaded_module = NodePath(pending_module.name)


func clear_interface():
	confirm_panel.visible = false
	$Interface/Log.text = ""
	$Interface/Tree.text = ""



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
