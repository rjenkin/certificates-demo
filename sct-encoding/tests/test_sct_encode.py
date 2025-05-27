import pytest
import base64
import struct
from binascii import hexlify
from src.sct_encode import encode_sct

def test_encode_sct():
    """Test encoding a JSON SCT into binary format"""
    
    # Create a sample SCT in the expected JSON format
    sample_sct = {
        "sct_version": 0,
        "id": base64.b64encode(b'\xaa' * 32).decode('ascii'),  # 32-byte log ID filled with 0xAA
        "timestamp": 1620000000000,  # Example timestamp
        "extensions": "",  # Empty extensions
        "signature": base64.b64encode(b'\x04\x03\x00\x04' + b'\xbb' * 4).decode('ascii')  # Signature with hash_alg(4), sig_alg(3), length(4), and 4 bytes of 0xBB
    }
    
    # Call the function to encode the SCT
    result = encode_sct(sample_sct)
    
    # Verify the binary structure
    # First byte should be the version
    assert result[0] == 0
    
    # Next 32 bytes should be the log ID
    assert result[1:33] == b'\xaa' * 32
    
    # Next 8 bytes should be the timestamp in big-endian format
    expected_timestamp = struct.pack(">Q", 1620000000000)
    assert result[33:41] == expected_timestamp
    
    # Next 2 bytes should be extensions length (0)
    assert result[41:43] == b'\x00\x00'
    
    # The rest should be the signature
    assert result[43:] == b'\x04\x03\x00\x04' + b'\xbb' * 4

def test_encode_sct_with_extensions():
    """Test encoding a JSON SCT with extensions"""
    
    # Create sample extensions data (4 bytes of 0xCC)
    extensions_data = b'\xcc' * 4
    extensions_base64 = base64.b64encode(extensions_data).decode('ascii')
    
    # Create a sample SCT with extensions
    sample_sct = {
        "sct_version": 0,
        "id": base64.b64encode(b'\xaa' * 32).decode('ascii'),
        "timestamp": 1620000000000,
        "extensions": extensions_base64,
        "signature": base64.b64encode(b'\x04\x03\x00\x04' + b'\xbb' * 4).decode('ascii')
    }
    
    # Call the function to encode the SCT
    result = encode_sct(sample_sct)
    
    # Verify structure including extensions
    assert result[0] == 0  # Version
    assert result[1:33] == b'\xaa' * 32  # Log ID
    
    expected_timestamp = struct.pack(">Q", 1620000000000)
    assert result[33:41] == expected_timestamp  # Timestamp
    
    expected_ext_length = struct.pack(">H", 4)  # Extensions length (4)
    assert result[41:43] == expected_ext_length
    
    assert result[43:47] == extensions_data  # Extensions data
    
    assert result[47:] == b'\x04\x03\x00\x04' + b'\xbb' * 4  # Signature

def test_encode_sct_real_data():
    """Test encoding with data that mimics real SCT values"""
    
    # Sample SCT with realistic values
    sample_sct = {
        "sct_version": 0,
        "id": "pLkJkLQYWBSHuxOizGdwCjw1mAT5G9+443fNDsgN3BA=",  # Real-looking log ID
        "timestamp": 1613564510303,  # Feb 17, 2021
        "extensions": "",
        "signature": "BAMARjBEAiB6zw2I8dSRb+le1RvfjWn+6j1L+Fxv8Q8zTK6GkKzJKQIgefvMJH0zDzL0H4fFQQFVKQlA/eSLRMmPgBTCAvH9HEA="
    }
    
    # Encode the SCT
    result = encode_sct(sample_sct)
    
    # Basic structural checks
    assert len(result) > 43  # Ensure we have at least the minimum length
    assert result[0] == 0  # Version
    
    # Log ID should decode to expected value
    expected_id = base64.b64decode("pLkJkLQYWBSHuxOizGdwCjw1mAT5G9+443fNDsgN3BA=")
    assert result[1:33] == expected_id
    
    # Timestamp should match
    expected_timestamp = struct.pack(">Q", 1613564510303)
    assert result[33:41] == expected_timestamp
    
    # Extensions length (0)
    assert result[41:43] == b'\x00\x00'
    
    # Signature should match the decoded value
    expected_sig = base64.b64decode("BAMARjBEAiB6zw2I8dSRb+le1RvfjWn+6j1L+Fxv8Q8zTK6GkKzJKQIgefvMJH0zDzL0H4fFQQFVKQlA/eSLRMmPgBTCAvH9HEA=")
    assert result[43:] == expected_sig
