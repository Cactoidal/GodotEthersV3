use godot::prelude::*;
use godot::engine::Engine;
use godot::classes::Object;
use ethers::{core::{abi::{AbiDecode, AbiEncode}, k256::elliptic_curve::consts::{U248, U8}, types::*}, prelude::SignerMiddleware, providers::*, signers::*};
use ethers_contract::{abigen};
use ethers::core::types::transaction::eip2718::TypedTransaction;
use std::{convert::TryFrom, sync::Arc};
use hex::*;
use num_bigint::{BigUint, BigInt};

abigen!(
    ERC20ABI,
    "./ERC20.json",
    event_derives(serde::Deserialize, serde::Serialize)
);

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


//      ERC20 METHODS     //

#[func]
fn check_erc20_balance(_key: PackedByteArray, _chain_id: GString, _rpc: GString, token_contract: GString, _account_address: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);
            
    let token_address: Address = string_to_address(token_contract);
            
    let contract = ERC20ABI::new(token_address.clone(), Arc::new(client.clone()));

    let account_address: Address = string_to_address(_account_address);

    let calldata = contract.balance_of(account_address).calldata().unwrap();

    let return_string: GString = calldata.to_string().into();

    return_string

}

#[func]
fn get_erc20_name(_key: PackedByteArray, _chain_id: GString, _rpc: GString, _token_contract: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);
            
    let token_address = string_to_address(_token_contract);
            
    let contract = ERC20ABI::new(token_address.clone(), Arc::new(client.clone()));

    let calldata = contract.name().calldata().unwrap();

    let return_string: GString = calldata.to_string().into();

    return_string

}

#[func]
fn get_erc20_decimals(_key: PackedByteArray, _chain_id: GString, _rpc: GString, _token_contract: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);
            
    let token_address = string_to_address(_token_contract);
            
    let contract = ERC20ABI::new(token_address.clone(), Arc::new(client.clone()));

    let calldata = contract.decimals().calldata().unwrap();

    let return_string: GString = calldata.to_string().into();

    return_string

}


#[func]
fn check_erc20_allowance(_key: PackedByteArray, _chain_id: GString, _rpc: GString, _token_contract: GString, _spender_contract: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);
            
    let token_address = string_to_address(_token_contract);

    let spender_address = string_to_address(_spender_contract);
            
    let contract = ERC20ABI::new(token_address.clone(), Arc::new(client.clone()));

    let calldata = contract.allowance(user_address, spender_address).calldata().unwrap();

    let return_string: GString = calldata.to_string().into();

    return_string

}


#[func]
fn approve_erc20_allowance(_key: PackedByteArray, _chain_id: GString, _rpc: GString, _gas_fee: u64, _count: u64, _token_contract: GString, _spender_contract: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);

    let spender_address = string_to_address(_spender_contract);

    let token_address = string_to_address(_token_contract);

    let contract = ERC20ABI::new(token_address.clone(), Arc::new(client.clone()));

    let calldata = contract.approve(spender_address, U256::MAX).calldata().unwrap();

    let tx = Eip1559TransactionRequest::new()
        .from(user_address)
        .to(token_address) 
        .value(0)
        .gas(200000)
        .max_fee_per_gas(_gas_fee)
        .max_priority_fee_per_gas(_gas_fee)
        .chain_id(chain_id)
        .nonce(_count)
        .data(calldata);

    let signed_calldata = get_signed_calldata(tx, wallet);

    signed_calldata

}


#[func]
fn transfer_erc20(_key: PackedByteArray, _chain_id: GString, _token_contract: GString, _rpc: GString, _gas_fee: u64, _count: u64, _recipient: GString, _amount: GString) -> GString {

    let (wallet, chain_id, user_address, client) = get_signer(_key, _chain_id, _rpc);

    let token_address = string_to_address(_token_contract);

    let recipient = string_to_address(_recipient);

    let amount = string_to_uint256(_amount);

    let contract = ERC20ABI::new(token_address.clone(), Arc::new(client.clone()));

    let calldata = contract.transfer(recipient, amount).calldata().unwrap();

    let tx = Eip1559TransactionRequest::new()
        .from(user_address)
        .to(token_address) 
        .value(0)
        .gas(200000)
        .max_fee_per_gas(_gas_fee)
        .max_priority_fee_per_gas(_gas_fee)
        .chain_id(chain_id)
        .nonce(_count)
        .data(calldata);

    let signed_calldata = get_signed_calldata(tx, wallet);

    signed_calldata

}


//      HELPER METHODS        //

// Mostly for decoding RPC responses

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

