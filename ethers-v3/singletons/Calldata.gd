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


# Decodings are next


##########   ENCODING   #########


func get_function_calldata(abi, function_name, _args=[]):
	var args = []
	var calldata = ""
	
	var function = get_function(abi, function_name)
	if !function:
		return false
		
	var inputs = get_function_inputs(function)
	if inputs:
		calldata = abi_encode(inputs, _args)
		
	var function_selector = get_function_selector(function)
				
	return function_selector + calldata
	

func get_function(abi, function_name):
	for function in abi:
		if function.has("name"):
			if function["name"] == function_name:
				return function
	return false


func get_function_inputs(function):
	if function.has("inputs"):
		return(function["inputs"])
	return false


# inputs is an array of dictionaries each containing a "type" field,
# and a "components" field if the type is a tuple
func abi_encode(inputs, _args):
	var args = []
	var selector = 0
	for input in inputs:
						
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
	
	var calldata = construct_calldata(args)
	return calldata
	

func construct_calldata(args):
	var body = []
	var tail = []
	var calldata = ""
	var callback_index = 0
	
	# Determines which types are dynamic.  If the type
	# is dynamic, inserts a placeholder uint256 into
	# the body of the calldata.  It will be updated 
	# later after the offset can been calculated.
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
			
			# Save dynamic args in the tail, to be encoded 
			# after static args have been encoded.
			tail.push_back(arg)
			
		else:
			
			# Static args go straight into the body, so that 
			# they are encoded first.
			body.push_back(arg)
			
		callback_index += 1
	
	# Merge the body and tail arrays.
	body.append_array(tail)
	
	# The args are encoded in sequence, starting with the static args.
	# The length of each argument is recorded as it is encoded.
	# These lengths are then used to calculate the offsets
	# for the dynamic args.
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
	
	# The calldata chunks are concatenated.
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
			# hex String, and converts to a PackedByteArray
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



##########   ENCODING TYPE HANDLING   #########

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
	# and converts into a hex String
	if typeof(value) == 29:
		value = value.hex_encode()
	
	while value.length() < 64:
		value += "0"
	
	return value


func encode_bool(arg):
	var value = arg["value"]
	
	# Checks if bool has been given as a String
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
	
	# Nested Arrays are encoded right to left
	var type_splitter = 2
	var array_checker = _arg_type.right(type_splitter)
	
	# Check if the rightmost array has a fixed size
	if array_checker.contains("[]"):
		arg["fixed_size"] = false
	else:
		arg["fixed_size"] = true
		type_splitter += 1
	
	# Extract the type of the rightmost array's elements
	var arg_type = _arg_type.left(-type_splitter)
	
	var calldata = ""
	var args = []
	
	for value in value_array:
	
		var new_arg = {
			"value": value,
			"type": arg_type,
			"calldata": "",
			"length": 0,
			"dynamic": false
			}
		if arg_type.contains("tuple"):
			new_arg["components"] = arg["components"]
		args.push_back(new_arg)
	
	calldata = construct_calldata(args)
	
	# Add length component if unfixed size
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


# NOTE: 
# Use get_function(abi, function_name) to get the function object, 
# then pass the function object to get_function_outputs(function).
func get_function_outputs(function):
	if function.has("outputs"):
		return(function["outputs"])
	return false


#NOTE:
# _outputs is an array of dictionaries each containing a "type" field,
# and a "components" field if the type is a tuple
func abi_decode(_outputs, calldata):
	calldata = calldata.trim_prefix("0x")
	
	var outputs = []
	for output in _outputs:
		var new_output = {
			"type" = output["type"],
			"dynamic" = false,
		}
		if output["type"].contains("tuple"):
			new_output["components"] = output["components"]
		outputs.push_back(new_output)
	
	var decoded = deconstruct_calldata(outputs, calldata)

	return decoded
	

func deconstruct_calldata(outputs, calldata):
	
	var decoded_values = []
	var dynamic_outputs = []
	
	# Determine which types are dynamic.
	for output in outputs:
		var output_type = output["type"]
		if output_type.contains("["):
			if array_is_dynamic(output_type):
				output["dynamic"] = true
		elif output_type.begins_with("bytes"):
			if output_type.length() == 5:
				output["dynamic"] = true
		elif output_type.begins_with("tuple"):
			if tuple_is_dynamic(output):
				output["dynamic"] = true
		elif output_type.begins_with("string"):
				output["dynamic"] = true
	
	# Fill in decoded static values and placeholders
	# for dynamic values.  Track the current position
	# in the calldata after decoding each value.
	var position = 0
	var head_index = 0
	for output in outputs:
		if output["dynamic"]:
			# Decode the offset value and obtain the 
			# placeholder's index.
			var _offset = calldata.substr(position, position + 32)
			position += 32
			var offset = GodotSigner.decode_uint256(_offset)
			output["offset"] = offset
			output["head_index"] = head_index
			dynamic_outputs.push_back(output)
			decoded_values.push_back("")
		else:
			# Because static args have a fixed size, it's possible to
			# know their length immediately. All single args take up 32 bytes.
			# Static arrays and tuples take up multiples of 32 bytes.
			var arg_length = get_static_size(output)
			
			# Decode the static arg using a substring sliced using
			# the arg length.  Track the current position in the 
			# calldata by adding the length.
			var _calldata = calldata.substr(position, position + arg_length)
			position += arg_length
			
			var decode_result = decode_arg(output, _calldata)
			decoded_values.push_back(decode_result["value"])
		
		head_index += 1
	
	# Determine the length of each dynamic value.
	var dynamic_selector = 0
	for output in dynamic_outputs:
		if dynamic_selector > 0:
			var previous_output = dynamic_outputs[dynamic_selector - 1]
			previous_output["length"] = output["offset"] - previous_output["offset"]
		if dynamic_selector == (dynamic_outputs.size() - 1):
			output["length"] = calldata.length() - output["offset"]
		dynamic_selector += 1
	
	# Decode dynamic values using a substring of the calldata.  Track
	# the position by adding the length of the substring.
	for output in dynamic_outputs:
		var _calldata = calldata.substr(position, position + output["length"])
		position += output["length"]
		var decode_result = decode_arg(output, _calldata)
		var _head_index = output["head_index"]
		decoded_values[_head_index] = decode_result
	
	return decoded_values
	

func get_static_size(output):
	var arg_type = output["type"]
	var total_size = 0
	
	if arg_type.contains("["):
		# Extract the type of the rightmost array's elements
		var _arg_type = arg_type.left(-3)
		
		# Get the number of elements.
		var iterator = int(arg_type.right(2).trim_suffix("]"))
		
		# Total the length of all elements.
		for element in range(iterator):
			var inner_value = {
				"type": _arg_type,
			}
			if arg_type.contains("tuple"):
				inner_value["components"] = output["components"]
			total_size += get_static_size(inner_value)
		
		return total_size
		
		
	elif arg_type.begins_with("tuple"):
		var components = output["components"]
		for component in components:
			total_size += get_static_size(component)
			
		return total_size
			
	else:
		return 32


# In the case of arrays and tuples, must be capable of
# breaking out chunks to send back through deconstruct_calldata()
func decode_arg(arg, calldata):
	var arg_type = arg["type"]
	

# Giant mess below
	
func OLDdecode_static_arg(arg, chunks, chunk_selector):
	
	var decoded = {
		"value": "",
		"chunk_selector": chunk_selector
	}
	
	var arg_type = arg["type"]
	if arg_type.contains("["):
		decoded = decode_array(arg, chunks, chunk_selector)
	elif arg_type.begins_with("uint"):
		decoded = decode_general(arg, chunks, chunk_selector)
	elif arg_type.begins_with("int"):
		decoded = decode_general(arg, chunks, chunk_selector)
	elif arg_type.begins_with("bytes"):
		if arg_type.length() == 5:
			# Checks if the bytes have been provided as a 
			# hex String, and converts to a PackedByteArray
			if typeof(arg["value"]) == 4:
				arg["value"] = arg["value"].hex_decode()
			decoded = decode_general(arg, chunks, chunk_selector)
		else:
			decoded = decode_fixed_bytes(arg, chunks, chunk_selector)
	else:
		match arg_type:
			"string": decoded = decode_general(arg, chunks, chunk_selector)
			"address": decoded = decode_general(arg, chunks, chunk_selector)
			"bool": decoded = decode_bool(arg, chunks, chunk_selector)
			"enum": decoded = decode_enum(arg, chunks, chunk_selector)
			"tuple": decoded = decode_tuple(arg, chunks, chunk_selector)
	
	return decoded


##########   DECODING TYPE HANDLING   #########

# Handles uint, int, address, string, and dynamic bytes
func decode_general(arg, chunks, chunk_selector):
	var arg_type = arg["type"]
	
	var decoded = {
		"value": "",
		"chunk_selector": chunk_selector
	}
	
	if arg_type in ["string", "bytes"]:
		#Strings and bytes will need their offsets checked against chunks
		pass
	else:
		decoded["value"] = GodotSigner.call("decode_" + arg_type, chunks[chunk_selector])
	
	#chunk selector needs to be incremented properly
	decoded["chunk_selector"] += 1
	return decoded


func decode_fixed_bytes(arg, chunks, chunk_selector):
	var value = arg["value"]
	var arg_type = arg["type"]

	var decoded = {
		"value": "",
		"chunk_selector": chunk_selector
	}
		
	# Checks if the bytes have been provided as a PackedByteArray,
	# and converts into a hex String
	if typeof(value) == 29:
		value = value.hex_encode()
	
	while value.length() < 64:
		value += "0"
	
	return decoded


func decode_bool(arg, chunks, chunk_selector):
	var value = arg["value"]
	
	
	var decoded = {
		"value": "",
		"chunk_selector": chunk_selector
	}
	
	# Checks if bool has been given as a String
	if typeof(value) == 4:
		if value == "true":
			value = true
		else:
			value = false
			
	var calldata = GodotSigner.encode_bool(value)
	return decoded


func decode_enum(arg, chunks, chunk_selector):
	var value = arg["value"]
	
	
	var decoded = {
		"value": "",
		"chunk_selector": chunk_selector
	}
	
	
	var calldata = GodotSigner.encode_uint8(value)
	
	
	return decoded


func decode_array(arg, chunks, chunk_selector):
	
	var _arg_type = arg["type"]
	var value_array = arg["value"]
	
	
	var decoded = {
		"value": [],
		"chunk_selector": chunk_selector
	}
	
	# Nested Arrays are encoded right to left
	var type_splitter = 2
	var array_checker = _arg_type.right(type_splitter)
	
	# Check if the rightmost array has a fixed size
	if array_checker.contains("[]"):
		arg["fixed_size"] = false
	else:
		arg["fixed_size"] = true
		type_splitter += 1
	
	# Extract the type of the rightmost array's elements
	var arg_type = _arg_type.left(-type_splitter)
	
	var calldata = ""
	var args = []
	
	for value in value_array:
	
		var new_arg = {
			"value": value,
			"type": arg_type,
			"calldata": "",
			"length": 0,
			"dynamic": false
			}
		if arg_type.contains("tuple"):
			new_arg["components"] = arg["components"]
		args.push_back(new_arg)
	
	calldata = construct_calldata(args)
	
	# Add length component if unfixed size
	if !arg["fixed_size"]:
		var _param_count = str(arg["value"].size())
		var param_count = GodotSigner.encode_uint256(_param_count)
		calldata = param_count + calldata
		
	return decoded


func decode_tuple(arg, chunks, chunk_selector):
	var value_array = arg["value"]
	var components = arg["components"]
	
	
	var decoded = {
		"value": [],
		"chunk_selector": chunk_selector
	}

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
	
	return decoded
	
