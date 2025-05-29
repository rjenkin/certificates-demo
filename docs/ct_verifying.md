# Verifying a SCT

Return [Certificate Transparency Logs](../certificate-transparency-logs.md)

Using the certificates downloaded during the "Chain of Trust" exercise, we'll verify the embedded Signed Certificate Timestamps (SCTs) against public Certificate Transparency logs. This verification process demonstrates how browsers and other systems can cryptographically validate that certificates were properly logged before being trusted.

**Install packages:**

Go to the `ct-verify` directory and install the required dependencies with:
```bash
npm install
```

> Note: If you install packages through an internal package manager, add the URL to the following environment variable:
> ```bash
> # NodeJS package source
> export NPM_CONFIG_REGISTRY=https://your-internal-proxy/api/npm/npm
> npm install
> ```

**Run the script:**

After the installation completes, run the verification script by providing both the certificate and its issuer as arguments:
```bash
npm run ct-verify ../ssl/chain-of-trust/cert1.pem ../ssl/chain-of-trust/cert2.pem
```

> Note: If you're behind a corporate proxy, you'll need to pass the CA bundle to NodeJS
> ```bash
> export NODE_EXTRA_CA_CERTS=~/ca_bundle.pem
> npm run ct-verify ../ssl/chain-of-trust/cert1.pem ../ssl/chain-of-trust/cert2.pem
> ```

The script will examine the certificate for embedded Signed Certificate Timestamps (SCTs), identify which Certificate Transparency logs issued them, request the certificate entry from the log, verify the cryptographic proofs, and report the results. This verification demonstrates the same process that browsers use to ensure certificates have been properly logged before being trusted for secure connections.

## How verification works

To verify that a certificate has been properly logged in a Certificate Transparency (CT) log, a multi-step cryptographic verification process is used:
1. **Log Identification:** Each Signed Certificate Timestamp (SCT) in a certificate contains a Log ID that uniquely identifies which CT log issued it. This Log ID is used to locate the log server's API endpoints.
2. **Fetching the Signed Tree Head (STH):** The verifier requests the log's current Signed Tree Head, which contains:
    - The current size of the log (number of entries)
    - A timestamp
    - The cryptographic root hash of the Merkle Tree
    - A digital signature from the log
3. **Creating a Leaf Hash:** The verifier constructs a `leaf hash` by:
    - Reconstructing what the precertificate would have been. This contains the TBS section (to be signed) section of the certificate with the SCTs removed.
    - Formatting this data as a MerkleTreeLeaf structure
    - Hashing this data using the log's specified hash algorithm (typically SHA-256)
4. **Requesting Inclusion Proofs:** The verifier sends the leaf hash to the log server's `get-proof-by-hash` endpoint, which returns a cryptographic proof (a series of hashes) showing where and how the certificate is included in the Merkle Tree.
5. **Verification:** Using the leaf hash and the returned proof hashes, the verifier can mathematically compute what the root hash should be. If this calculated root hash matches the one in the Signed Tree Head, it proves the certificate is included in the log.


## Exercise: Find a Log Server URL

To locate which Certificate Transparency log issued a particular SCT, you need to convert the Log ID from the certificate into the format used in [Google's official CT log list](https://www.gstatic.com/ct/log_list/v3/all_logs_list.json).

**Step 1: Extract the Log ID from a certificate**

First, examine the certificate to find the Log ID embedded in its SCTs:

```bash
openssl x509 -in ssl/chain-of-trust/cert1.pem -noout -text
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

## Next section

[CT Log Servers](./ct_log_servers.md)
