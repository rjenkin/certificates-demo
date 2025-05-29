# CT Log Servers

Return [Certificate Transparency Logs](../certificate-transparency-logs.md)

CT log servers expose several REST API endpoints defined in RFC 6962, all sharing a common base URL. These endpoints enable certificate verification, monitoring, and auditing.


## Get roots

The `get-roots` endpoint returns the set of trusted root certificates that the CT log accepts for submission.

```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-roots | jq .
{
  "certificates": [
    "Base 64 encoded DER certificate"
  ]
}
```

**Check the number of root certificates:**

Use the following command to get the number of root certificates:
```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-roots | jq '.certificates | length'
```

**View root certificate details:**

The root certificates are base-64 encoded in DER format:
```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-roots | jq -r '.certificates[0]' | base64 -d | openssl x509 -inform DER -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            36:01:22:04:70:24:1f:a9:4b:51:62:a9:e3:63:9b:d4
```


## Signed Head Tree

The signed tree head shows the number of log entries in `tree_size` and is a required parameter to get proof of an entry, and the `sha256_root_hash` is later used to verify an entry.

```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-sth | jq .
{
  "tree_size": 881954985,
  "timestamp": 1747854133389,
  "sha256_root_hash": "w5Jr51s74b8a3JgTpTXol0KVS8P8jBz0wKY9u9BRfts=",
  "tree_head_signature": "BAMARzBFAiEA9f3fBm+RBQO7DBQUSTR3v6geYdfvbXfOnjE59i/C70UCIBVfkfHYSLDo/5OuQqSHMPo7Leu+hwtlOludNGXiMk5z"
}
```


## Get Proof by Hash

The `get-proof-by-hash` endpoint locates a specific certificate in the log and returns a cryptographic proof of its inclusion, using the SHA-256 hash of its Merkle Tree Leaf as the search key.

> **Important:** When creating the leaf hash for verification, you must remove the SCT extension from the certificate's TBS (to-be-signed) section. This is because the precertificate that was originally logged didn't contain this extension - it had the poison extension instead.

```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-proof-by-hash?tree_size=55&hash=..hash.."
{
  leaf_index: 59781451,
  audit_path: [
    '...base64 encoded...',
    ...
  ]
}
```

The returned `leaf_index` identifies the certificate's position in the log, while the `audit_path` contains the hash values needed to reconstruct the Merkle path from this leaf to the root hash. This proof can be mathematically verified against the log's signed tree head to confirm the certificate's inclusion.


## Get entries

This endpoint returns an entry using it's index in the log.

```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq .
{
  "entries": [
    {
      "leaf_input": "..base64 encoded MerkleTreeLeaf..",
      "extra_data": "..base64 encoded data.."
    }
  ]
}
```

**Leaf input:**

The `leaf_input` field returned by a CT Log server contains the serialized binary encoding of the complete MerkleTreeLeaf structure as defined in RFC 6962. The structure follows:
- Version (1 byte)
- MerkleLeafType (1 byte)
- TimestampedEntry, which contains:
 - Timestamp (8 bytes)
 - LogEntryType (2 bytes)
 - Signed entry data (certificate or precertificate)
 - Extensions (2+ bytes)

The actual certificate data is split between the `leaf_input` and `extra_data` fields in the response. The `leaf_input` contains the MerkleTreeLeaf with minimal certificate data (typically just the TBS for a precertificate), while the extra_data contains the full certificate chain that was submitted to the log.

This separation allows verifiers to reconstruct the exact data that was hashed to create the Merkle Tree, while still providing the complete certificates needed for full verification.

```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r ".entries[0].leaf_input" | base64 -d | xxd
```

**Extra data:**

The `extra_data` field in a CT log entry contains the full certificate chain that was submitted to the log. This data follows this structure:
 - Bytes 0-2: Total length of the certificate chain data (3-byte integer)
 - Bytes 3-5: Length of the first certificate (3-byte integer, e.g., 1774)
 - Byte 6: Start of certificate (0x30, ASN.1 SEQUENCE tag)
 - Byte 7: Length encoding byte (e.g., 0x82 indicates the next 2 bytes specify length)
 - Bytes 8-9: Certificate length (e.g., 1770)
 - Bytes 10+: Certificate data

The command below extracts the length of the first certificate:
```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r ".entries[0].extra_data" | base64 -d | xxd --seek 3 --length 3 --plain
> 0006ee
```

The command below displays the certificate, this time by skipping 6 bytes and setting the length to the value obtained above (0x6ee = 1,774 bytes):
```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r '.entries[0].extra_data' | base64 -d | dd bs=1 skip=6 count=1777 2>/dev/null | openssl x509 -inform DER -text -noout
```

## Get Entry and Proof

The `get-entry-and-proof` endpoint retrieves both a specific log entry and its associated cryptographic proof, enabling verification that the entry is included in the Merkle Tree at the specified position without downloading the entire log.

> Note: this endpoint might not exposed on all log servers.

```bash
curl --silent "https://localhost:8080/logs/ct/v1/get-entry-and-proof?leaf_index=0&tree_size=881954985" | jq .
{
  "leaf_input": "...Base 64 encoded MerkleTreeLeaf...",
  "extra_data": "...",
  "audit_path": [
    "IF...4=",
    "zI...E=",
    "YY...U=",
    "Y5...g="
  ]
}
```

## Add Pre Chain

The `add-pre-chain` endpoint is used to submit precertificates to a CT log before the final certificate is issued.

```bash
curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d '{"chain":["Base64 encoded DER (precert)", "Base64 encoded DER (CA)"]}' \
  https://nessie2025.ct.digicert.com/log/ct/v1/add-pre-chain
```

**Key characteristics:**
- Accepts a precertificate containing the critical poison extension (1.3.6.1.4.1.11129.2.4.3 = critical,ASN1:NULL)
- Returns a Signed Certificate Timestamp (SCT) that can be embedded in the final certificate
- The precertificate must chain to a root certificate trusted by the log
- This is the standard method for implementing Certificate Transparency

**Response:**
```json
{
  "sct_version": 0,
  "id": "jzsf74xD/iFFMEsi9GK0xKM8DIRLaWXmt0Fb8ho9Jw0=",
  "timestamp": 1747266466681,
  "extensions": "",
  "signature": "BAMARzBFAiEAs2ZUwqWrOYHxTsxIBngcUYEci4Wt/x7XJ/Q4gvL4UhICIHIJyiGCf61E5WIHvl+bk70695JzgKqS57+hrWym6iBC"
}
```

## Add Chain

The `add-chain` endpoint is used to submit already-issued certificates to the log. This is typically used for existing certificates or for backward compatibility.

```bash
curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d '{"chain":["Base64 encoded DER (final cert)", "Base64 encoded DER (CA)"]}' \
  https://nessie2025.ct.digicert.com/log/ct/v1/add-chain
```

**Key characteristics:**
- Accepts a final certificate without the poison extension
- Returns an SCT, but this cannot be embedded in the certificate (as it's already issued)
- Useful for logging legacy certificates or monitoring existing deployments
- The returned SCT can be delivered via OCSP stapling or TLS extension

**Important considerations:**
- The `add-chain` endpoint is useful for adding existing certificates to logs
- For new certificates, the preferred workflow is to use `add-pre-chain` first, then embed the SCT in the final certificate
- Both endpoints require a complete certificate chain up to a root trusted by the log

## Next section

[SCT encoding](./ct_encoding.md)
