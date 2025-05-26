# Certificate Transparency Logs

Certificate Transparency logs help protect end users by making it possible to detect and fix fraudulent or mistakenly issued website security certificates, reducing the risk of impersonation or malicious websites.

When a certificate is issued by a Certificate Authority, it can be submitted to public, append-only CT logs maintained by independent operators. These logs create cryptographically verifiable records of all certificates, allowing website owners, browsers, and security researchers to monitor and audit certificate issuance. Each logged certificate receives a Signed Certificate Timestamp (SCT) as proof of inclusion, which can be embedded in the certificate itself.

Certificate Transparency uses a two-step process for logging certificates:
1. **Precertificate Submission:** Before issuing the final certificate, the CA creates a "precertificate" - a version of the certificate containing a special critical poison extension (OID 1.3.6.1.4.1.11129.2.4.3). The critical poison extension prevents the certificate from being used. This precertificate is submitted to CT logs.
2. **SCT Inclusion in Final Certificate:** After receiving SCTs from logs, the CA removes the poison extension and embeds the collected SCTs in the final certificate using the Precertificate Signed Certificate Timestamps extension (OID 1.3.6.1.4.1.11129.2.4.2).

The precertificate and final certificate are almost identical except for these extensions, ensuring that the SCTs remain valid for the final certificate despite being generated for the precertificate.

A certificate can be submitted to multiple logs.


## Certificate transparency verification

Using certificates downloaded during the "Real world certificates" exercise, we'll verify the embedded Signed Certificate Timestamps (SCTs) against public Certificate Transparency logs. This verification process demonstrates how browsers and other systems can cryptographically validate that certificates were properly logged before being trusted.

> Note: this step required NodeJS installed

In the `ct-verify` directory, run:
- `npm install`
- `npm run ct-verify ../cert1.pem ../cert2.pem`

The script should output the results of certificate transparency verification.


## How verification works

To verify that a certificate has been properly logged in a Certificate Transparency (CT) log, a multi-step cryptographic verification process is used:
1. **Log Identification:** Each Signed Certificate Timestamp (SCT) in a certificate contains a Log ID that uniquely identifies which CT log issued it. This Log ID is used to locate the log server's API endpoints.
2. **Fetching the Signed Tree Head (STH):** The verifier requests the log's current Signed Tree Head, which contains:
 - The current size of the log (number of entries)
 - A timestamp
 - The cryptographic root hash of the Merkle Tree
 - A digital signature from the log
3. **Creating a Leaf Hash:** The verifier constructs a "leaf hash" by:
 - Reconstructing what the precertificate would have been (removing SCT extensions)
 - Formatting this data as a MerkleTreeLeaf structure
 - Hashing this data using the log's specified hash algorithm (typically SHA-256)
4. **Requesting Inclusion Proofs:** The verifier sends the leaf hash to the log server's `get-proof-by-hash` endpoint, which returns a cryptographic proof (a series of hashes) showing where and how the certificate is included in the Merkle Tree.
5. **Verification:** Using the leaf hash and the returned proof hashes, the verifier can mathematically compute what the root hash should be. If this calculated root hash matches the one in the Signed Tree Head, it proves the certificate is included in the log.


### Exercise: Finding a Log Server URL

To locate which Certificate Transparency log issued a particular SCT, you need to convert the Log ID from the certificate into the format used in [Google's official CT log list](https://www.gstatic.com/ct/log_list/v3/all_logs_list.json).

**Step 1: Extract the Log ID from a certificate**

First, examine the certificate to find the Log ID embedded in its SCTs:

```bash
openssl x509 -in cert1.pem -noout -text
```

In the output, look for the "CT Precertificate SCTs" section:
```text
CT Precertificate SCTs: 
    Signed Certificate Timestamp:
        Log ID    : E6:D2:...
```

**Step 2: Convert the Log ID to base64 format**

The Log ID in the certificate is shown as a colon-separated hex string, but Google's log list uses base64 encoding. Convert the binary value to base64.

**Step 3: Search for this base64-encoded Log ID**

Now search for this base64-encoded value in Google's official CT log list [https://www.gstatic.com/ct/log_list/v3/all_logs_list.json](https://www.gstatic.com/ct/log_list/v3/all_logs_list.json)



## Certificate Transparency Log Servers

CT log servers expose several REST API endpoints defined in RFC 6962, all sharing a common base URL. These endpoints enable certificate verification, monitoring, and auditing.


### Get roots

The `get-roots` endpoint returns the set of trusted root certificates that the CT log accepts for submission.

```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-roots | jq .
{
  "certificates": [
    "Base 64 encoded DER certificate"
  ]
}
```

Get the number of root certificates:
```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-roots | jq '.certificates | length'
```

Decode a root certificate:
```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-roots | jq -r '.certificates[0]' | base64 -d | openssl x509 -inform DER -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            36:01:22:04:70:24:1f:a9:4b:51:62:a9:e3:63:9b:d4
```


### Signed Head Tree

The signed tree head shows the number of log entries in `tree_size` and is a required parameter to get proof of an entry, and the sha256_root_hash is later used to verify an entries by comparing against an expected root hash which is calculated using the proof and a hash of an entries Merkle Tree leaf.

```bash
curl --silent https://nessie2025.ct.digicert.com/log/ct/v1/get-sth | jq .
{
  "tree_size": 881954985,
  "timestamp": 1747854133389,
  "sha256_root_hash": "w5Jr51s74b8a3JgTpTXol0KVS8P8jBz0wKY9u9BRfts=",
  "tree_head_signature": "BAMARzBFAiEA9f3fBm+RBQO7DBQUSTR3v6geYdfvbXfOnjE59i/C70UCIBVfkfHYSLDo/5OuQqSHMPo7Leu+hwtlOludNGXiMk5z"
}
```


### Get entries
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

The actual certificate data is split between the `leaf_input` and `extra_data` fields in the response. The leaf_input contains the MerkleTreeLeaf with minimal certificate data (typically just the TBS for a precertificate), while the extra_data contains the full certificate chain that was submitted to the log.

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

The command below skips the chain length and extracts the length of the first certificate:
```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r ".entries[0].extra_data" | base64 -d | xxd --seek 3 --length 3 --plain
> 0006ee
```

The command below displays the certificate, this time by skipping 6 bytes and setting the length to the value obtained above (0x6ee = 1,774 bytes):
```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r '.entries[0].extra_data' | base64 -d | dd bs=1 skip=6 count=1777 2>/dev/null | openssl x509 -inform DER -text -noout
```


### Get Proof by Hash

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


### Get Entry and Proof

The `get-entry-and-proof` endpoint retrieves both a specific log entry and its associated cryptographic proof, enabling verification that the entry is included in the Merkle Tree at the specified position without downloading the entire log.

```bash
curl --silent "http://localhost:8080/testlog/ct/v1/get-entry-and-proof?leaf_index=0&tree_size=9" | jq .
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

### Add Pre Chain

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

### Add Chain

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




## Signed Certificate Timestamp List Encoding

The SCT extension in certificates follows a specific binary structure defined in RFC 6962. Let's examine how to extract and understand this encoding.

**Examining SCT Extension Structure**

Find the offset for the SCT extension data:
```bash
openssl asn1parse -in cert1.pem
```

Look for the CT Precertificate SCTs extension:
```
 1165:d=5  hl=2 l=  10 prim: OBJECT            :CT Precertificate SCTs
 1177:d=5  hl=4 l= 367 prim: OCTET STRING      [HEX DUMP]:0482016B0169007600E6D2...AD
```

Extract the extension value at offset for the octet string:
```bash
openssl asn1parse -in cert1.pem -strparse "1177"

0:d=0  hl=4 l= 363 prim: OCTET STRING      [HEX DUMP]:0169007600E6D2...AD
```

Notice there is a difference between the output of the first and second commands. This difference is the ASN.1 headers.

**Understanding the Binary Structure**

The SCT extension uses a nested structure:

1. **ASN.1 Header (first command output):**
 - `04`: ASN.1 tag for OCTET STRING
 - `82`: Length encoding indicator (2 bytes follow)
 - `016B`: Length value (363 bytes)
2. **SCT List** (second command output):
 - `0169`: Total length of SCT list (361 bytes)
3. **Individual SCTs**, each containing:
 - `0076`: Length of this SCT encoded with 2 bytes (118 bytes)
 - `00`: Version (v1)
 - 32 bytes: Log ID
 - 8 bytes: Timestamp (milliseconds since epoch)
 - 2+ bytes: Extensions length and data
 - Signature:
   - Hash algorithm (1 byte): 0=None, 1=MD5, 2=SHA-1, 3=SHA-224, 4=SHA-256, 5=SHA-384, 6=SHA-512
   - Signature algorithm (1 byte): 0=Anonymous, 1=RSA, 2=DSA, 3=ECDSA
   - Signature length (2 bytes)
   - Signature data (variable length)

### Exercise: Identify the SCT Components

Understanding the precise binary structure of SCTs is essential for properly encoding them from your own log server. In this exercise, extract the SCT as binary and output to a text file. Annotate the text file with the meaning of each byte.

```bash
openssl asn1parse -in cert1.pem -strparse "..offset.." -out sct_raw.bin -noout

xxd -c 1 --decimal sct_raw.bin > sct_raw.txt
```

### Exercise: script to extract SCT data to JSON

Update the sct_decode script to output the sct_raw.bin as JSON. Unit tests have been setup to ensure the code is output to the expected format.

When the script is working, output the response to a JSON file:
```bash
pipenv run python sct_decode.py --sct ../sct_raw.bin > scts.json
```

### Exercise: script to encode SCT data into a certificate

Update the sct_encode script to convert the JSON back to binary. By comparing the output with the original `sct_raw.bin` we can verify that the script is working correctly, and use this for embedding our own SCTs into our certificates.

```bash
xxd -c 1 --decimal sct_output.bin > sct_output.txt

diff --color=always --side-by-side ../sct_raw.txt sct_output.txt
git diff --no-index --word-diff ../sct_raw.txt sct_output.txt
```


## Running a local CT Log server

While public CT logs operated by Google, DigiCert, Cloudflare and others serve the global PKI ecosystem, running your own CT log server provides valuable hands-on learning opportunities. This exercise allows you to:
1. **Understand the complete CT workflow** by directly interacting with all components
2. **Experiment with precertificate submission** and observe the format differences
3. **Generate SCTs from your own log** that you can embed in test certificates
4. **Verify inclusion proofs** in a controlled environment
5. **Learn the verification mechanisms** that browsers implement

This practical experience with a local log server is purely educational - production certificates should always use established, trusted CT logs that are recognized by major browsers. The skills gained, however, provide deeper insights into certificate transparency that are valuable for security professionals and PKI administrators.


## Start local log server:

Google's [Certificate Transparency Go](https://github.com/google/certificate-transparency-go) project provides a reference implementation of a CT log server that can be run locally for testing and educational purposes. This implementation functions as a "CT personality" layer on top of [Trillian](https://github.com/google/trillian), which serves as the underlying Merkle tree database.

To run the local CT log server:
1. Ensure both repositories are available in the submodules directory:
 - `certificate-transparency-go`
 - `trillian`
2. Start the log server using the provided script:
```bash
./scripts/ctfe.sh
```

The script should create directory `docker/ctfe_config`. In that directory there is a configuration file `ct_server.cfg` and a root certificate called `fake-ca.cert`. To add your own certificates to the log, copy your root CA into the config directory and update the `roots_pem_file` parameter in `ct_server.cfg`. A restart of the `ctfe-1` container is required for the changes to take affect.

**Test server:**

The base URL of the local CT server should be `http://localhost:8080/testlog`. Test that it's running by calling an endpoint:
```bash
curl http://localhost:8080/testlog/ct/v1/get-roots
```

This command should return a JSON response containing the trusted root certificates that the log accepts. If the server is running correctly, you'll see a response like:

```json
{
  "certificates": [
    "MIIC..."
  ]
}
```


### Creating and Submitting a Precertificate

To implement Certificate Transparency for your certificates, follow this workflow:

**Create a precertificate with the poison extension:**
```
1.3.6.1.4.1.11129.2.4.3 = critical,ASN1:NULL
```

**Prepare the submission payload:**

```bash
# Base64 encode both certificates
ISSUER_DER_BASE64=$(openssl x509 -in issuer.crt -outform DER | base64 -w 0)
PRECERT_DER_BASE64=$(openssl x509 -in precert.crt -outform DER | base64 -w 0)

# Create the JSON payload
REQUEST_DATA=$(cat << EOF
{
  "chain": [
    "${PRECERT_DER_BASE64}",
    "${ISSUER_DER_BASE64}"
  ]
}
EOF
```

**Submit to the CT log and save the response:**
```bash
curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_DATA" \
  http://localhost:8080/testlog/ct/v1/add-pre-chain
```

**Create the final certificate** with the SCT extension:
- Remove the poison extension
- Add the SCT extension with OID 1.3.6.1.4.1.11129.2.4.2
- The certificate must be otherwise identical to ensure SCT validation

**Verify the SCT embedding:**
```bash
openssl x509 -in final.crt -noout -text
```

**Verify with the `ct-verify` script:**

To verify that your certificate contains valid SCTs from your local CT log server, you'll need to modify the ct-verify script first. The script normally uses Google's public log list to identify known CT logs, but your local server won't be in that list.

Open the [verify.ts](../ct-verify/src/verify.ts) file in the `ct-verify` directory and locate the `ctLogStore.addLog` call. Add a new entry for your local log server by inserting code that includes your server's log ID (which you can extract from your certificate's SCT) and the public key (found in the ct_server.cfg file).

Once the script is updated, run the verification with:
```bash
npm run ct-verify final.crt ca.crt
```

