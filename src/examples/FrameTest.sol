pragma solidity ^0.8.13;

import "../crypto/secp256k1.sol";
import "../crypto/encryption.sol";
import "../KeyManager.sol";
import "../IAndromeda.sol";

contract FrameTest {
    KeyManager_v0 keymgr;
    address public owner;

    constructor(KeyManager_v0 _keymgr) {
        keymgr = _keymgr;
        owner = msg.sender;
    }

    function isInitialized() public view returns (bool) {
        return keymgr.derivedPub(address(this)).length != 0;
    }

    // Part 0: Exfiltration of the Sirrah key to the Enclave app
    /* Since we are modifying the enclave itself to have the application in its outer
       logic, we need to share some authority (private keys) with this outer application state.

       On the other hand, we can't just return values to the caller, since that might be the
       untrusted host. 

       We also don't want to muck about much on the Andromeda interface, adding more 
       precompiles etc., until we have a more thorough plan, beyond scope here.

       One way we can do this fast is by repurposing the volatileSet. The outer application can
       read this state.
    */

    function offchain_Enclave() public {
        IAndromeda Suave = keymgr.Suave();
        bytes32 priv = keymgr.derivedPriv();
        // There is no "volatileGet" for priv... instead the outer application (main.rs)
        // will read it directly
        Suave.volatileSet("priv", priv);
    }

    // Part 1: TLS registration
    bytes public encryptedSslKey;

    function onchain_Setup(bytes memory ciph) public {
        require(msg.sender == owner);
        encryptedSslKey = ciph;
    }
}
