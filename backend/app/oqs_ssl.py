"""
OQS-OpenSSL Integration Module
==============================

This module provides utilities for configuring and using OQS-OpenSSL provider
with Python's ssl module for post-quantum TLS/HTTPS connections.

Note: This requires Python to be built against OQS-OpenSSL, or using a workaround
with ctypes to load the provider dynamically.
"""

import os
import sys
import ctypes
from pathlib import Path
from typing import Optional
import ssl


def setup_oqs_provider(provider_path: Optional[str] = None) -> bool:
    """
    Setup OQS-OpenSSL provider for use with Python's ssl module.
    
    This function attempts to load the oqs-provider library and configure
    OpenSSL to use it. Note that Python's ssl module uses the system OpenSSL,
    so this may not work unless Python was built against OQS-OpenSSL.
    
    Args:
        provider_path: Path to oqsprov.dll (Windows) or oqsprov.so (Linux)
    
    Returns:
        True if provider was loaded successfully, False otherwise
    """
    if provider_path is None:
        # Try to find provider in common locations
        script_dir = Path(__file__).parent.parent
        possible_paths = [
            script_dir / "oqs-provider" / "oqsprov.dll",
            script_dir / "oqs-provider" / "oqsprov.so",
            script_dir.parent / "oqs-provider" / "_build" / "bin" / "Release" / "oqsprov.dll",
        ]
        
        for path in possible_paths:
            if path.exists():
                provider_path = str(path)
                break
    
    if not provider_path or not Path(provider_path).exists():
        print("[OQS-SSL] WARNING: OQS provider not found. HTTPS will use classical algorithms only.")
        print("[OQS-SSL] To enable post-quantum TLS:")
        print("[OQS-SSL]   1. Build oqs-provider using setup_oqs_openssl.ps1")
        print("[OQS-SSL]   2. Set OQS_PROVIDER_PATH environment variable")
        return False
    
    # On Windows, we can't directly load the provider into Python's OpenSSL
    # because Python uses its own OpenSSL library. We need to use a workaround
    # or ensure Python was built against OQS-OpenSSL.
    
    # For now, we'll just set the environment variable that OpenSSL might use
    provider_dir = str(Path(provider_path).parent)
    os.environ["OPENSSL_MODULES"] = provider_dir
    
    print(f"[OQS-SSL] Provider path set to: {provider_dir}")
    print("[OQS-SSL] NOTE: Python's ssl module may not use this provider")
    print("[OQS-SSL] For full OQS-OpenSSL support, use a reverse proxy (nginx) compiled with OQS-OpenSSL")
    
    return True


def create_ssl_context(
    certfile: str,
    keyfile: str,
    use_pq: bool = True
) -> ssl.SSLContext:
    """
    Create an SSL context for HTTPS with optional post-quantum support.
    
    Args:
        certfile: Path to SSL certificate file
        keyfile: Path to SSL private key file
        use_pq: Whether to attempt to use post-quantum algorithms
    
    Returns:
        SSLContext configured for HTTPS
    """
    if use_pq:
        setup_oqs_provider()
    
    # Create SSL context
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    
    # Load certificate and key
    try:
        context.load_cert_chain(certfile, keyfile)
        print(f"[OQS-SSL] Loaded certificate: {certfile}")
        print(f"[OQS-SSL] Loaded private key: {keyfile}")
    except Exception as e:
        print(f"[OQS-SSL] ERROR: Failed to load certificate/key: {e}")
        raise
    
    # Configure TLS options
    context.options |= ssl.OP_NO_SSLv2
    context.options |= ssl.OP_NO_SSLv3
    context.options |= ssl.OP_NO_TLSv1
    context.options |= ssl.OP_NO_TLSv1_1
    
    # Prefer TLS 1.3 (which supports post-quantum algorithms better)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.maximum_version = ssl.TLSVersion.MAXIMUM_SUPPORTED
    
    # Set cipher preferences (Python's ssl module has limited control)
    # For full post-quantum support, use a reverse proxy
    
    return context


def verify_oqs_openssl() -> bool:
    """
    Verify that OQS-OpenSSL is available and working.
    
    This checks if the system OpenSSL (or Python's OpenSSL) supports
    post-quantum algorithms. This is a best-effort check.
    
    Returns:
        True if OQS-OpenSSL appears to be available, False otherwise
    """
    try:
        import subprocess
        import shutil
        
        # Try to find openssl binary
        openssl_path = shutil.which("openssl")
        if not openssl_path:
            print("[OQS-SSL] OpenSSL binary not found in PATH")
            return False
        
        # Check OpenSSL version
        result = subprocess.run(
            [openssl_path, "version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        
        if result.returncode != 0:
            return False
        
        version_str = result.stdout.strip()
        print(f"[OQS-SSL] Found OpenSSL: {version_str}")
        
        # Check if it's OpenSSL 3.x (required for providers)
        if "OpenSSL 3." not in version_str:
            print("[OQS-SSL] WARNING: OpenSSL 3.x is required for providers")
            return False
        
        # Try to list providers (if oqs-provider is loaded)
        result = subprocess.run(
            [openssl_path, "list", "-providers"],
            capture_output=True,
            text=True,
            timeout=5,
            env={**os.environ, "OPENSSL_MODULES": os.environ.get("OPENSSL_MODULES", "")}
        )
        
        if "oqsprovider" in result.stdout.lower() or "oqs" in result.stdout.lower():
            print("[OQS-SSL] OQS provider appears to be available")
            return True
        else:
            print("[OQS-SSL] OQS provider not detected in OpenSSL")
            print("[OQS-SSL] This is normal if using Python's bundled OpenSSL")
            return False
            
    except Exception as e:
        print(f"[OQS-SSL] Error checking OQS-OpenSSL: {e}")
        return False

