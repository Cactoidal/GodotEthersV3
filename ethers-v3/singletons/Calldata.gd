extends Node

# (ostensibly, needs to be thoroughly tested)

# Can encode:     
# Uints of typical varieties  - works
# Ints of typical varieties  - works
# Strings - works
# Addresses - works
# Unfixed Dynamic Arrays - works
# Fixed Dynamic Arrays - works
# Unfixed Static Arrays - works
# Fixed Static Arrays - works
# Bools - works
# Enums - works
# Bytes - works
# Dynamic Tuples - works
# Static Tuples  - works
# FixedBytes - works (manually constructed)
# Arrays of Structs - works
# Nested Arrays - works


# Decodings also need attention (see Ethers for these)
# Automatic decoding using the ABI would be nice
# I should be able to simply reverse the process, given the ABI and the incoming calldata


func get_function_calldata(abi, function_name, _args=[]):
	var args = []
	for function in abi:
		if function.has("name"):
			if function["name"] == function_name:
				if function.has("inputs"):
					var selector = 0
					for input in function["inputs"]:
						
						var new_arg = {
							"value": _args[selector],
							"type": input["type"],
							"calldata": "",
							"length": 0,
							"dynamic": false
							}
						if input["type"].contains("tuple"):
							new_arg["components"] = input["components"]
						args.push_back(new_arg)
						selector += 1
				
				var function_selector = get_function_selector(function)
				
				var calldata = construct_calldata(args)
				return function_selector + calldata
	
	return false

func construct_calldata(args):
	var body = []
	var tail = []
	var calldata = ""
	var callback_index = 0
	for arg in args:
		var arg_type = arg["type"]
		if arg_type.contains("["):
			if array_is_dynamic(arg_type):
				arg["dynamic"] = true
		elif arg_type.begins_with("bytes"):
			if arg_type.length() == 5:
				arg["dynamic"] = true
		elif arg_type.begins_with("tuple"):
			if tuple_is_dynamic(arg):
				arg["dynamic"] = true
		elif arg_type.begins_with("string"):
				arg["dynamic"] = true
				
		if arg["dynamic"]:
			var placeholder = {
				"value": "placeholder",
				"type": "uint256",
				"calldata": "placeholder",
				"length": 32,
				"dynamic": false
			}
			body.push_back(placeholder)
			arg["callback_index"] = callback_index
			tail.push_back(arg)
		else:
			body.push_back(arg)
		callback_index += 1
	
	body.append_array(tail)
	
	var selector = 0
	for chunk in body:
		if chunk["calldata"] != "placeholder":
			chunk["calldata"] = encode_arg(chunk)
			chunk["length"] = chunk["calldata"].length() / 2
			if chunk["dynamic"]:
				var _callback_index = chunk["callback_index"]
				var total_offset = 0
				for _chunk in range(selector):
					var _length = body[_chunk]["length"]
					total_offset += _length
				body[_callback_index]["value"] = total_offset
				body[_callback_index]["calldata"] = GodotSigner.encode_uint256(str(total_offset))
			
		selector += 1
	
	for _calldata in body:
		calldata += _calldata["calldata"]
	
	return calldata


func encode_arg(arg):
	var calldata = ""
	
	var arg_type = arg["type"]
	if arg_type.contains("["):
		calldata = encode_array(arg)
	elif arg_type.begins_with("uint"):
		calldata = encode_general(arg)
	elif arg_type.begins_with("int"):
		calldata = encode_general(arg)
	elif arg_type.begins_with("bytes"):
		if arg_type.length() == 5:
			# Checks if the bytes have been provided as a 
			# hex string, and converts to a PackedByteArray
			if typeof(arg["value"]) == 4:
				arg["value"] = arg["value"].hex_decode()
			calldata = encode_general(arg)
		else:
			calldata = encode_fixed_bytes(arg)
	else:
		match arg_type:
			"string": calldata = encode_general(arg)
			"address": calldata = encode_general(arg)
			"bool": calldata = encode_bool(arg)
			"enum": calldata = encode_enum(arg)
			"tuple": calldata = encode_tuple(arg)
	
	return calldata


func get_function_selector(function):
	var selector_string = function["name"] + "("
	for input in function["inputs"]:
		
		if input["type"].contains("tuple"):
			selector_string += get_tuple_components(input)
			selector_string = selector_string.trim_suffix(",")
			if input["type"].length() > 5:
				selector_string += input["type"].right(-5)
		else:
			selector_string += input["type"] + ","
			
	selector_string = selector_string.trim_suffix(",") + ")"

	var selector_bytes = selector_string.to_utf8_buffer()
	var function_selector = GodotSigner.get_function_selector(selector_bytes).left(8)
	
	return function_selector

func get_tuple_components(input):	
	var selector_string = ""
	
	for component in input["components"]:
		if component["type"].contains("tuple"):
			selector_string += get_tuple_components(component)
			if component["type"].length() > 5:
				selector_string += component["type"].right(-5)
		else:
			selector_string += component["type"] + ","
	
	selector_string = selector_string.trim_suffix(",")
	return ("(" + selector_string + "),")


func array_is_dynamic(arg_type):
	for dynamic_type in ["string", "bytes"]:
		if arg_type.begins_with(dynamic_type):
			return true
			
	if arg_type.contains("[]"):
		return true
		
	return false


func tuple_is_dynamic(arg):
	var components = arg["components"]
	for component in components:
		var arg_type = component["type"]
		if arg_type.contains("["):
			if array_is_dynamic(arg_type):
				return true
		elif arg_type.begins_with("bytes"):
			if arg_type.length() == 5:
				return true
		elif arg_type.begins_with("tuple"):
			if tuple_is_dynamic(arg_type):
				return true
		elif arg_type.begins_with("string"):
				return true
	
	return false



##########   ENCODING   #########

# Handles uint, int, address, string, and dynamic bytes
func encode_general(arg):
	var value = arg["value"]
	var arg_type = arg["type"]
	var calldata = GodotSigner.call("encode_" + arg_type, value)
	if arg_type in ["bytes", "string"]:
		calldata = calldata.trim_prefix("0000000000000000000000000000000000000000000000000000000000000020")

	return calldata


func encode_fixed_bytes(arg):
	var value = arg["value"]
	var arg_type = arg["type"]
		
	# Checks if the bytes have been provided as a PackedByteArray,
	# and converts into a hex string
	if typeof(value) == 29:
		value = value.hex_encode()
	
	while value.length() < 64:
		value += "0"
	
	return value


func encode_bool(arg):
	var value = arg["value"]
	# Checks if bool is string
	if typeof(value) == 4:
		if value == "true":
			value = true
		else:
			value = false
	var calldata = GodotSigner.encode_bool(value)
	return calldata


func encode_enum(arg):
	var value = arg["value"]
	var calldata = GodotSigner.encode_uint8(value)
	return calldata


func encode_array(arg):
	
	var _arg_type = arg["type"]
	var value_array = arg["value"]
	
	var array_start_index = _arg_type.find("[")
	var arg_type = _arg_type.left(array_start_index)
	
	array_start_index += 2
	var array_checker = _arg_type.left(array_start_index)
	
	if array_checker.contains("[]"):
		arg["fixed_size"] = false
	else:
		arg["fixed_size"] = true
		array_start_index += 1
	
	var calldata = ""
	var args = []
	
	for value in value_array:
		var value_type = arg_type
		# Checks if value is nested array
		if typeof(value) == 28:
			value_type += _arg_type.right(-array_start_index)
		var new_arg = {
			"value": value,
			"type": value_type,
			"calldata": "",
			"length": 0,
			"dynamic": false
			}
		if arg_type.contains("tuple"):
			new_arg["components"] = arg["components"]
		args.push_back(new_arg)
	
	calldata = construct_calldata(args)
	
	if !arg["fixed_size"]:
		var _param_count = str(arg["value"].size())
		var param_count = GodotSigner.encode_uint256(_param_count)
		calldata = param_count + calldata
		
	return calldata


func encode_tuple(arg):
	var value_array = arg["value"]
	var components = arg["components"]

	var args = []
	var selector = 0
	for component in components:
		var new_arg = {
			"value": value_array[selector],
			"type": component["type"],
			"calldata": "",
			"length": 0,
			"dynamic": false
				}
		if component["type"].contains("tuple"):
			new_arg["components"] = component["components"]
		args.push_back(new_arg)
		selector += 1
	
	var calldata = construct_calldata(args)
	
	return calldata
	


##########   DECODING   #########

# Potentially these will just be in Ethers instead

func decode_uint(arg):
	pass

func decode_int(arg):
	pass

func decode_address(arg):
	pass

func decode_fixed_bytes(arg):
	pass

func decode_bool(arg):
	pass
	
func decode_enum(arg):
	pass

func decode_string(arg):
	pass

func decode_bytes(arg):
	pass

func decode_array(arg):
	pass

func decode_tuple(arg):
	pass
