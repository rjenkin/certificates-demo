#
# This script takes a SCT in JSON format and encodes it into a value that can be inserted into a certificate
# Usage: pipenv run encode --scts <SCT json file>
#
import argparse
import base64
from binascii import unhexlify
import json
import math
import os
import struct
import sys

def encode_sct(sct):
    # sct_version: typically 0 for v1
    sct_version = struct.pack("B", sct["sct_version"])

    # id: 32 bytes, hex-encoded log ID
    # log_id = unhexlify(sct["id"])
    log_id = unhexlify(base64.b64decode(sct["id"]).hex())

    # timestamp: 8 bytes, uint64 big-endian
    timestamp = struct.pack(">Q", sct["timestamp"])

    # extensions: variable-length, with 2-byte prefix
    extensions = base64.b64decode(sct["extensions"])
    extensions_len = struct.pack(">H", len(extensions))

    # signature: decode from base64
    signature = base64.b64decode(sct["signature"])

    # Build the serialized SCT
    serialized_sct = (
        sct_version +
        log_id +
        timestamp +
        extensions_len + extensions +
        signature
    )

    return serialized_sct


def encode_binary_sct(filename_json, filename_binary):
    with open(filename_json, "r") as f:
        sct_input = json.load(f)

    # Accept a list of SCTs or a single SCT
    if isinstance(sct_input, dict):
        sct_list = [sct_input]
    else:
        sct_list = sct_input

    total_size = 0
    serialized_scts = b''
    
    for sct in sct_list:
        serialized_sct = encode_sct(sct)

        size = len(serialized_sct)

        serialized_scts += struct.pack(">H", size)
        serialized_scts += serialized_sct

        # Add the size, as well as 6 for each SCT's length
        total_size += size + 2

    # Prefix total size into serialized_scts
    serialized_scts = struct.pack(">H", total_size) + serialized_scts

    # Add ASN.1 headers
    headers = b'\x04' # OCTET STRING tag
    if len(serialized_scts) < 128:
        headers += struct.pack("B", len(serialized_scts))
    else:
        length = len(serialized_scts)
        byte_length = math.ceil(length.bit_length() / 8)
        byte = 0x80 | byte_length
        headers += struct.pack("B", byte)
        headers += struct.pack(">H", length)

    with open(filename_binary, "wb") as f:
        f.write(headers + serialized_scts)

    # Output the line for use in openssl.cnf
    return f'1.3.6.1.4.1.11129.2.4.2 = critical,ASN1:FORMAT:HEX,OCTETSTRING:{serialized_scts.hex()}'

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process SCT JSON to binary.')
    parser.add_argument('--scts', help='Path to the JSON file containing SCTs', required=True)
    parser.add_argument('--binary-output', help='Filename to save the binary SCT output', default='sct_output.bin')
    args = parser.parse_args()

    if not os.path.isfile(args.scts):
        print(f"Error: SCT JSON file '{args.scts}' does not exist", file=sys.stderr)
        sys.exit(1)

    config_value = encode_binary_sct(args.scts, args.binary_output)

    print("# The following value can be used in the certificate config:")
    print(config_value)
