use godot::prelude::*;
use godot::engine::Engine;
use godot::classes::Object;
use ethers::{core::{abi::{AbiDecode, AbiEncode}, k256::elliptic_curve::consts::{U248, U8}, types::*}, prelude::SignerMiddleware, providers::*, signers::*};
use ethers_contract::{abigen};
use ethers::core::types::transaction::eip2718::TypedTransaction;
use std::{convert::TryFrom, sync::Arc};
use hex::*;
use num_bigint::{BigUint, BigInt};

struct GodotEthers;

//#[gdextension]
//unsafe impl ExtensionLibrary for GodotEthers {}

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


//////      TRANSACTION CALLDATA SIGNING       //////

#[func]
fn transfer(_key: PackedByteArray, _chain_id: GString, _placeholder: GString, _rpc: GString, _gas_fee: u64, _count: u64, _recipient: GString, _amount: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);

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
             
    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);
        
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




//////      HELPER METHODS       //////

#[func]
fn get_function_selector(function_bytes: PackedByteArray) -> GString {
    let selector_bytes = ethers::utils::keccak256(&function_bytes.to_vec()[..]);
    
    let selector = hex::encode(selector_bytes);
    
    selector.to_string().into()

}

#[func]
fn get_address(_key: PackedByteArray) -> GString {

    let wallet : LocalWallet = LocalWallet::from_bytes(&_key.to_vec()[..]).unwrap();

    let address = wallet.address();

    let address_string = address.encode_hex();

    let key_slice = match address_string.char_indices().nth(*&0 as usize) {
        Some((_pos, _)) => (&address_string[26..]).to_string(),
        None => "".to_string(),
        };

    let return_string: GString = format!("0x{}", key_slice).into();

    return_string
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
fn decode_string (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: String = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = decoded.into();
    return_string
}

#[func]
fn decode_bool (_message: GString) -> GString {
    let raw_hex: String = _message.to_string();
    let decoded: bool = ethers::abi::AbiDecode::decode_hex(raw_hex).unwrap();
    let return_string: GString = format!("{:?}", decoded).into();
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



}


//      UTILITY FUNCTIONS       //

// Common type conversions and operations


fn get_signer(_key: PackedByteArray, _chain_id: GString, _rpc: GString) -> (LocalWallet, u64, Address, SignerMiddleware<Provider<Http>, LocalWallet>) {
    
    let chain_id: u64 = _chain_id.to_string().parse::<u64>().unwrap();

    let wallet : LocalWallet = LocalWallet::from_bytes(&_key.to_vec()[..]).unwrap().with_chain_id(chain_id);

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

fn string_array_to_addresses(_godot_string_array: Array<GString>) -> Vec<Address> {

    let string_vec: Vec<String> = _godot_string_array.iter_shared().map(|e| e.to_string() as String).collect();

    let address_vec: Vec<Address> = string_vec.iter().map(|e|e.parse::<Address>().unwrap() as Address).collect();

    address_vec
}

fn string_to_uint256(_string: GString) -> U256 {

    let big_uint: BigUint = _string.to_string().parse().unwrap();

    let u256: U256 = U256::from_big_endian(big_uint.to_bytes_be().as_slice());

    u256

}

fn string_array_to_uint256s(_godot_string_array: Array<GString>) -> Vec<U256> {

    let string_vec: Vec<String> = _godot_string_array.iter_shared().map(|e| e.to_string() as String).collect();

    let big_uint_vec: Vec<BigUint> = string_vec.iter().map(|e|e.parse::<BigUint>().unwrap() as BigUint).collect();

    let u256_vec: Vec<U256> = big_uint_vec.iter().map(|e|U256::from_big_endian(e.to_bytes_be().as_slice()) as U256).collect();

    u256_vec
}