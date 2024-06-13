extends Node

# Interface for loading modules.

var ccip_module = load("res://modules/CCIP/CCIP.tscn")
var ethereal_traveler_module = load("res://modules/EtherealTraveler/EtherealTraveler.tscn")

var pending_module
var loaded_module = ""
@onready var confirm_panel = $Interface/Confirm


func _ready():
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
	
	# This is by no means an exhaustive security check, and
	# should not be treated as one. 
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
				if value.get_class() in ["GDScript", "Script", "CSharpScript", "ScriptExtension", "GodotSharp", "ResourcePreloader"]:
					if node != 0:
						print("Invalid source: Non-root node has script")
						return true
					else:
						source = value.source_code
	
	if source.contains("_init"):
		print("Invalid source: Contains _init() function")
		return true
		
	return false


func get_node_scene_tree(node, indent):
	var scene_tree = indent + "* " + node.get_class() + " (" + node.name + ")\n"
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
