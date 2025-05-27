import pytest
import base64
import struct
from src.sct_decode import extract_sct_data

def test_extract_sct_data():
    """Test extraction of SCT data from a binary SCT"""

    # Create a mock SCT with known values
    version = 0  # SCT version 0 (v1)
    log_id_bytes = b'\xaa' * 32  # 32-byte log ID filled with 0xAA
    timestamp = 1746057600000
    extensions_length = 0  # No extensions
    hash_alg = 4  # SHA-256
    sig_alg = 3  # ECDSA
    sig_length = 4  # 4-byte mock signature
    signature = b'\xbb' * 4  # Mock signature filled with 0xBB

    # Construct the mock SCT binary data
    mock_sct = bytearray()
    mock_sct.append(version)
    mock_sct.extend(log_id_bytes)
    mock_sct.extend(struct.pack(">Q", timestamp))
    mock_sct.extend(struct.pack(">H", extensions_length))
    mock_sct.append(hash_alg)
    mock_sct.append(sig_alg)
    mock_sct.extend(struct.pack(">H", sig_length))
    mock_sct.extend(signature)

    # Call the function with our mock data
    result = extract_sct_data(bytes(mock_sct))

    # Verify the results
    assert result['sct_version'] == version
    assert result['id'] == base64.b64encode(log_id_bytes).decode('ascii')
    assert result['timestamp'] == timestamp
    assert result['extensions'] == ''
    
    # The signature field should contain the hash_alg, sig_alg, sig_length, and signature bytes
    expected_sig_data = bytes([hash_alg, sig_alg]) + struct.pack(">H", sig_length) + signature
    assert result['signature'] == base64.b64encode(expected_sig_data).decode('ascii')

def test_extract_sct_data_with_extensions():
    """Test extraction of SCT data with extensions"""
    
    # Create a mock SCT with known values and extensions
    version = 0
    log_id_bytes = b'\xaa' * 32
    timestamp = 1746057600000
    extensions_data = b'\xcc' * 4
    extensions_length = len(extensions_data)
    hash_alg = 4
    sig_alg = 3
    sig_length = 4
    signature = b'\xbb' * 4
    
    # Construct the mock SCT binary data
    mock_sct = bytearray()
    mock_sct.append(version)
    mock_sct.extend(log_id_bytes)
    mock_sct.extend(struct.pack(">Q", timestamp))
    mock_sct.extend(struct.pack(">H", extensions_length))
    mock_sct.extend(extensions_data)
    mock_sct.append(hash_alg)
    mock_sct.append(sig_alg)
    mock_sct.extend(struct.pack(">H", sig_length))
    mock_sct.extend(signature)
    
    # Call the function with our mock data
    result = extract_sct_data(bytes(mock_sct))
    
    # Verify the results
    assert result['sct_version'] == version
    assert result['id'] == base64.b64encode(log_id_bytes).decode('ascii')
    assert result['timestamp'] == timestamp
    assert result['extensions'] == 'zMzMzA=='
    
    # The signature field should contain the hash_alg, sig_alg, sig_length, and signature bytes
    expected_sig_data = bytes([hash_alg, sig_alg]) + struct.pack(">H", sig_length) + signature
    assert result['signature'] == base64.b64encode(expected_sig_data).decode('ascii')
