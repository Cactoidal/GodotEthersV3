extends Node


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

func encode_fixed_bytes(arg):
	pass

func encode_fixed_size_array(arg, type):
	pass

func get_offset(length, shift):
	var offset = (32 * length) + shift
	return GodotSigner.encode_uint256(String(offset))

func encode_string(arg):
	pass

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
