# Certificate Chain of Trust

Return [home](../README.md)

The Certificate Chain of Trust in modern PKI systems employs a tiered architecture where trust flows downward from a highly-secured offline root Certificate Authority (CA), through one or more intermediate CAs, and finally to the end-entity certificates that secure websites and services. This hierarchical design strategically isolates the root CA's critical private key from online threats while still extending its authority through a verifiable chain of digital signatures, enabling browsers and clients to validate server certificates by tracing their lineage back to a trusted root.

When examining certificates from production websites, this chain structure becomes evident as each certificate references its issuer, creating an unbroken path of trust from the server certificate through intermediaries to a root CA that's pre-installed in client trust stores.

This section guides you through retrieving certificates from live websites, analyzing their structure and properties, and understanding how production certificates differ from the simpler examples created in previous exercises. You'll learn to extract certificates using OpenSSL's s_client, inspect detailed certificate extensions, and compare different certificates in a certificate chain to understand trust relationships in real-world deployments. Finally we'll try to recreate those certificates.

## Download certificates

This command establishes a secure TLS connection to the domain on port 443 using OpenSSL's `s_client` tool with the `-showcerts` flag, which displays the complete certificate chain presented by the server. The connection is fed an empty input from `/dev/null` to prevent the command from hanging; and then exports each certificate to it's own file by identifying where the certificates begin and end:
```bash
openssl s_client -showcerts -connect domain:443 </dev/null | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="ssl/chain-of-trust/cert"a".pem"; print >out}'
```

**Check the subject and issuer:**
```bash
openssl x509 -in ssl/chain-of-trust/cert1.pem -noout -subject -issuer
openssl x509 -in ssl/chain-of-trust/cert2.pem -noout -subject -issuer
openssl x509 -in ssl/chain-of-trust/cert3.pem -noout -subject -issuer
```

**Compare certificate purposes:**
```bash
openssl x509 -in ssl/chain-of-trust/cert1.pem -noout -purpose > ssl/chain-of-trust/cert1.purpose.txt
openssl x509 -in ssl/chain-of-trust/cert2.pem -noout -purpose > ssl/chain-of-trust/cert2.purpose.txt
openssl x509 -in ssl/chain-of-trust/cert3.pem -noout -purpose > ssl/chain-of-trust/cert3.purpose.txt

diff --color=always --side-by-side ssl/chain-of-trust/cert1.purpose.txt ssl/chain-of-trust/cert2.purpose.txt
git diff --no-index --word-diff ssl/chain-of-trust/cert1.purpose.txt ssl/chain-of-trust/cert2.purpose.txt

diff --color=always --side-by-side ssl/chain-of-trust/cert2.purpose.txt ssl/chain-of-trust/cert3.purpose.txt
git diff --no-index --word-diff ssl/chain-of-trust/cert2.purpose.txt ssl/chain-of-trust/cert3.purpose.txt
```

**Compare certificate dates:**
```bash
openssl x509 -in ssl/chain-of-trust/cert1.pem -noout -dates
openssl x509 -in ssl/chain-of-trust/cert2.pem -noout -dates
openssl x509 -in ssl/chain-of-trust/cert3.pem -noout -dates
```

**Verify certificates:**

The intermediate certificate can be validated against the root certificate authority:
```bash
openssl verify -CAfile ssl/chain-of-trust/cert3.pem ssl/chain-of-trust/cert2.pem
```

To validate certificate one however, the intermediate certificate and the root certificate need to be bundled:
```bash
cat ssl/chain-of-trust/cert3.pem ssl/chain-of-trust/cert2.pem > ssl/chain-of-trust/certs-bundle.pem

openssl verify -CAfile ssl/chain-of-trust/certs-bundle.pem ssl/chain-of-trust/cert1.pem
```


## Recreate certificates

This exercise involves trying to recreate all three certificates with identical details. To verify whether your certificate matches, we will use a diff tool to identify what is similar or different. Start with the root CA as that's needed to create the intermediate certificate, and finally the server's certificate.

> Note: you won't be able to match the public key or the signature value using your own private keys.

Config files:
 - [CA config](../ssl/chain-of-trust/ca.cnf)
 - [Intermediate config](../ssl/chain-of-trust/intermediate.cnf)
 - [Server config](../ssl/chain-of-trust/server.cnf)

Create script:
```bash
./scripts/create.sh
```

Compare the certificates:
```bash
# Compare the root CA
diff --color=always --side-by-side ssl/chain-of-trust/cert3.pem.txt ssl/chain-of-trust/ca.pem.txt
git diff --no-index --word-diff ssl/chain-of-trust/cert3.pem.txt ssl/chain-of-trust/ca.pem.txt

# Compare the intermediate certificate
diff --color=always --side-by-side ssl/chain-of-trust/cert2.pem.txt ssl/chain-of-trust/intermediate.pem.txt
git diff --no-index --word-diff ssl/chain-of-trust/cert2.pem.txt ssl/chain-of-trust/intermediate.pem.txt

# Compare the server certificate
diff --color=always --side-by-side ssl/chain-of-trust/cert1.pem.txt ssl/chain-of-trust/server.pem.txt
git diff --no-index --word-diff ssl/chain-of-trust/cert1.pem.txt ssl/chain-of-trust/server.pem.txt
```

### Certificate script

Update the config files and `create.sh` script to reconstruct the three-tier certificate hierarchy we examined. Your goal is to match the original certificates as closely as possible, focusing on matching the subject names, extensions, validity periods, and other metadata. You might not be able to match the signature and keys (public key, subject key identifier, and authority key identifier) as we're using different keys. While most details can be updated through the config files, you might need to pass different parameters into the commands within the create script.

When you've completed your certificate chain, verify its validity:

```bash
# Verify intermediate against root
openssl verify -CAfile ssl/chain-of-trust/ca.pem ssl/chain-of-trust/intermediate.pem

# Create a bundle and verify server certificate
cat ssl/chain-of-trust/ca.pem ssl/chain-of-trust/intermediate.pem > ssl/chain-of-trust/bundle.pem
openssl verify -CAfile ssl/chain-of-trust/bundle.pem ssl/chain-of-trust/server.pem
```

## Next section

[Certificate Transparency Logs](./certificate-transparency-logs.md)
