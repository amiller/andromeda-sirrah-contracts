pragma solidity ^0.8.13;

import "../crypto/secp256k1.sol";
import "../KeyManager.sol";
import {IAndromeda} from "src/IAndromeda.sol";

contract OneShotSignature {
    KeyManager_v0 keymgr;

    constructor(KeyManager_v0 _keymgr) {
        keymgr = _keymgr;
    }

    function isInitialized() public view returns (bool) {
        return keymgr.derivedPub(address(this)).length != 0;
    }

    // Public key that can sign exactly one message
    address public addr;

    // Generate a key, store in volatile only
    function offchain_keygen() public returns (address, bytes memory) {
	require(isInitialized());

	// Generate
	IAndromeda Suave = keymgr.Suave();
	bytes32 privKey = Suave.localRandom();

	// Store
	Suave.volatileSet("mykey", privKey);

	// Derive the address
	address a = Secp256k1.deriveAddress(uint(privKey));

	// Attest to the address
	bytes memory sig = keymgr.attest(bytes32(bytes20(a)));

	return (a, sig);
    }

    // Store the address on chain
    function onchain_keygen(address a, bytes memory sig) public {
	// Only set once
	require(addr == address(0));
	IAndromeda Suave = keymgr.Suave();
	
	// Verify attestation
	keymgr.verify(address(this), bytes32(bytes20(a)), sig);

	// Go ahead and set
	addr = a;
    }

    // Generate one signature, then unset the key in volatile
    function offchain_signmessage(string memory m) public returns(bytes memory) {
	IAndromeda Suave = keymgr.Suave();
	bytes32 privkey = Suave.volatileGet("mykey");
	require(addr != address(0));
	require(privkey != 0);

	// Create the signature
	bytes memory sig = Secp256k1.sign(uint(privkey), keccak256(bytes(m)));

	// Immediately clear the key
	Suave.volatileSet("mykey", 0);
	
	// Finally return it
	return sig;
    }
}
