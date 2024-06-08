extends Node


func sort_args_for_encoding(abi, function_name, _args=[]):
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
			#not true for fixed arrays with static parameters 
			arg["dynamic"] = true
		elif arg_type.begins_with("bytes"):
			if arg_type.length() == 5:
				arg["dynamic"] = true
		else:
			match arg_type:
				"string": arg["dynamic"] = true
				"tuple": arg["dynamic"] = true
		
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
			chunk["length"] = chunk["calldata"].length()
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



##########   ENCODING   #########

# Handles uint, int, address, string, and dynamic bytes
func encode_general(arg):
	var value = arg["value"]
	var arg_type = arg["type"]
	var calldata = GodotSigner.call("encode_" + arg_type, value)
	if arg_type in ["bytes", "string"]:
		calldata = calldata.trim_prefix("000000000000000000000000000000000000000000000000000000000000002")

	return calldata

func encode_fixed_bytes(arg):
	pass

func encode_bool(arg):
	var value = arg["value"]
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

func encode_array(_arg):
	#add fixed array support
	#add nested array support
	
	var _arg_type = _arg["type"]
	var array = _arg["value"]
	
	var array_start_index = _arg_type.find("[")
	var arg_type = _arg_type.left(array_start_index)
	
	var calldata = ""
	var args = []
	
	for value in array:
		var new_arg = {
			"value": value,
			"type": arg_type,
			"calldata": "",
			"length": 0,
			"dynamic": false
			}
		args.push_back(new_arg)
	
		calldata = construct_calldata(args)

	return calldata

func encode_tuple(arg):
	pass


##########   DECODING   #########

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






func get_function_calldata(abi, function_name, _args=[]):
	for function in abi:
		if function.has("name"):
			if function["name"] == function_name:
				var head_index = 0
				var pre_encodings = []
				for input in function["inputs"]:
					var context_args = _args[head_index]
					var pre_encoding = get_pre_encoding(context_args, input)
					pre_encoding["head_index"] = head_index
					pre_encodings.append(pre_encoding)
					head_index += 1
				
				var head = []
				var dynamic_values = []
				for pre_encoding in pre_encodings:
					var context_calldata = get_context_calldata(pre_encoding)
					if pre_encoding["dynamic"]:
						head.append({
							"calldata": "", #offset will end up here
							"bytes_length": 32
						})
						dynamic_values.append(context_calldata)
					else:
						head.append(context_calldata)
				
				var head_size = head.size()
				for value in dynamic_values:
					head.append(value)
				
				head = calculate_offsets(head, head_size)
			
				var function_selector = get_function_selector(function)
				var calldata = function_selector + head["calldata"]

				return calldata
					

func get_pre_encoding(context_args, input):
	var raw_pre_encode = trim(input["type"])
	raw_pre_encode["context_args"] = context_args
	if raw_pre_encode["type"] == "tuple":
		raw_pre_encode["components"] = []
		var head_index = 0
		for component in input["components"]:
			var raw_component = trim(component)
			raw_pre_encode["context_args"] = context_args[head_index]
			if raw_component["dynamic"]:
				raw_pre_encode["dynamic"] = true
			raw_pre_encode["head_index"] = head_index
			raw_pre_encode["components"].append(raw_component)
			head_index += 1
	
	return raw_pre_encode

func trim(type):
	var trimmed_type = type
	var array_list = []
	var dynamic = false
	if "[" in type:
		# Get the type
		var bracket_index = 0
		for character in type:
			if character == "[":
				break
			bracket_index += 1
		trimmed_type = type.left(bracket_index)
		# Get the list of arrays
		bracket_index = 0
		for character in type:
			var extended_index = 1
			var checked_character = ""
			if character == "[":
				checked_character = type[bracket_index + extended_index]
				var fixed_size = ""
				while checked_character != "]":
					checked_character = type[bracket_index + extended_index]
					fixed_size += (checked_character)
					extended_index += 1
				if fixed_size == "":
					array_list.append(["d"])
					dynamic = true
				else:
					array_list.append([fixed_size])
			bracket_index += 1
	
	if trimmed_type in ["string", "bytes"]:
		dynamic = true
	
	var raw_pre_encode = {
		"type": trimmed_type,
		"arrays": array_list,
		"dynamic": dynamic
	}
	
	return raw_pre_encode


func get_context_calldata(pre_encoding):
	var context_args = pre_encoding["context_args"]
	var type =  pre_encoding["type"]
	var arrays =  pre_encoding["arrays"]
	var dynamic = pre_encoding["dynamic"]
	
	var head = []
	var dynamic_values = []
	
	if !arrays.is_empty():
		var context_calldata = get_array_calldata(context_args, arrays, type)
		if dynamic:
			dynamic_values.append(context_calldata)
		else:
			head.append(context_calldata)
	
	else:
		if type != "tuple":
			var static_type_call = "encode_" + type
			var context_calldata = GodotSigner.call(static_type_call, context_args)
			if type == "bytes":
				#removing extraneous offset added by ethers-rs
				context_calldata.trim_prefix("0000000000000000000000000000000000000000000000000000000000000020")
			if dynamic:
#				head.append({
#							"calldata": "", #offset will end up here
#							"bytes_length": 32
#						})
				dynamic_values.append({
					"calldata": context_calldata,
					"bytes_length": context_calldata.length()
				})
			else:
				head.append({
					"calldata": context_calldata,
					"bytes_length": context_calldata.length()
				})
		else:
			# NEEDS TUPLE SUPPORT
			for component in pre_encoding["components"]:
				var context_calldata = get_context_calldata(component)

	
	var head_size = head.size()
#
	for value in dynamic_values:
		head.append(value)

	if head.size() == 1:
		head = head[0]
	return head
	
##ultimtely this returns a dictionary:
#var context_calldata = {
#	"calldata": "", 
#	"bytes": #,
#}
# calldata is the ENTIRE string for this context, including offsets, and bytes is the full number
# to get here, there will need to potentially be multiple rounds of offset calculation and calldata concatenation


func get_array_calldata(context_args, array, type):
	var length_field = GodotSigner.encode_uint256(String(context_args.size()))
	var context_calldata = length_field
	for arg in context_args:
			if typeof(arg) == 19:  #if arg is an array
				# NEEDS NESTED ARRAY SUPPORT
				get_array_calldata(arg, array, type)
			else:
				if !type in ["bytes", "string", "tuple"]:
					var static_type_call = "encode_" + type
					context_calldata += GodotSigner.call(static_type_call, arg)
					
				# NEEDS BYTES/STRING/TUPLE SUPPORT

	return {
		"calldata": context_calldata,
		"bytes_length": context_calldata.length()
	}
					
		

func calculate_offsets(head, size):
	var dynamic_index = 0
	if typeof(head) == 19:
		for param in range(size):
			if head[param]["calldata"] == "":
				var byte_offset = 0
				for _param in range(size+dynamic_index):
					byte_offset += head[_param]["bytes_length"]
				head[param]["calldata"] = GodotSigner.encode_uint256(String(byte_offset))
				head[size+dynamic_index] = calculate_offsets(head[size+dynamic_index], head[size+dynamic_index].size())
				dynamic_index += 1
	
	var calldata_string = ""
	if typeof(head) == 28:
		for param in head:
			calldata_string += param["calldata"]
	else:
		calldata_string = head["calldata"]
			
	return {
		"calldata": calldata_string,
		"bytes_length": calldata_string.length()
	}



func get_function_selector(function):
	var selector_string = function["name"] + "("
	for input in function["inputs"]:
		selector_string += input["type"] + ","
	selector_string = selector_string.trim_suffix(",") + ")"
	var selector_bytes = selector_string.to_utf8_buffer()
	var function_selector = GodotSigner.get_function_selector(selector_bytes).left(8)
	
	return function_selector


func encode_fixed_size_array(arg, type):
	pass

func get_offset(length, shift):
	var offset = (32 * length) + shift
	return GodotSigner.encode_uint256(String(offset))



#
##This works when the Bytes are pulled directly from the blockchain
#func encode_dynamic_bytes(arg):
	#var bytes = GodotSigner.get_hex_bytes(arg)
	#
	##var length = GodotSigner.encode_u256(String(bytes.size()))
	##var parameter = length
	#var filler = 0
	#if bytes.size() > 32:
		#filler = bytes.size()%32
	#
	##parameter += GodotSigner.old_encode_bytes(bytes)
	#
	##AbiEncode automatically adds an unnecessary offset parameter.  
	##but apparently adds a necessary length param? man I don't even know
	#var parameter = GodotSigner.old_encode_bytes(bytes).trim_prefix("0000000000000000000000000000000000000000000000000000000000000020")
	#
	#if filler != 0:
		#parameter += "0".repeat(filler)
	#
	#return parameter
	

func encode_dynamic_array(dynamic_param):
	#needs to account for fixed bytes as well
	if "string" in dynamic_param["type"] || "bytes" in dynamic_param["type"]:
		return encode_dynamic_array_with_dynamic_values(dynamic_param)
	else:
		return encode_dynamic_array_with_static_values(dynamic_param)


func encode_dynamic_array_with_static_values(dynamic_param):
	var array = dynamic_param["arg"]
	var length = GodotSigner.encode_uint256(String(array.size()))
	var parameter = length
	var static_type_call = "encode_" + dynamic_param["type"]
	#needs to account for fixed bytes as well
	for value in array:
		parameter += GodotSigner.call(static_type_call, value)
	return parameter
		
		

func encode_dynamic_array_with_dynamic_values(dynamic_param):
	#var length = GodotSigner.encode_u256(array.size())
	#I'm not quite sure how this is formatted yet
	var parameter
	
	#stuff
	
	return parameter
