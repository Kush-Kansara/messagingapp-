"""
Post-Quantum Security Verification Script
=========================================

This script verifies that the PQ implementation is actually using
real Kyber cryptography and not the fallback implementation.

Run this to ensure your setup is PQ-safe:
    python verify_pq.py
"""

import sys
import os

# Add the app directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

def verify_liboqs_installation():
    """Verify that liboqs-python is installed and working"""
    print("=" * 60)
    print("Verifying liboqs-python installation...")
    print("=" * 60)
    
    try:
        import oqs
        print("[OK] liboqs-python is installed")
        
        # Test Kyber512 keypair generation
        print("\nTesting Kyber512 keypair generation...")
        with oqs.KeyEncapsulation("Kyber512") as kem:
            public_key = kem.generate_keypair()
            secret_key = kem.export_secret_key()
            print(f"[OK] Generated public key: {len(public_key)} bytes")
            print(f"[OK] Generated secret key: {len(secret_key)} bytes")
            
            # Test encapsulation/decapsulation
            print("\nTesting KEM encapsulation/decapsulation...")
            ciphertext, shared_secret_encap = kem.encap_secret(public_key)
            print(f"[OK] Encapsulation successful: ciphertext={len(ciphertext)} bytes, shared_secret={len(shared_secret_encap)} bytes")
            
            # Test decapsulation with the secret key
            with oqs.KeyEncapsulation("Kyber512", secret_key) as kem_decaps:
                shared_secret_decap = kem_decaps.decap_secret(ciphertext)
                print(f"[OK] Decapsulation successful: shared_secret={len(shared_secret_decap)} bytes")
                
                # Verify shared secrets match
                if shared_secret_encap == shared_secret_decap:
                    print("[OK] Shared secrets match! KEM is working correctly.")
                    return True
                else:
                    print("[ERROR] Shared secrets do NOT match!")
                    return False
                    
    except ImportError:
        print("[ERROR] liboqs-python is NOT installed!")
        print("\nTo install:")
        print("  pip install liboqs-python")
        print("\nWithout liboqs-python, the backend will use a fallback")
        print("implementation that is NOT post-quantum safe!")
        return False
    except Exception as e:
        print(f"[ERROR] Failed to test liboqs: {e}")
        return False


def verify_backend_implementation():
    """Verify that the backend PQ module uses real Kyber"""
    print("\n" + "=" * 60)
    print("Verifying backend PQ implementation...")
    print("=" * 60)
    
    try:
        from app.pq_transport import generate_server_keypair, server_decapsulate, get_server_public_key
        from app.pq_transport import HAS_OQS
        
        if not HAS_OQS:
            print("[WARNING] Backend is using fallback implementation (NOT PQ-safe)")
            print("  Install liboqs-python to enable real Kyber")
            return False
        
        print("[OK] Backend PQ module loaded successfully")
        print("[OK] Using real Kyber implementation (liboqs-python)")
        
        # Generate a test keypair
        print("\nGenerating test server keypair...")
        public_key, secret_key = generate_server_keypair()
        print(f"[OK] Generated keypair: public={len(public_key)} bytes, secret={len(secret_key)} bytes")
        
        # Verify we can get the public key
        retrieved_public = get_server_public_key()
        if retrieved_public == public_key:
            print("[OK] Public key retrieval works")
        else:
            print("[ERROR] Public key mismatch")
            return False
        
        # Test with a real encapsulation (simulate client)
        print("\nTesting full KEM flow (simulating client handshake)...")
        import oqs
        with oqs.KeyEncapsulation("Kyber512") as client_kem:
            # Client performs encapsulation
            ciphertext, client_shared_secret = client_kem.encap_secret(public_key)
            print(f"[OK] Client encapsulation: ciphertext={len(ciphertext)} bytes")
            
            # Server performs decapsulation
            server_shared_secret = server_decapsulate(ciphertext)
            print(f"[OK] Server decapsulation: shared_secret={len(server_shared_secret)} bytes")
            
            # Verify shared secrets match
            if client_shared_secret == server_shared_secret:
                print("[OK] Shared secrets match! Full KEM flow works correctly.")
                return True
            else:
                print("[ERROR] Shared secrets do NOT match!")
                return False
                
    except Exception as e:
        print(f"[ERROR] Failed to verify backend: {e}")
        import traceback
        traceback.print_exc()
        return False


def verify_aes_gcm():
    """Verify AES-GCM encryption/decryption works"""
    print("\n" + "=" * 60)
    print("Verifying AES-GCM implementation...")
    print("=" * 60)
    
    try:
        from app.pq_transport import derive_session_key, encrypt_aes_gcm, decrypt_aes_gcm
        
        # Generate a test shared secret
        import os
        test_shared_secret = os.urandom(32)
        
        # Derive session key
        print("Deriving session key from shared secret...")
        session_key = derive_session_key(test_shared_secret)
        print(f"[OK] Derived session key: {len(session_key)} bytes (256 bits)")
        
        # Test encryption/decryption
        print("\nTesting AES-GCM encryption/decryption...")
        test_message = "Hello, post-quantum world!"
        nonce, ciphertext = encrypt_aes_gcm(session_key, test_message)
        print(f"[OK] Encrypted: nonce={len(nonce)} bytes, ciphertext={len(ciphertext)} bytes")
        
        decrypted = decrypt_aes_gcm(session_key, nonce, ciphertext)
        print(f"[OK] Decrypted message: {decrypted}")
        
        if decrypted == test_message:
            print("[OK] AES-GCM encryption/decryption works correctly!")
            return True
        else:
            print(f"[ERROR] Decrypted message doesn't match! Expected: {test_message}, Got: {decrypted}")
            return False
            
    except Exception as e:
        print(f"[ERROR] Failed to verify AES-GCM: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all verification checks"""
    print("\n" + "=" * 60)
    print("POST-QUANTUM SECURITY VERIFICATION")
    print("=" * 60)
    print("\nThis script verifies that your implementation uses")
    print("real post-quantum cryptography (CRYSTALS-Kyber).\n")
    
    results = []
    
    # Check 1: liboqs-python installation
    results.append(("liboqs-python Installation", verify_liboqs_installation()))
    
    # Check 2: Backend implementation
    results.append(("Backend PQ Implementation", verify_backend_implementation()))
    
    # Check 3: AES-GCM
    results.append(("AES-GCM Encryption", verify_aes_gcm()))
    
    # Summary
    print("\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)
    
    all_passed = True
    for name, passed in results:
        status = "[PASS]" if passed else "[FAIL]"
        print(f"{status}: {name}")
        if not passed:
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("[SUCCESS] ALL CHECKS PASSED - Your backend is PQ-safe!")
    else:
        print("[WARNING] SOME CHECKS FAILED - Your implementation may not be PQ-safe!")
        print("\nTo fix:")
        print("1. Install liboqs-python: pip install liboqs-python")
        print("2. Restart your FastAPI server")
        print("3. Run this verification script again")
    print("=" * 60 + "\n")
    
    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())

