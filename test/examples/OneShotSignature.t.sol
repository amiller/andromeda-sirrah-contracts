// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AndromedaRemote} from "src/AndromedaRemote.sol";
import {SigVerifyLib} from "automata-dcap-v3-attestation/utils/SigVerifyLib.sol";

import {Test, console2} from "forge-std/Test.sol";
import "src/crypto/secp256k1.sol";
import {KeyManager_v0} from "src/KeyManager.sol";
import {PKE, Curve} from "src/crypto/encryption.sol";
import {OneShotSignature} from "src/examples/OneShotSignature.sol";

contract OneShotSignatureTest is Test {
    AndromedaRemote andromeda;
    KeyManager_v0 keymgr;

    address alice;

    function setUp() public {
        SigVerifyLib lib = new SigVerifyLib();
        andromeda = new AndromedaRemote(address(lib));
        andromeda.initialize();
        vm.warp(1701528486);

        andromeda.setMrSigner(
            bytes32(
                0x1cf2e52911410fbf3f199056a98d58795a559a2e800933f7fcd13d048462271c
            ),
            true
        );

        // To ensure we don't use the same address with volatile storage
        vm.prank(vm.addr(uint256(keccak256("examples/OneShotSignature.t.sol"))));
        keymgr = new KeyManager_v0(address(andromeda));
        (address xPub, bytes memory att) = keymgr.offchain_Bootstrap();
        keymgr.onchain_Bootstrap(xPub, att);

        alice = vm.addr(uint256(keccak256("alice")));
    }

    function test_oneshotsig() public {
        OneShotSignature oneshotsig = new OneShotSignature(keymgr);

        // Initialize the derived public key
        assertEq(oneshotsig.isInitialized(), false);
        (bytes memory dPub, bytes memory sig) = keymgr.offchain_DeriveKey(
            address(oneshotsig)
        );
        keymgr.onchain_DeriveKey(address(oneshotsig), dPub, sig);
        assertEq(oneshotsig.isInitialized(), true);

        // Derive the key and post it
	(address a, bytes memory sig2) = oneshotsig.offchain_keygen();
	oneshotsig.onchain_keygen(a, sig2);
	vm.roll(1);

        // Off chain compute the solution
        bytes memory sig3 = oneshotsig.offchain_signmessage("my msg");
        assert(Secp256k1.verify(a, keccak256("my msg"), sig3));

	// Show it fails!
	vm.expectRevert();
	oneshotsig.offchain_signmessage("this shouldn't work");
    }
}
