use godot::prelude::*;
use godot::engine::Engine;
use godot::classes::Object;
use ethers::{core::{abi::{AbiDecode, AbiEncode}, k256::elliptic_curve::consts::{U248, U8}, types::*}, prelude::SignerMiddleware, providers::*, signers::*};
use ethers_contract::{abigen};
use ethers::core::types::transaction::eip2718::TypedTransaction;
use std::{convert::TryFrom, sync::Arc};
//use hex::*;
use num_bigint::{BigUint, BigInt};
use pbkdf2::{pbkdf2_hmac, pbkdf2_hmac_array};
use sha2::Sha256;
use zeroize::*;
use rlp::*;
use k256::ecdsa::{Signature, VerifyingKey};
use k256::PublicKey as K256PublicKey;
use k256::elliptic_curve::sec1::ToEncodedPoint;

struct GodotEthers;

#[gdextension]
unsafe impl ExtensionLibrary for GodotEthers {
    fn on_level_init(level: InitLevel) {
        if level == InitLevel::Scene {
            // The StringName identifies your singleton and can be
            // used later to access it.
            Engine::singleton().register_singleton(
                StringName::from("GodotSigner"),
                GodotSigner::new_alloc().upcast(),
            );
        }
    }

    fn on_level_deinit(level: InitLevel) {
        if level == InitLevel::Scene {
            // Get the `Engine` instance and `StringName` for your singleton.
            let mut engine = Engine::singleton();
            let singleton_name = StringName::from("GodotSigner");

            // We need to retrieve the pointer to the singleton object,
            // as it has to be freed manually - unregistering singleton 
            // doesn't do it automatically.
            let singleton = engine
                .get_singleton(singleton_name.clone())
                .expect("cannot retrieve the singleton");

            // Unregistering singleton and freeing the object itself is needed 
            // to avoid memory leaks and warnings, especially for hot reloading.
            engine.unregister_singleton(singleton_name);
            singleton.free();
        }
    }
}


#[derive(GodotClass)]
#[class(init, base=Object)]
pub struct GodotSigner {
    base: Base<Object>,
}

#[godot_api]
impl GodotSigner {


//////      ACCOUNT MANAGEMENT       //////


#[func]
fn derive_key(_password: GString, _salt: GString) -> Array<u8> {
    let password = _password.to_string();
    let salt = _salt.to_string();
    let password_bytes = password.as_bytes();
    let salt_bytes = salt.as_bytes();

    let n = 600_000;

    let mut key = pbkdf2_hmac_array::<Sha256, 32>(password_bytes, salt_bytes, n);

    let key_array: Array<u8> = key.iter().map(|e| *e as u8).collect();

    key.zeroize();
    
    key_array
}


#[func]
fn get_address(_key: PackedByteArray) -> GString {

    let mut _key = _key.to_vec();

    let wallet : LocalWallet = LocalWallet::from_bytes(&_key[..]).unwrap();

    _key.zeroize();

    let address = wallet.address();

    let address_string = address.encode_hex();

    let key_slice = match address_string.char_indices().nth(*&0 as usize) {
        Some((_pos, _)) => (&address_string[26..]).to_string(),
        None => "".to_string(),
        };

    let return_string: GString = format!("0x{}", key_slice).into();

    return_string
}


//////      TRANSACTION CALLDATA SIGNING       //////

#[func]
fn transfer(_key: PackedByteArray, _chain_id: GString, _placeholder: GString, _rpc: GString, _gas_fee: u64, _count: u64, _recipient: GString, _amount: GString) -> GString {

    let mut _key = &mut _key.to_vec();

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);

    _key.zeroize();

    let recipient = string_to_address(_recipient);

    let amount = string_to_uint256(_amount);

    let tx = Eip1559TransactionRequest::new()
        .from(user_address)
        .to(recipient) 
        .value(amount)
        .gas(22000)
        .max_fee_per_gas(_gas_fee)
        .max_priority_fee_per_gas(_gas_fee)
        .chain_id(chain_id)
        .nonce(_count);

    let signed_calldata = get_signed_calldata(tx, wallet);

    signed_calldata

}


#[func]
fn sign_raw_calldata(_key: PackedByteArray, _chain_id: GString, _contract_address: GString, _rpc: GString, _gas_limit: GString, _gas_fee: u64, _count: u64, _value: GString, _calldata: GString) -> GString {
             
    let mut _key = &mut _key.to_vec();

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);

    _key.zeroize();
    
    let contract_address: Address = _contract_address.to_string().parse().unwrap();

    let gas_limit = string_to_uint256(_gas_limit);

    let value = string_to_uint256(_value);

    let calldata = string_to_bytes(_calldata);

    let tx = Eip1559TransactionRequest::new()
        .from(user_address)
        .to(contract_address) 
        .value(value)
        .gas(gas_limit) //recommend 900000
        .max_fee_per_gas(_gas_fee)
        .max_priority_fee_per_gas(_gas_fee)
        .chain_id(chain_id)
        .nonce(_count)
        .data(calldata);

    let signed_calldata = get_signed_calldata(tx, wallet);

    signed_calldata

}




//////     ABI ENCODING AND DECODING       //////

#[func]
fn keccak(bytes: PackedByteArray) -> PackedByteArray {
    let keccak_hash = ethers::utils::keccak256(&bytes.to_vec()[..]);
    
    keccak_hash.to_vec().into()

}



#[func]
fn get_function_selector(function_bytes: PackedByteArray) -> GString {
    let selector_bytes = ethers::utils::keccak256(&function_bytes.to_vec()[..]);
    
    let selector = hex::encode(selector_bytes);
    
    selector.to_string().into()

}



//////      ENCODING       //////


#[func]
fn encode_bool (_bool: bool) -> GString {
    let encoded = ethers::abi::AbiEncode::encode(_bool);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_address (_address: GString) -> GString {
    let address = string_to_address(_address);
    let encoded = ethers::abi::AbiEncode::encode(address);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_bytes (_bytes: PackedByteArray) -> GString {
    let bytes: Bytes = _bytes.to_vec().into();
    let encoded = ethers::abi::AbiEncode::encode(bytes);
    let return_string: GString = hex::encode(encoded).into();
    return_string

}

#[func]
fn encode_string (_string: GString) -> GString {
    let string: String = _string.into();
    let encoded = ethers::abi::AbiEncode::encode(string);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_uint8 (_uint8: GString) -> GString {
    let uint8: u8 = _uint8.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(uint8);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_uint16 (_uint16: GString) -> GString {
    let uint16: u16 = _uint16.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(uint16);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_uint32 (_uint32: GString) -> GString {
    let uint32: u32 = _uint32.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(uint32);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_uint64 (_uint64: GString) -> GString {
    let uint64: u64 = _uint64.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(uint64);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_uint128 (_uint128: GString) -> GString {
    let uint128: U128 = _uint128.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(uint128);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_uint256 (_big_uint: GString) -> GString {
    let u256 = string_to_uint256(_big_uint);
    let encoded = ethers::abi::AbiEncode::encode(u256);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_int8 (_int8: GString) -> GString {
    let int8: i8 = _int8.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(int8);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_int16 (_int16: GString) -> GString {
    let int16: i16 = _int16.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(int16);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_int32 (_int32: GString) -> GString {
    let int32: i32 = _int32.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(int32);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_int64 (_int64: GString) -> GString {
    let int64: i64 = _int64.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(int64);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_int128 (_int128: GString) -> GString {
    let int128: i128 = _int128.to_string().parse().unwrap();
    let encoded = ethers::abi::AbiEncode::encode(int128);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}

#[func]
fn encode_int256 (_big_int: GString) -> GString {
    let i256: I256 = I256::try_from(_big_int.to_string()).unwrap();
    let encoded = ethers::abi::AbiEncode::encode(i256);
    let return_string: GString = hex::encode(encoded).into();
    return_string
}



//////      DECODING       //////

#[func]
fn decode_bool (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: bool = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_address (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: Address = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_bytes (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: Bytes = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let decoded_array: Vec<u8> = decoded.iter().map(|e| *e as u8).collect();
    let decoded_hex = hex::encode(decoded_array);
    decoded_hex.into()
}

#[func]
fn decode_string (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: String = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = decoded.into();
    return_string
}

#[func]
fn decode_uint8 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: u8 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_uint16 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: u16 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_uint32 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: u32 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_uint64 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: u64 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_uint128 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: u128 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_uint256 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: U256 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_int8 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: i8 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_int16 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: i16 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_int32 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: i32 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_int64 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: i64 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_int128 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: i128 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}

#[func]
fn decode_int256 (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: I256 = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
    return_string
}


//      BIGNUMBER FUNCTIONS       //

// Common operations for large unsigned integers

#[func]
fn arithmetic(_number1: GString, _number2: GString, _operation: GString) -> GString {

    let number1: BigUint = _number1.to_string().parse().unwrap();

    let number2: BigUint = _number2.to_string().parse().unwrap();

    let output: BigUint;

    let operation: String = _operation.to_string();

    assert!(["ADD", "SUBTRACT", "DIVIDE", "MULTIPLY"].contains(&&*operation) == true);

    if operation == "ADD" {
        output = number1 + number2;
    }
    else if operation == "SUBTRACT" {
        assert!(Self::compare(_number1, _number2, "GREATER THAN OR EQUAL".into()) == true);
        output = number1 - number2;
    }
    else if operation == "DIVIDE" {
        assert!(Self::compare(_number1, _number2, "GREATER THAN OR EQUAL".into()) == true);
        output = number1 / number2;
        }
    else if operation == "MULTIPLY" {
        output = number1 * number2;
    }
    else {
        // Unreachable due to earlier assert
        output = number1;
    }
    
    output.to_string().into()

}


#[func]
fn compare(_number1: GString, _number2: GString, _operation: GString) -> bool {
    let number1: BigUint = _number1.to_string().parse().unwrap();

    let number2: BigUint = _number2.to_string().parse().unwrap();

    let output: bool;

    let operation: String = _operation.to_string();

    assert!(["GREATER THAN", "LESS THAN", "GREATER THAN OR EQUAL", "LESS THAN OR EQUAL", "EQUAL"].contains(&&*operation) == true);

    if operation == "GREATER THAN" {
        if number1 > number2 {
            output = true;
        }
        else {
            output = false;
        }
    }
    else if operation == "LESS THAN" {
        if number1 < number2 {
            output = true;
        }
        else {
            output = false;
        }
    }
    else if operation == "GREATER THAN OR EQUAL" {
        if number1 >= number2 {
            output = true;
        }
        else {
            output = false;
        }
    }
    else if operation == "LESS THAN OR EQUAL" {
        if number1 <= number2 {
            output = true;
        }
        else {
            output = false;
        }
    }
    else if operation == "EQUAL" { 
        if number1 == number2 {
            output = true;
        }
        else {
            output = false;
        }
    }
    else {
        // Unreachable due to earlier assert
        output = false;
    }


    output

}



//      COMMUNICATION       //

// Helper functions for signing and communicating with bootnodes and peers

#[func]
fn sign_calldata(_key: PackedByteArray, _message: GString, _with_prefix: bool) -> PackedByteArray{
    let mut _key = &mut _key.to_vec();

    let (wallet, chain_id, user_address, client) = get_signer(_key, "1".into(), "https://rpc.com".into());

    _key.zeroize();
 
    let message_hash: H256;
    let message = string_to_bytes(_message);

    if (_with_prefix) {
        message_hash = ethers::utils::hash_message(message);
    }
    else {
        let keccak_hash = ethers::utils::keccak256(message);
        message_hash = H256::from(keccak_hash);
    }

    let signature = wallet.sign_hash(message_hash).unwrap().to_vec();

    signature.into()
}



#[func]
fn sign_bytes(_key: PackedByteArray, _message: PackedByteArray, _with_prefix: bool) -> PackedByteArray{
    let mut _key = &mut _key.to_vec();

    let (wallet, chain_id, user_address, client) = get_signer(_key, "1".into(), "https://rpc.com".into());

    _key.zeroize();
 
    let message_hash: H256;
  
    if (_with_prefix) {
        let message = _message.to_vec();
        message_hash = ethers::utils::hash_message(message);
    }
    else {
        let _message_hash = Self::keccak(_message);
        let message_array: [u8; 32] = _message_hash.to_vec().as_slice().try_into().unwrap();
        message_hash = H256::from(message_array);
    }

    let signature = wallet.sign_hash(message_hash).unwrap().to_vec();

    signature.into()
}


#[func]
fn recover_signer_string(_message: GString, _signature: PackedByteArray) -> PackedByteArray {
    let message = string_to_bytes(_message);
    let public_key = Self::recover_signer(message.to_vec().into(), _signature);
    public_key
    
}


#[func]
fn recover_signer(_message_bytes: PackedByteArray, _signature: PackedByteArray) -> PackedByteArray {
    let sig_vec = _signature.to_vec();

    let _message_hash = Self::keccak(_message_bytes);
    let message_hash_vec = _message_hash.to_vec();
    let message_hash = message_hash_vec.as_slice();

    let recovery_signature: ethers::types::Signature = ethers::types::Signature::try_from(sig_vec.as_slice()).unwrap();
    let recovery_id = recovery_signature.recovery_id().unwrap();

    let short_sig = sig_vec.as_slice()[..64].to_vec();
    let signature: k256::ecdsa::Signature = k256::ecdsa::Signature::try_from(short_sig.as_slice()).unwrap();
    
    let verifying_key = VerifyingKey::recover_from_prehash(
        message_hash,
        &signature,
        recovery_id,
    ).unwrap();

    let public_key = K256PublicKey::from(&verifying_key);
    let public_key = public_key.to_encoded_point(/* compress = */ false);
    let public_key = public_key.as_bytes().to_vec();

    public_key.into()

}


#[func]
fn get_address_from_public_key(public_key: PackedByteArray) -> GString {
    let public_key_hash = Self::keccak(public_key.to_vec()[1..].into());
    let _signer = public_key_hash.to_vec();
    
    let signer = Address::from_slice(&_signer[12..]);

    let signer_hex = signer.encode_hex();

    let key_slice = match signer_hex.char_indices().nth(*&0 as usize) {
        Some((_pos, _)) => (&signer_hex[26..]).to_string(),
        None => "".to_string(),
        };

    let return_string: GString = format!("0x{}", key_slice).into();

    return_string
}


#[func]
fn get_public_key(key: PackedByteArray) -> GString {
    let key: [u8; 32] = key.to_vec().try_into().unwrap();

    let key = SigningKey::from_bytes(&key.into()).unwrap();

    let verifying_key = key.verifying_key().to_encoded_point(false);

    key.to_bytes().zeroize();

    let _public_key = verifying_key.as_bytes();

    let public_key = hex::encode(_public_key);

    public_key.into()
}


#[func]
fn rlp_encode(_message: GString) -> PackedByteArray {
    let message: String = _message.into();
    let bytes = rlp::encode(&message).to_vec();
    bytes.into()
}


#[func]
fn rlp_decode(_bytes: PackedByteArray) -> GString {
    let bytes = _bytes.to_vec();
    let message: String = rlp::decode(&bytes).unwrap();
    message.into()
}



}



//      UTILITY FUNCTIONS       //

// Common type conversions and operations


fn get_signer(_key: &mut [u8], _chain_id: GString, _rpc: GString) -> (LocalWallet, u64, Address, SignerMiddleware<Provider<Http>, LocalWallet>) {
    
   //let mut _key = &mut _key.to_vec()[..];
    
    let chain_id: u64 = _chain_id.to_string().parse::<u64>().unwrap();

    let wallet : LocalWallet = LocalWallet::from_bytes(_key).unwrap().with_chain_id(chain_id);

    _key.zeroize();

    let user_address = wallet.address();
            
    let provider = Provider::<Http>::try_from(_rpc.to_string()).expect("could not instantiate HTTP Provider");

    let client = SignerMiddleware::new(provider, wallet.clone());

    (wallet, chain_id, user_address, client)
}

fn get_signed_calldata(_tx: Eip1559TransactionRequest, _wallet: LocalWallet) -> GString {

    let typed_tx: TypedTransaction = TypedTransaction::Eip1559(_tx.clone());

    let signature = _wallet.sign_transaction_sync(&typed_tx).unwrap();

    let rlp_signed = TypedTransaction::rlp_signed(&typed_tx, &signature);

    let signed_calldata = hex::encode(rlp_signed);

    signed_calldata.into()
}


fn string_to_bytes(_string: GString) -> Bytes {

    let string: String = _string.to_string();

    let byte_array = hex::decode(string).unwrap();
        
    let bytes: Bytes = byte_array.into();

    bytes
}

fn string_to_address(_string: GString) -> Address {

    let address: Address = _string.to_string().parse().unwrap();

    address
}


fn string_to_uint256(_string: GString) -> U256 {

    let big_uint: BigUint = _string.to_string().parse().unwrap();

    let u256: U256 = U256::from_big_endian(big_uint.to_bytes_be().as_slice());

    u256

}
