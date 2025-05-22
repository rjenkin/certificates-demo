# Certificates Notes

## Prerequisite info

### Commands

#### Base64 encoding/decoding

Base64 encode string:
```bash
echo -n "abc" | base64
```

Base64 decode string:
```bash
echo -n "YWJj" | base64 -d
```

#### Binary data

Hex dump tool for working with binary data

Converts escaped hex bytes to binary:
```bash
echo -e -n "\x30\x59\x30\x13" | xxd
```

Group bytes:
```bash
echo -e -n "\x30\x59\x30\x13" | xxd -groupsize 2
```

View binary data, one byte per line, with location:
```bash
echo -e -n "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11" | xxd -cols 1
```

View binary data, one byte per line, with location in decimal:
```bash
echo -e -n "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11" | xxd -cols 1 --decimal
```

View binary data, one byte per line, without location:
```bash
echo -e -n "\x30\x59\x30\x13" | xxd -cols 1 -plain
```

View smaller set of binary data with skip and length:
```bash
echo -e -n "\x30\x59\x30\x13" | xxd -cols 1 -seek 1 -len 2
```

Convert hex encoded data to binary:
```bash
echo -n "30593013" | xxd -revert -plain | xxd -groupsize 1
```

#### JSON data

Command-line JSON processor

Access "name" value:
```bash
echo '{"name":"value","array":[1,2,3],"nested":{"nested1":1,"nested2":2}}' | jq '.name'
```

Access the raw value value:
```bash
echo '{"name":"value","array":[1,2,3],"nested":{"nested1":1,"nested2":2}}' | jq --raw-output '.name'
```

Access an array index:
```bash
echo '{"name":"value","array":[1,2,3],"nested":{"nested1":1,"nested2":2}}' | jq '.array[1]'
```

Access a nested value:
```bash
echo '{"name":"value","array":[1,2,3],"nested":{"nested1":1,"nested2":2}}' | jq '.nested.nested2'
```

#### Curl

```bash
cat > submission.json <<EOF
{
"chain": [
    "${CA_CERT_DER_BASE64}",
    "${PRE_CERT_DER_BASE64}"
]
}
EOF
```

```bash
curl --include -X POST \
-H "Content-Type: application/json" \
--data @submission.json \
http://localhost:8080/testlog/ct/v1/add-pre-chain
```


### Formats

### PEM

Base64 version of DER wrapped with:
```text
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

View the details of a PEM certificate:
```bash
openssl x509 -in cert1.pem -text -noout | head --lines 5
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            79:d8:16:d9:c1:f8:5c:2c:34:3b:d6:55:ae:e3:e9:78
```

### DER

DER stands for Distinguished Encoding Rules. It’s a binary format used to encode data structures described by ASN.1 (Abstract Syntax Notation One), which is a standard used in cryptographic systems, especially for certificates.

Convert a PEM certificate to DER format:
```bash
openssl x509 -in cert1.pem -outform DER | xxd -cols 1 -seek 0 -len 31
```

### Abstract Syntax Notation One (ASN.1)

Abstract Syntax Notation One (ASN.1) is a standard interface description language (IDL) for defining data structures that can be serialized and deserialized in a cross-platform way. It is broadly used in telecommunications and computer networking, and especially in cryptography.

```bash
openssl asn1parse -in cert1.pem | head --lines 5
    0:d=0  hl=4 l=1820 cons: SEQUENCE          
    4:d=1  hl=4 l=1540 cons: SEQUENCE          
    8:d=2  hl=2 l=   3 cons: cont [ 0 ]        
   10:d=3  hl=2 l=   1 prim: INTEGER           :02
   13:d=2  hl=2 l=  16 prim: INTEGER           :79D816D9C1F85C2C343BD655AEE3E978
```

In the above output: at byte offset 0 the depth is 0 (top level). The tag and length use 4 bytes. It's type is a SEQUENCE which is 1,820 bytes long. The type is constructed, rather than primitive, meaning it contains nested fields.

[ASN.1 Tags](https://letsencrypt.org/docs/a-warm-welcome-to-asn1-and-der/#tag)

[Length](https://letsencrypt.org/docs/a-warm-welcome-to-asn1-and-der/#length)

The encoding of length can take two forms: short or long.
- The short form is a single byte, between 0 and 127.
- The long form is at least two bytes long, and has bit 8 of the first byte set to 1. Bits 7-1 of the first byte indicate how many more bytes are in the length field itself. Then the remaining bytes specify the length itself, as a multi-byte integer.

```text
00000000: 30  0
00000001: 82  .
00000002: 07  .
00000003: 1c  .
00000004: 30  0
00000005: 82  .
00000006: 06  .
00000007: 04  .
00000008: a0  .
00000009: 03  .
0000000a: 02  .
0000000b: 01  .
0000000c: 02  .
0000000d: 02  .
0000000e: 10  .
0000000f: 79  y
00000010: d8  .
00000011: 16  .
00000012: d9  .
00000013: c1  .
00000014: f8  .
00000015: 5c  \
00000016: 2c  ,
00000017: 34  4
00000018: 3b  ;
00000019: d6  .
0000001a: 55  U
0000001b: ae  .
0000001c: e3  .
0000001d: e9  .
0000001e: 78  x
```

More info https://www.cryptologie.net/article/262/what-are-x509-certificates-rfc-asn1-der/


## Setup

**Start docker:**
```bash
docker-compose up -d
```

**Test docker (HTTP):**
```bash
curl http://localhost:10000/

curl -H 'Host: server-one' http://localhost:10000/

curl -H 'Host: server-two' http://localhost:10000/

curl --resolve server-one:10000:127.0.0.1 http://server-one:10000/

curl --resolve server-two:10000:127.0.0.1 http://server-two:10000/
```

## Diagram

![Diagram](./docs/diagram.png)


## 1. Self-signed certificates

Create a self-signed certificate for the server.

### Private key

**Create the key:**
```bash
openssl genrsa -out docker/ssl/selfsigned.key 2048
```

**Check the details of the key:**
```bash
openssl pkey -in docker/ssl/selfsigned.key -text -noout

openssl asn1parse -in docker/ssl/selfsigned.key

openssl rsa -in docker/ssl/selfsigned.key -outform DER | xxd -c 1 -s 0 -l 30 --decimal
** writing RSA key??
```

### Certificate signing request

**Create the Certificate Signing Request:**
```bash
openssl req -new \
-key docker/ssl/selfsigned.key \
-config docker/ssl/selfsigned.cnf \
-out docker/ssl/selfsigned.csr
```

**View the signing request:**
```bash
openssl req -in docker/ssl/selfsigned.csr -text -noout

openssl asn1parse -in docker/ssl/selfsigned.csr
```

**Read the details of the Certificate Signing Request:**
```bash
openssl req -in docker/ssl/selfsigned.csr -text -noout
```

### Create the certificate

**Create the certificate:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/selfsigned.csr \
-signkey docker/ssl/selfsigned.key \
-out docker/ssl/selfsigned.crt \
-extfile docker/ssl/selfsigned.cnf
```

**Read details of the certificate:**
```bash
openssl x509 -in docker/ssl/selfsigned.crt -text -noout
```

**Compare the signing request to the certificate:**
```bash
openssl req -in docker/ssl/selfsigned.csr -text -noout > selfsigned.csr.text

openssl x509 -in docker/ssl/selfsigned.crt -text -noout > selfsigned.crt.text

diff --color=always --side-by-side selfsigned.csr.text selfsigned.crt.text
```

### Testing the certificate

**Enable SSL in nginx:**

Update the [nginx config](./docker/nginx.conf) and restart the container:
```
server {
    listen 80 ssl;
    server_name server-one;

    ssl_certificate     /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    ....
}
```

**Make a HTTPs request to the server:**
```bash
curl --resolve server-one:10000:127.0.0.1 https://server-one:10000/
```

*This should return an untrusted certificate error*

**Ignore error (not recommended):**
```bash
curl --resolve server-one:10000:127.0.0.1 https://server-one:10000/ --insecure
```

**Request with certificate:**
```bash
curl --cacert docker/ssl/selfsigned.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000/
```

**Request on different domain name:**
```bash
curl --cacert docker/ssl/selfsigned.crt https://localhost:10000/

curl --cacert docker/ssl/selfsigned.crt --resolve server-two:10000:127.0.0.1 https://server-two:10000/
```

### Subject Name Alternatives

Include the Subject Name Alternatives into [config](./docker/ssl/selfsigned-2.cnf)

**Create the Certificate Signing Request:**
```bash
openssl req -new \
-key docker/ssl/selfsigned.key \
-out docker/ssl/selfsigned.csr \
-config docker/ssl/selfsigned-2.cnf
```

**Read the details of the Certificate Signing Request:**
```bash
openssl req -in docker/ssl/selfsigned.csr -text -noout > selfsigned.csr.text
```

**Create the certificate:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/selfsigned.csr \
-signkey docker/ssl/selfsigned.key \
-out docker/ssl/selfsigned.crt \
-extensions req_ext \
-extfile docker/ssl/selfsigned-2.cnf
```

**Read details of the certificate:**
```bash
openssl x509 -in docker/ssl/selfsigned.crt -text -noout > selfsigned.crt.text
```

**Testing the new certificate:**
```bash
curl --cacert docker/ssl/selfsigned.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000

curl --cacert docker/ssl/selfsigned.crt -H 'Host: server-one' https://localhost:10000/ 
```


## 2. Certificate Authority

Using a custom Certificate Authority (CA) for local development simplifies security by requiring you to trust just one root certificate instead of multiple self-signed ones. Once your system trusts your local CA, you can easily generate and use certificates for any number of development services without additional trust configuration, creating a more realistic and streamlined secure development environment.

### Create the certificate authority

**Create the private key:**
```bash
openssl genrsa -out docker/ssl/ca.key 4096
```

**Create the certificate:**
```bash
openssl req -new \
-x509 \
-days 3650 \
-key docker/ssl/ca.key \
-out docker/ssl/ca.crt \
-config docker/ssl/ca.cnf \
-extensions req_ext
```

### Create the server certificates

**Create a private key:**
```bash
openssl genrsa -out docker/ssl/servers.key 2048
```

**Create the Certificate Signing Request:**
```bash
openssl req -new \
-key docker/ssl/servers.key \
-out docker/ssl/server-one.csr \
-config docker/ssl/server-one.cnf

openssl req -new \
-key docker/ssl/servers.key \
-out docker/ssl/server-two.csr \
-config docker/ssl/server-two.cnf
```

**Create the certificates with the Certificate Authority:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/server-one.csr \
-CA docker/ssl/ca.crt \
-CAkey docker/ssl/ca.key \
-CAcreateserial \
-out docker/ssl/server-one.crt \
-extensions req_ext \
-extfile docker/ssl/server-one.cnf

openssl x509 -req \
-days 365 \
-in docker/ssl/server-two.csr \
-CA docker/ssl/ca.crt \
-CAkey docker/ssl/ca.key \
-CAcreateserial \
-out docker/ssl/server-two.crt \
-extensions req_ext \
-extfile docker/ssl/server-two.cnf
```

### Testing the certificates

**Enable SSL in nginx:**

Update both servers in [nginx config](./docker/nginx.conf) to use certificates `server-one.crt` and `server-two.crt` and restart the container:

**Make a HTTPs request to the server using the CA certificate:**
```bash
curl --cacert docker/ssl/ca.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000

curl --cacert docker/ssl/ca.crt --resolve server-two:10000:127.0.0.1 https://server-two:10000

curl --cacert docker/ssl/ca.crt -H 'Host: server-one' https://localhost:10000/ 

curl --cacert docker/ssl/ca.crt -H 'Host: server-two' https://localhost:10000/ 
```

### Verify the Certificate authority

Verify that a certificate was signed by an authority:
```bash
openssl verify -CAfile docker/ssl/ca.crt docker/ssl/server-one.crt 
```

## 3. Examining and Recreating Live Certificates

This exercises involves examining existing certificates installed on an endpoint, and then recreating the certificate details. Real world certificates include many additional parameters to the certificates created in the exercises above, such as key usage, certificate polcies, etc.

Reference the [certificate extension configuration format docs](https://docs.openssl.org/3.4/man5/x509v3_config/) and check openssl options with `openssl req --help`.

For certificate transparency logs, additional steps may be required. Before creating the final certificate, a precertificate is created which is sent to a certificate transparency log server and that returns a value, which is used to create the final certificate. 


## Examine existing certificates

This command checks the certificates installed on the endpoint, and saves each to disk. The `</dev/null` is required to close the connection.

**Download an existing certificate:**
```bash
openssl s_client -showcerts -connect 108.158.32.39:443 -servername commbank.com.au </dev/null | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".pem"; print >out}'
```

**OpenSSL commands to examine certificates:**
```bash
# List all commands
openssl x509 --help

# Certificate purpose
openssl x509 -in cert1.pem -noout -purpose
openssl x509 -in cert2.pem -noout -purpose
openssl x509 -in cert3.pem -noout -purpose

# Issuer
openssl x509 -in cert1.pem -noout -issuer
openssl x509 -in cert2.pem -noout -issuer
openssl x509 -in cert3.pem -noout -issuer

# Subject
openssl x509 -in cert1.pem -noout -subject
openssl x509 -in cert1.pem -noout -subject -nameopt RFC2253
openssl x509 -in cert1.pem -noout -subject -nameopt oneline
openssl x509 -in cert1.pem -noout -subject -nameopt multiline
openssl x509 -in cert1.pem -noout -subject -nameopt esc_2253
openssl x509 -in cert1.pem -noout -subject -nameopt utf8
openssl x509 -in cert1.pem -noout -subject -nameopt sep_comma_plus
openssl x509 -in cert1.pem -noout -subject -nameopt dn_rev

# Dates
openssl x509 -in cert1.pem -noout -dates
openssl x509 -in cert1.pem -noout -startdate
openssl x509 -in cert1.pem -noout -enddate
openssl x509 -in cert1.pem -noout -dates -dateopt iso_8601

# Check hosts
openssl x509 -in cert1.pem -noout -checkhost example.com

# Check subject name alternatives
openssl x509 -in cert1.pem -noout -ext subjectAltName

# Others
openssl x509 -in cert1.pem -noout -ext keyUsage
openssl x509 -in cert1.pem -noout -ext extendedKeyUsage
openssl x509 -in cert1.pem -noout -ext basicConstraints
openssl x509 -in cert1.pem -noout -ext certificatePolicies
openssl x509 -in cert1.pem -noout -ext subjectKeyIdentifier
openssl x509 -in cert1.pem -noout -ext authorityKeyIdentifier
openssl x509 -in cert1.pem -noout -ext crlDistributionPoints
openssl x509 -in cert1.pem -noout -ext authorityInfoAccess
openssl x509 -in cert1.pem -noout -fingerprint

# Multiple options
openssl x509 -in cert1.pem -noout -ext subjectAltName,keyUsage
```

**Export the details to a text file:**
```bash
openssl x509 -in cert1.pem -text -noout > cert1.pem.text

openssl x509 -in cert2.pem -text -noout > cert2.pem.text

openssl x509 -in cert3.pem -text -noout > cert3.pem.text
```

**Stage in Git:**

Stage the file in git so that when we generate our own certificate, we can see what is similar or different

```bash
git add cert1.pem.text

git add cert2.pem.text

git add cert3.pem.text
```

**Verify certificates:**

Check cert3 against cert2:
```bash
openssl verify -CAfile cert3.pem cert2.pem
```

Bundle cert3 and cert2:
```bash
cat cert3.pem cert2.pem > bundle.pem
```

Verify cert1:
```bash
openssl verify -CAfile bundle.pem cert1.pem
```

**Exercise: Create a script to recreate a certificate:**

Create a bash script to generate a certificate authority and a certificate, then export to the text file
above. Modify the certificate config files and commands to reduce the number of differences between your
certificate and the original downloaded.

```bash
./scripts/...
```


## Certificate Transparency Logs

Certificate Transparency logs help protect end users by making it possible to detect and fix fraudulent or
mistakenly issued website security certificates, reducing the risk of impersonation or malicious websites.


**View existing SCT data:**

Extract SCT from existing certificate:
```bash
./scripts/extract.sh
```

Examine with: `xxd -c 1 sct_raw.bin > sct_debug.txt`

```bash
# This extracts the data in ASN.1 format (RFC 6962).
# Examine with: `xxd -c 1 sct_raw.bin > sct_debug.txt`

# First byte is the type: 0x04 is octet string: https://www.oss.com/asn1/resources/asn1-made-simple/asn1-quick-reference.html

# Second byte:
# If most significant bit is 0, this value contains the length and can be 0-127; i.e 7F = 127 (0111 1111)
# If most signficant bit is 1, the remaining 7 bytes say how many bytes store the number:
# 0x82 = 1000 0010; 10 binary = 2 decimal; so the next two bytes contain the length


00000000: 04  . # OCTET STRING
00000001: 82  . # Most significant bit is 1, so this indicates how many bytes store length; which is 2
00000002: 01  . # Length: 0x16b = 363.
00000003: 6b  k # 

# This is what is included in the CSR
00000004: 01  . # 0x169 = 361
00000005: 69  i

00000006: 00  . # Length: 
00000007: 76  v # Length: 7d - 8 = 75; 118 decimal
00000008: 00  . # Version?
00000009: e6  . # Start of Log ID 1
0000000a: d2  .
0000000b: 31  1
0000000c: 63  c
```


[View Logs](https://www.gstatic.com/ct/log_list/v3/all_logs_list.json)


**Find the log that stores a certificate entry:**

The certificate contains a hex encoded Log ID while the JSON list above has base64 encoded


### Log server endpoints

The log entry contain a base URL for a series of endpoint required to verify a certificate.

**Get roots:**

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
            39:0d:19:f5:ed:02:c4:59:e5:10:ec:3b:90:de:f8:93:c4:4c:4e:39

```

**Signed Head Tree:**

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




**Get entries:**
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

View a MerkleTreeLeaf:

```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=9" | jq -r ".entries[0].leaf_input" | base64 -d | xxd
```

MerkelTreeLeaf structure:
```c
struct {
    Version version;
    MerkleLeafType leaf_type;
    TimestampedEntry leaf_input;
} MerkleTreeLeaf;

struct {
    uint64 timestamp;
    LogEntryType entry_type;
    select(entry_type) {
        case x509_entry: ASN.1Cert;
        case precert_entry: PreCert;
    } signed_entry;
    CtExtensions extensions;
} TimestampedEntry;
```

Bytes:
- 1 byte for version,
- 1 byte for leaf type
- 8 bytes for timestamp
- 2 bytes for entry type
- 32 bytes for issuer key hash
- 3 bytes for TBS length
- TBS data
- 2 bytes for SCT extensions length
- SCT extensions bytes




Extract the timestamp from the leaf data:

```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r ".entries[0].extra_data" | base64 -d | xxd -c 1 -l 10
```

```c
struct {
    ASN.1Cert leaf_certificate;
    ASN.1Cert certificate_chain<0..2^24-1>;
}
```

Bytes:
- 0,1,2 bytes indicate the length
- 3,4,5 bytes indicate the first certificate (1774)
- 6th byte is start of certificate with 0x30
- 7th is length, i.e 0x82 = next two bytes indicate length
- 8-9th: length (1770)


```bash
# Reads the certificate. Note: skipping first 3 bytes which indicate length, and the count was calculated by looking at the output with the command above.
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-entries?start=0&end=0" | jq -r '.entries[0].extra_data' | base64 -d | dd bs=1 skip=6 count=1774 2>/dev/null | openssl x509 -inform DER -text -noout
```




**Get entry and proof:**

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


**Get proof by hash:**

How to get the hash?
Remove the SCT data from the certificate, becomes the TBS Certificate, create a Merkle Tree Leaf, the create a hash and base 64 encode it


Remove the SCT extension from the certificate (1.3.6.1.4.1.11129.2.4.2)

```bash
curl --silent "https://nessie2025.ct.digicert.com/log/ct/v1/get-proof-by-hash?tree_size=55&hash=..hash.."
```

Response:
```
{
  leaf_index: 59781451,
  audit_path: [
    '...base64 encoded...',
    '...base64 encoded...',
    '...base64 encoded...'
  ]
}
```

Validate by calculating the root hash using the proof and leaf, and compare that against the signed tree head's sha256_root_hash.


**Start local log server:**

Start the log server:
```bash
./scripts/ctfe.sh
```

Note: Add root CA and restart ctfe



**Adding precertificate to the chain:**

To get the Signed Certificate Timestamp into your final certificate, you need to upload a precertificate. A precertificate is identical to the final certificate except that it contains a CT Poison extension (1.3.6.1.4.1.11129.2.4.3 = critical,ASN1:NULL) and the final certificate contains the Signed Certificate Timestamp list (1.3.6.1.4.1.11129.2.4.5 = ASN1:FORMAT:HEX,OCTETSTRING:...).

```bash
curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d '{"chain":["Base64 encoded DER (precert)", "Base64 encoded DER (CA)"]}' \
  https://nessie2025.ct.digicert.com/log/ct/v1/add-pre-chain
```

Response:
```json
{
  "sct_version": 0,
  "id": "jzsf74xD/iFFMEsi9GK0xKM8DIRLaWXmt0Fb8ho9Jw0=",
  "timestamp": 1747266466681,
  "extensions": "",
  "signature": "BAMARzBFAiEAs2ZUwqWrOYHxTsxIBngcUYEci4Wt/x7XJ/Q4gvL4UhICIHIJyiGCf61E5WIHvl+bk70695JzgKqS57+hrWym6iBC"
}
```

Debug the JSON:
```bash
echo -n "BAMARzBFAiEAs2ZUwqWrOYHxTsxIBngcUYEci4Wt/x7XJ/Q4gvL4UhICIHIJyiGCf61E5WIHvl+bk70695JzgKqS57+hrWym6iBC" | base64 -d | xxd -c 1
```

https://datatracker.ietf.org/doc/html/rfc5246#page-46
```c
enum {
    none(0), md5(1), sha1(2), sha224(3), sha256(4), sha384(5),
    sha512(6), (255)
} HashAlgorithm;

enum { anonymous(0), rsa(1), dsa(2), ecdsa(3), (255) }
  SignatureAlgorithm;

struct {
      HashAlgorithm hash;
      SignatureAlgorithm signature;
} SignatureAndHashAlgorithm;
```

Bytes:
- 1 Hash
- 2 Signature
- 3-4 Length
- 4 Sequence
- 5 Length
- 6 Int
- 7 Int length

```bash
# Examine the SCT response:
jq -r '.[0].signature' sct_list.json | base64 -d | xxd -c 1
```

```text
00000000: 04  . # SHA256
00000001: 03  . # ECDSA
00000002: 00  . # Length
00000003: 47  G # Length
00000004: 30  0 # Sequence
00000005: 45  E # 69

00000006: 02  . # Int
00000007: 21  ! 33

00000008: 00  .
00000009: b3  .
00000010: 66  f
00000011: 54  T
00000012: c2  .
00000013: a5  .
00000014: ab  .
00000015: 39  9
00000016: 81  .
00000017: f1  .
00000018: 4e  N
00000019: cc  .
00000020: 48  H
00000021: 06  .
00000022: 78  x
00000023: 1c  .
00000024: 51  Q
00000025: 81  .
00000026: 1c  .
00000027: 8b  .
00000028: 85  .
00000029: ad  .
00000030: ff  .
00000031: 1e  .
00000032: d7  .
00000033: 27  '
00000034: f4  .
00000035: 38  8
00000036: 82  .
00000037: f2  .
00000038: f8  .
00000039: 52  R
00000040: 12  .

00000041: 02  . # Int
00000042: 20    # 32
00000043: 72  r
00000044: 09  .
00000045: ca  .
00000046: 21  !
00000047: 82  .
00000048: 7f  .
00000049: ad  .
00000050: 44  D
00000051: e5  .
00000052: 62  b
00000053: 07  .
00000054: be  .
00000055: 5f  _
00000056: 9b  .
00000057: 93  .
00000058: bd  .
00000059: 3a  :
00000060: f7  .
00000061: 92  .
00000062: 73  s
00000063: 80  .
00000064: aa  .
00000065: 92  .
00000066: e7  .
00000067: bf  .
00000068: a1  .
00000069: ad  .
00000070: 6c  l
00000071: a6  .
00000072: ea  .
00000073: 20   
00000074: 42  B
```

**Encoding the SCT:**



Adding final certificate to the chain:

```bash
curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d '{"chain":["Base64 encoded DER (final cert)", "Base64 encoded DER (CA)"]}' \
  https://nessie2025.ct.digicert.com/log/ct/v1/add-chain
```


**Get Signed Tree Head consistency:**
```bash
curl --silent "http://localhost:8080/testlog/ct/v1/get-sth-consistency?first=0&second=1" | jq .
{
  "consistency": [
    "..hash..",
    "..hash.."
  ]
}
```

**Verify your certificate exists in the log server:**




Endpoints:


```
# Other test commands:
# curl http://localhost:8091/healthz
# curl http://localhost:8091/metrics

# curl http://localhost:8080/metrics

# AddChainPath          = POST "/ct/v1/add-chain"
# AddPreChainPath       = POST "/ct/v1/add-pre-chain"
# GetSTHPath            = GET  "/ct/v1/get-sth"
# GetEntriesPath        = GET  "/ct/v1/get-entries"
# GetProofByHashPath    = GET  "/ct/v1/get-proof-by-hash"
# GetSTHConsistencyPath = GET  "/ct/v1/get-sth-consistency"
# GetRootsPath          = GET  "/ct/v1/get-roots"
# GetEntryAndProofPath  = GET  "/ct/v1/get-entry-and-proof" leaf_index: int, tree_size: int
```








Certificate Transparency
https://datatracker.ietf.org/doc/html/rfc6962

Talks about the structure
https://datatracker.ietf.org/doc/html/rfc6962#section-3.3

1.3.6.1.4.1.11129.2.4.2: Precertificate Signed Certificate Timestamps (SCTs) extension
1.3.6.1.4.1.11129.2.4.3: Signed Certificate Timestamps (SCTs) extension. Poisoned?
1.3.6.1.4.1.11129.2.4.5: Signed Certificate Timestamp List TLS extension

The Transport Layer Security (TLS) Protocol Version 1.2
https://datatracker.ietf.org/doc/html/rfc5246

https://letsencrypt.org/2018/04/04/sct-encoding/






<!-- 
Extract SCT from existing certificate:
`./scripts/extract.sh`


Examine with: `xxd -c 1 sct_raw.bin > sct_debug.txt`

```
# This extracts the data in ASN.1 format (RFC 6962).
# Examine with: `xxd -c 1 sct_raw.bin > sct_debug.txt`

# First byte is the type: 0x04 is octet string: https://www.oss.com/asn1/resources/asn1-made-simple/asn1-quick-reference.html

# Second byte:
# If most significant bit is 0, this value contains the length and can be 0-127; i.e 7F = 127 (0111 1111)
# If most signficant bit is 1, the remaining 7 bytes say how many bytes store the number:
# 0x82 = 1000 0010; 10 binary = 2 decimal; so the next two bytes contain the length


00000000: 04  . # OCTET STRING
00000001: 82  . # Most significant bit is 1, so this indicates how many bytes store length; which is 2
00000002: 01  . # Length: 0x16b = 363.
00000003: 6b  k # 

# This is what is included in the CSR
00000004: 01  . # 0x169 = 361
00000005: 69  i

00000006: 00  . # Length: 
00000007: 76  v # Length: 7d - 8 = 75; 118 decimal
00000008: 00  . # Version?
00000009: e6  . # Start of Log ID 1
0000000a: d2  .
0000000b: 31  1
0000000c: 63  c
``` -->

Use sct_decode.py to output json
`pipenv run python sct_encode.py`

Debug the JSON:
`jq -r '.[0].signature' sct_list.json | base64 -d | xxd -c 1`


```
# Examine the SCT response:
# jq -r '.[0].signature' sct_list.json | base64 -d | xxd -c 1

# 00000000: 04  . # SHA256
# 00000001: 03  . # ECDSA
# 00000002: 00  .
# 00000003: 47  G
# 00000004: 30  0
# 00000005: 45  E
# 00000006: 02  .
# 00000007: 21  !
# 00000008: 00  .
# 00000009: b3  .

# hash_names = {
#     0: "none",
#     1: "MD5",
#     2: "SHA1", 
#     3: "SHA224",
#     4: "SHA256",
#     5: "SHA384",
#     6: "SHA512"
# }

# sig_names = {
#     0: "anonymous",
#     1: "RSA",
#     2: "DSA",
#     3: "ECDSA"
# }
```


Use sct.sh to create a precertificate with a poison:
1.3.6.1.4.1.11129.2.4.3 = critical,ASN1:NULL

DER encode and upload to `/ct/v1/add-pre-chain` -> Save the response

```
# Examine the SCT response:
# jq -r '.signature' sct_response.json | base64 -d | xxd -c 1 -l 10

# 00000000: 04  . # SHA256
# 00000001: 03  . # ECDSA
# 00000002: 00  .
# 00000003: 47  G
# 00000004: 30  0
# 00000005: 45  E
# 00000006: 02  .
# 00000007: 21  !
# 00000008: 00  .
# 00000009: b3  .

# hash_names = {
#     0: "none",
#     1: "MD5",
#     2: "SHA1", 
#     3: "SHA224",
#     4: "SHA256",
#     5: "SHA384",
#     6: "SHA512"
# }

# sig_names = {
#     0: "anonymous",
#     1: "RSA",
#     2: "DSA",
#     3: "ECDSA"
# }
```

Use sct_encode.py to add logs into CSR for final certicate

Upload to add-chain

Verify final certificate contains the logs









curl --silent 'http://localhost:8080/testlog/ct/v1/get-proof-by-hash?tree_size=55&hash=6a0259179db6a7ab979ecf8f0050ca45f5fdb8f44ad' | jq .


go run github.com/google/certificate-transparency-go/client/ctclient get-proof \
  --log_uri http://localhost:8080/testlog \
  --cert final.crt







## Other tools:

### Certigo

Certigo is a utility to examine and validate certificates to help with debugging SSL/TLS issues.

Install certigo with:
```bash
brew install certigo
```

Inspect live certificates:
```bash
certigo connect google.com:443

certigo connect google.com:443 --verbose

certigo connect google.com:443 --pem

certigo connect --verbose commbank.com.au:443 --json | jq .
```

Inspect certificate on disk:
```bash
certigo dump cert1.pem --verbose
```


### ZLint

ZLint is a X.509 certificate linter written in Go that checks for consistency with standards (e.g. RFC 5280) and other relevant PKI requirements (e.g. CA/Browser Forum Baseline Requirements).

Usage:
```bash
$ zlint cert1.pem | jq .
{
  "e_aia_ca_issuers_must_have_http_only": {
    "result": "pass"
  },
  "e_aia_must_contain_permitted_access_method": {
    "result": "pass"
  },
  "e_aia_ocsp_must_have_http_only": {
    "result": "pass"
  },
  "e_aia_unique_access_locations": {
    "result": "pass"
  },
  "e_algorithm_identifier_improper_encoding": {
    "result": "pass"
  },
  "e_authority_key_identifier_correct": {
    "result": "NA"
  },
  "e_basic_constraints_not_critical": {
    "result": "NA"
  },
  "e_empty_sct_list": {
    "result": "pass"
  },
    ...
  "w_tls_server_cert_valid_time_longer_than_397_days": {
    "result": "pass"
  }
}
```

Check certificate transparency details:
```bash
zlint ../../cert1.pem | jq '{e_empty_sct_list: .e_empty_sct_list,e_scts_missing: .e_scts_missing,e_embedded_sct_not_enough_for_issuance: .e_embedded_sct_not_enough_for_issuance, e_precert_with_sct_list: .e_precert_with_sct_list,w_ct_sct_policy_count_unsatisfied: .w_ct_sct_policy_count_unsatisfied}'
```


### GRP Curl

grpcurl is a command-line tool that lets you interact with gRPC servers. It's basically curl for gRPC servers.

Usage:
```bash
% grpcurl -plaintext localhost:8090 list
grpc.reflection.v1.ServerReflection
grpc.reflection.v1alpha.ServerReflection
trillian.TrillianAdmin
trillian.TrillianLog

% grpcurl -plaintext localhost:8090 list trillian.TrillianLog
trillian.TrillianLog.AddSequencedLeaves
trillian.TrillianLog.GetConsistencyProof
trillian.TrillianLog.GetEntryAndProof
trillian.TrillianLog.GetInclusionProof
trillian.TrillianLog.GetInclusionProofByHash
trillian.TrillianLog.GetLatestSignedLogRoot
trillian.TrillianLog.GetLeavesByRange
trillian.TrillianLog.InitLog
trillian.TrillianLog.QueueLeaf
```











