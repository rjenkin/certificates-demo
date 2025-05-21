#
# This script takes a sct response and encodes it into a value that can be inserted into a CSR
#
# Single vs multiple?
#
import sys
import json
import base64
import struct
from binascii import unhexlify

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


def main():
    # Single SCT
    # with open("sct_response.json", "r") as f:
    #     sct_input = json.load(f)

    # SCT List
    # with open("sct_list.json", "r") as f:
    #     sct_input = json.load(f)

    with open("sct_response_latest.json", "r") as f:
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

    with open("test.bin", "wb") as f:
        f.write(serialized_scts)

    # Output the line for use in openssl.cnf
    print(f'1.3.6.1.4.1.11129.2.4.2 = critical,ASN1:FORMAT:HEX,OCTETSTRING:{serialized_scts.hex()}')

if __name__ == "__main__":
    main()

# 1.3.6.1.4.1.11129.2.4.5
# CT Certificate SCTs: 
#     Signed Certificate Timestamp:
#         Version   : v1 (0x0)
#         Log ID    : 8F:3B:1F:EF:8C:43:FE:21:45:30:4B:22:F4:62:B4:C4:
#                     A3:3C:0C:84:4B:69:65:E6:B7:41:5B:F2:1A:3D:27:0D
#         Timestamp : May 14 23:47:46.681 2025 GMT
#         Extensions: none
#         Signature : ecdsa-with-SHA256
#                     30:45:02:21:00:B3:66:54:C2:A5:AB:39:81:F1:4E:CC:
#                     48:06:78:1C:51:81:1C:8B:85:AD:FF:1E:D7:27:F4:38:
#                     82:F2:F8:52:12:02:20:72:09:CA:21:82:7F:AD:44:E5:
#                     62:07:BE:5F:9B:93:BD:3A:F7:92:73:80:AA:92:E7:BF:
#                     A1:AD:6C:A6:EA:20:42

# 1.3.6.1.4.1.11129.2.4.2
# CT Precertificate SCTs: 
#     Signed Certificate Timestamp:
#         Version   : v1 (0x0)
#         Log ID    : 8F:3B:1F:EF:8C:43:FE:21:45:30:4B:22:F4:62:B4:C4:
#                     A3:3C:0C:84:4B:69:65:E6:B7:41:5B:F2:1A:3D:27:0D
#         Timestamp : May 14 23:47:46.681 2025 GMT
#         Extensions: none
#         Signature : ecdsa-with-SHA256
#                     30:45:02:21:00:B3:66:54:C2:A5:AB:39:81:F1:4E:CC:
#                     48:06:78:1C:51:81:1C:8B:85:AD:FF:1E:D7:27:F4:38:
#                     82:F2:F8:52:12:02:20:72:09:CA:21:82:7F:AD:44:E5:
#                     62:07:BE:5F:9B:93:BD:3A:F7:92:73:80:AA:92:E7:BF:
#                     A1:AD:6C:A6:EA:20:42
