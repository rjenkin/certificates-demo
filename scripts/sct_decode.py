#
# This script thats SCT data from a certificate in ASN.1 format with an octet string and outputs as JSON
#
import sys
import os
import argparse
import struct
import json
import asn1tools
import base64

class SCTEncoder(json.JSONEncoder):
    """
    A minimal JSON encoder that preserves object structure.
    Only handles special data types (like bytes) that JSON can't natively serialize.
    """
    def default(self, obj):
        # Handle bytes by converting to base64 strings
        # if isinstance(obj, bytes):
            # return base64.b64encode(obj).decode('ascii')

        # If the object has a __dict__, use that directly
        if hasattr(obj, '__dict__'):
            return obj.__dict__

        # Let the default encoder handle everything else
        return super().default(obj)


def extract_sct_list(data):
    # Compile the ASN.1 specification
    spec = asn1tools.compile_files('schema.asn')
    decoded = spec.decode('CTEmbeddedSCTList', data)

    # Total length of all scts: 361
    # print(f"Bytes: {hex(decoded[0])}")
    # print(f"Bytes: {hex(decoded[1])}")

    offset = 0

    # Get the total length of all SCTs
    total_length = struct.unpack(">H", decoded[0:2])[0]
    offset += 2

    if total_length == 0:
        print("No SCTs found")
        exit

    # Length of SCT 1
    # print(f"Bytes: {hex(decoded[2])}")
    # print(f"Bytes: {hex(decoded[3])}")

    sct_list = []
    while offset < total_length:

        sct_length = struct.unpack(">H", decoded[offset : offset + 2])[0]
        offset += 2

        sct = extract_sct_data(decoded[offset : offset + sct_length])
        sct_list.append(sct)

        offset += sct_length

    return sct_list

def extract_sct_data(sct):
    """Extracts SCT data from a single SCT"""

    offset = 0
    
    # Version
    version = sct[offset]
    offset += 1
    
    # Log ID
    log_raw = sct[offset : offset + 32]
    log_id = base64.b64encode(log_raw).decode('ascii')
    offset += 32
    
    # Timestamp
    timestamp = struct.unpack(">Q", sct[offset : offset + 8])[0]
    offset += 8

    # Extensions
    extensions = b''
    ext_len = struct.unpack(">H", sct[offset : offset + 2])[0]
    offset += 2
    if ext_len > 0:
        extensions = sct[offset : offset + ext_len].hex()
        offset += ext_len

    # Extract the signature algorithm and signature
    signature_data = sct[offset : len(sct) - 1 + 2]

    signature = base64.b64encode(signature_data).decode('ascii')

    return {
        'sct_version': version,
        'id': log_id,
        'timestamp': timestamp,
        "extensions": extensions.decode('ascii'),
        "signature": signature
    }

def decode_binary_sct(filename):
    with open(filename, "rb") as f:
        data = f.read()
        return extract_sct_list(data)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process an SCT binary file.')
    parser.add_argument('--sct', help='Path to the SCT binary file')
    args = parser.parse_args()

    if not os.path.isfile(args.sct):
        print(f"Error: SCT file '{args.sct}' does not exist", file=sys.stderr)
        sys.exit(1)

    sct_list = decode_binary_sct(args.sct)

    print(json.dumps(sct_list, cls=SCTEncoder, indent=2))
