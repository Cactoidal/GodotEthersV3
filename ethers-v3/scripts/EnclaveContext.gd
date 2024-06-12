extends Node
class_name EnclaveContext

enum enclave_type {
	NONE,
	INTEL_SGX,
	AMD_SEV,
	APPLE_SECURE_ENCLAVE,
	ARM_TRUSTZONE,
	RISC_V_KEYSTONE,
	MICROSOFT_VSM,
	IBM_SSC,
	OPEN_ENCLAVE_SDK,
	GOOGLE_CONFIDENTIAL_VM,
	AWS_NITRO_ENCLAVE
}

var current_enclave

func _ready():
	check_for_enclave()

func check_for_enclave():
	var possible_enclaves = get_possible_enclaves()
	current_enclave = enclave_type.NONE
	for enclave in possible_enclaves:
		if current_enclave == enclave_type.NONE:
			match enclave:
				enclave_type.APPLE_SECURE_ENCLAVE: current_enclave = check_for_apple_secure_enclave()

func get_possible_enclaves():
	var system = OS.get_name()
	match system:
		"macOS": return [enclave_type.APPLE_SECURE_ENCLAVE]
	
	return [enclave_type.NONE]

func check_for_apple_secure_enclave():
	return enclave_type.APPLE_SECURE_ENCLAVE
	
func generate_key():
	match current_enclave:
		enclave_type.APPLE_SECURE_ENCLAVE: return GodotSigner.apple_enclave_generate_key(32)
		enclave_type.NONE: return Crypto.new().generate_random_bytes(32)
