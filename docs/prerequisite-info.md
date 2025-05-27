# Prerequisite information

This section serves as a foundational reference guide, introducing essential command-line tools and data formats commonly used when working with digital certificates. It provides practical examples for manipulating and inspecting certificate-related data, including Base64 encoding/decoding, binary data examination with xxd, JSON processing with jq, and making HTTP requests with curl. Additionally, it covers the critical certificate formats (PEM, DER) and explains Abstract Syntax Notation One (ASN.1) encoding—the underlying structure of digital certificates. These commands and format explanations form the technical toolbox you'll need throughout the certificate exercises, allowing you to decode, inspect, and modify certificate data with confidence.

## Commands

### Base64 encoding/decoding

Base64 encoding is often used to convert binary data into ASCII text format, ensuring safe transmission through text-based protocols that may not properly handle non-printable characters.

**Base64 encode string:**
```bash
echo -n "abc" | base64
```

> Note: Include the -n flag with the echo command to prevent adding a trailing newline character, which would affect the encoded data output.

**Base64 decode string:**
```bash
echo -n "YWJj" | base64 -d
```

### Binary data

`xxd` is a hex dump utility that displays binary data in hexadecimal format for analysis while also providing the capability to convert hex-encoded strings back to their binary representation.

**Convert escaped hex bytes to binary:**
```bash
echo -e -n "\x30\x59\x30\x13" | xxd
```

> Note: the `echo -e` flag enables interpreation of escape character sequences in the string.

**Group bytes:**
```bash
echo -e -n "\x30\x59\x30\x13" | xxd -groupsize 2
```

**View binary data, one byte per line, with offset location:**
```bash
echo -e -n "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11" | xxd -cols 1
```

**View binary data, one byte per line, with offset location in decimal:**
```bash
echo -e -n "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11" | xxd -cols 1 --decimal
```

**View binary data without offset location**:
```bash
echo -e -n "\x30\x59\x30\x13" | xxd -plain
```

**View subset of binary data with skip and length:**
```bash
echo -e -n "\x30\x59\x30\x13" | xxd -cols 1 -seek 1 -len 2
```

**Convert hex string to binary (then back to text for reading):**
```bash
echo -n "30593013" | xxd -revert -plain | xxd
```

### JSON data

API servers commonly return data in JSON format. The jq utility is a powerful command-line JSON processor that allows you to extract, manipulate, and transform specific elements from JSON data structures.

**Access "name" value:**
```bash
echo '{"name":"value"}' | jq '.name'
```

> Note: the returned name is quoted, i.e `"value"`.

**Access the raw value value:**
```bash
echo '{"name":"value"}' | jq --raw-output '.name'
```

> Note: The --raw-output (or -r) option removes the surrounding quotes from string values, which is essential when the output needs to be used as input for other commands or parsed further.

**Find the length of an array:**
```bash
echo '{"array":[1,2,3]}' | jq '.array | length'
```

**Access an array index:**
```bash
echo '{"array":[1,2,3]}' | jq '.array[1]'
```

**Access a nested value:**
```bash
echo '{"nested":{"nested1":1,"nested2":2}}' | jq '.nested.nested2'
```

### Curl

`curl` is a command-line tool for making HTTP requests.

**GET requests:**
```bash
curl https://api.restful-api.dev/objects
```

**Using curl with other commands:**

`curl` output can be piped to utilities like `jq` for JSON processing, enabling you to fetch and transform data in a single command line operation.

```bash
curl https://api.restful-api.dev/objects | jq .
```

> Note: When combining curl with jq, curl displays a progress meter to stderr. This can be disabled with the --silent (or -s) option, though be aware this will also suppress error messages. For more selective silencing, consider using --silent --show-error to keep error reporting.

```bash
curl --silent --show-error https://api.restful-api.dev/objects | jq . 
```

**Querystring parameters:**

When including querystring parameters, the URL needs to be quoted so the special characters (like & and ?) aren't interpreted by the shell. Without quotes, these characters would be processed as command operators rather than part of the URL.

```bash
curl "https://api.restful-api.dev/objects?id=3&id=5&id=10"
```

**POST requests:**

POST requests allow you to send data in the request body, commonly in JSON format. When sending JSON data, you must include appropriate headers (like Content-Type: application/json) to indicate the format of the payload.

```bash
curl -X POST -H "Content-Type: application/json" --data '{"name": "Apple MacBook Pro 16","data": {"year": 2019,"price": 1849.99,"CPU model": "Intel Core i9","Hard disk size": "1 TB"}}' https://api.restful-api.dev/objects
```

When the data becomes quite large, it can be useful to save it to a file and reference that file in your request.

```bash
cat > postdata.json <<EOF
{
   "name": "Apple MacBook Pro 16",
   "data": {
      "year": 2019,
      "price": 1849.99,
      "CPU model": "Intel Core i9",
      "Hard disk size": "1 TB"
   }
}
EOF
```

```bash
curl -X POST -H "Content-Type: application/json" --data @postdata.json https://api.restful-api.dev/objects
```



## Data formats

### PEM

Privacy Enhanced Mail (PEM) is the most common format used to store and distribute SSL certificates, keys, and other cryptographic assets. It represents binary certificate data (in DER format) as a Base64-encoded ASCII text file, making it easy to share via email, text editors, and configuration files. PEM files are readily identifiable by their characteristic header and footer markers, such as `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`. This format is widely supported by cryptographic tools and servers, allowing certificates and keys to be easily viewed, transferred, and imported across different systems and platforms.


**View the details of a PEM certificate:**

```bash
openssl x509 -in submodules/certificate-transparency-go/trillian/testdata/leaf-1.cert -text -noout | head --lines 4
```

Output:
```text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 3735928495 (0xdeadbeaf)
```

### DER

DER stands for Distinguished Encoding Rules. It’s a binary format used to encode data structures described by ASN.1 (Abstract Syntax Notation One), which is a standard used in cryptographic systems, especially for certificates.

Convert a PEM certificate to DER format:
```bash
openssl x509 -in submodules/certificate-transparency-go/trillian/testdata/leaf-1.cert -outform DER | xxd -cols 1 -seek 0 -len 20 --decimal
```

### Abstract Syntax Notation One (ASN.1)

Abstract Syntax Notation One (ASN.1) is a standard interface description language (IDL) for defining data structures that can be serialized and deserialized in a cross-platform way. It is broadly used in telecommunications and computer networking, and especially in cryptography.

```bash
openssl asn1parse -in submodules/certificate-transparency-go/trillian/testdata/leaf-1.cert | head --lines 5
```

Output:
```text
    0:d=0  hl=4 l= 513 cons: SEQUENCE          
    4:d=1  hl=4 l= 422 cons: SEQUENCE          
    8:d=2  hl=2 l=   3 cons: cont [ 0 ]        
   10:d=3  hl=2 l=   1 prim: INTEGER           :02
   13:d=2  hl=2 l=   5 prim: INTEGER           :DEADBEAF
```

In the above output: at offset 0 the depth is 0 (top level). The tag and length use 4 bytes. It's type is a SEQUENCE which is 513 bytes long. The type is constructed, rather than primitive, meaning it contains nested fields.
- [ASN.1 Tags](https://letsencrypt.org/docs/a-warm-welcome-to-asn1-and-der/#tag)
- [Length](https://letsencrypt.org/docs/a-warm-welcome-to-asn1-and-der/#length)

Length can be encoded in two forms: short or long.
- The short form is a single byte, between 0 and 127, with the most significant bit set to 0.
- The long form is at least two bytes long, and has the most significant bit set to 1. The remaining bits indicate how many more bytes are in the length field itself.

```text
00000000: 30  0
00000001: 82  .
00000002: 02  .
00000003: 01  .
00000004: 30  0
00000005: 82  .
00000006: 01  .
00000007: a6  .
00000008: a0  .
00000009: 03  .
00000010: 02  .
00000011: 01  .
00000012: 02  .
00000013: 02  .
00000014: 05  .
00000015: 00  .
00000016: de  .
00000017: ad  .
00000018: be  .
00000019: af  .
```

More info on context-specific tag in ASN.1: https://www.cryptologie.net/article/262/what-are-x509-certificates-rfc-asn1-der/

