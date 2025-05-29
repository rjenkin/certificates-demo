# SCT Encoding

Return [Certificate Transparency Logs](../certificate-transparency-logs.md)

The SCT extension in certificates follows a specific binary structure defined in RFC 6962. Let's examine how to extract and understand this encoding.

**Examining SCT Extension Structure**

Find the offset for the SCT extension data:
```bash
openssl asn1parse -in ssl/chain-of-trust/cert1.pem | grep -A 1 'CT Precertificate SCTs'
```

Look for the CT Precertificate SCTs extension:
```
 1165:d=5  hl=2 l=  10 prim: OBJECT            :CT Precertificate SCTs
 1177:d=5  hl=4 l= 367 prim: OCTET STRING      [HEX DUMP]:0482016B0169007600E6D2...AD
```

Extract the extension value at offset for the octet string:
```bash
openssl asn1parse -in ssl/chain-of-trust/cert1.pem -strparse "1177"

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


## Exercise: Identify the SCT Components

Understanding the precise binary structure of SCTs is essential for properly encoding them from your own log server. In this exercise, extract the SCT as binary and output to a text file. Annotate the text file with the meaning of each byte.

```bash
openssl asn1parse -in ssl/chain-of-trust/cert1.pem -strparse "..offset.." -out sct-encoding/data/cert1_scts.bin -noout

xxd -c 1 --decimal sct-encoding/data/cert1_scts.bin > sct-encoding/data/cert1_scts.bin.txt
```

The annotated output should look like:
```text
00000000: 04  . # Octet string
00000001: 82  . # 2 bytes are used for the length
...
```


## Exercise: script to extract SCT data to JSON

Update the `sct-encoding/src/sct_decode.py` script to output the `cert1_scts.bin` as JSON. Unit tests have been setup to ensure the code is output to the expected format.

Install the python dependencies:
```bash
pipenv install
```

> Note: to install packages through an internal package server, set the following environment variables
> ```bash
> export PIPENV_PYPI_MIRROR=https://your-internal-proxy/api/pypi/org.python.pypi/simple
> ```


When the script is working, output the response to a JSON file:
```bash
pipenv run decode --sct data/cert1_scts.bin > data/cert1_scts.json
```


## Exercise: script to encode SCT data into a certificate

Update the `sct-encoding/src/sct_encode.py` script to convert the JSON back to binary. By comparing the output with the original `cert1_scts.bin` we can verify that the script is working correctly, and use this for embedding our own SCTs into our certificates.

Run the script:
```bash
pipenv run encode --scts data/cert1_scts.json --binary-output data/cert1_scts_recoded.bin
```

Compare the output with the original:
```bash
xxd -c 1 --decimal data/cert1_scts_recoded.bin > data/cert1_scts_recoded.bin.txt

diff --color=always --side-by-side data/cert1_scts.bin.txt data/cert1_scts_recoded.bin.txt
git diff --no-index --word-diff data/cert1_scts.bin.txt data/cert1_scts_recoded.bin.txt
```



## Next section

[Generating certificates with embedded SCTs](./ct_certificates.md)
