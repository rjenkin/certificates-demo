#!/bin/bash
set -e

CA_CERT=../docker/ssl/ca.crt
CA_KEY=../docker/ssl/ca.key

CA_DER_BASE64=$(openssl x509 -in $CA_CERT -outform DER | base64 -w 0)


# Create configuration file with PROPER CT POISON extension
# Cannot be created without the poison extension
cat > precert.cnf << EOF
[req]
distinguished_name = req_dn
req_extensions = v3_req
prompt = no

[req_dn]
CN = example.com

[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
subjectAltName = @alt_names

# CT Poison extension - MUST be set correctly
1.3.6.1.4.1.11129.2.4.3 = critical,ASN1:NULL

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
EOF


# Create CSR
echo "Creating CSR for precertificate..."
openssl req -new \
  -key ../docker/ssl/server.key \
  -config precert.cnf \
  -out server.csr


# Create precertificate
echo "Creating precertificate..."
openssl x509 -req \
  -in server.csr \
  -CA $CA_CERT \
  -CAkey $CA_KEY \
  -CAcreateserial \
  -out precert.crt \
  -days 365 \
  -extensions v3_req \
  -extfile precert.cnf


# Verify the certificate has the CT Poison extension
#openssl x509 -in precert.crt -text -noout | grep "CT Precertificate Poison"

# Convert precert to DER and base64
PRECERT_DER_BASE64=$(openssl x509 -in precert.crt -outform DER | base64 -w 0)

# Create the precertificate request payload
REQUEST_DATA=$(cat << EOF
{
  "chain": [
    "${PRECERT_DER_BASE64}",
    "${CA_DER_BASE64}"
  ]
}
EOF
)


# Try add-pre-chain endpoint (standard for precertificates)
SCT_RESPONSE=$(curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_DATA" \
  http://localhost:8080/testlog/ct/v1/add-pre-chain)

echo "SCT Response from CT Log Server:"
echo "$SCT_RESPONSE" | jq .

# Save response..
echo $SCT_RESPONSE > sct_response_latest.json

# Extract the SCT data from the response
SCT_BASE64=$(echo "$SCT_RESPONSE" | jq -r '.signature')

# Config to final certificate.
# echo "$SCT_BASE64" | base64 -d > sct.bin

DATA=$(pipenv run python sct_encode.py)
echo "Adding data: $DATA"


cat > final_cert.cnf << EOF
[req]
distinguished_name = req_dn
req_extensions = v3_req
prompt = no

[req_dn]
CN = example.com

[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
subjectAltName = @alt_names

$DATA

[alt_names]
DNS.1 = example.com
DNS.2 = www.example.com
EOF


# SCT List extension - embedding the SCT received from the log
# 1.3.6.1.4.1.11129.2.4.2 = ASN1:SEQUENCE:scts

# Copied from CBA cert
#1.3.6.1.4.1.11129.2.4.5 = ASN1:FORMAT:HEX,OCTETSTRING:0169007600e6d2316340778cc1104106d771b9cec1d240f6968486fbba87321dfd1e378e500000018fdd0413a7000004030047304502203925f9b5854051770fd89f7b8f3d94aaaf13e6dc9f2f971907d29fda6e34ae75022100b485dc094d4dad4928cb17e7c16178836bec2102f91edf7922c3891076f56f27007700a2e30ae445efbdad9b7e38ed47677753d7825b8494d72b5e1b2cc4b950a447e70000018fdd04139c0000040300483046022100e2367ddaeae5592adf7e03d2adc4195491afabb88862e9fd176722808ff26f93022100d0e80020d1d805be11a09209c2d4005c4b55874cf4d8006b9496862aa1d5c49a0076004e75a3275c9a10c3385b6cd4df3f52eb1df0e08e1b8d69c0b1fa64b1629a39df0000018fdd0413e30000040300473045022100b9ff6183c7dd0bfb9353e2caf4d88de2d5be0d2a989453c5cf16f26c7f08d3a80220306dcae12aaeeb9623db2d8ee04f5bc05391e20ace5e6322098d152661985fad

# My SCT
#1.3.6.1.4.1.11129.2.4.5 = ASN1:FORMAT:HEX,OCTETSTRING:00780076008f3b1fef8c43fe2145304b22f462b4c4a33c0c844b6965e6b7415bf21a3d270d00000196d13273790000040300473045022100b36654c2a5ab3981f14ecc4806781c51811c8b85adff1ed727f43882f2f8521202207209ca21827fad44e56207be5f9b93bd3af7927380aa92e7bfa1ad6ca6ea2042
# 1.3.6.1.4.1.11129.2.4.5 = ASN1:FORMAT:HEX,OCTETSTRING:000f3b1fef8c43fe2145304b22f462b4c4a33c0c844b6965e6b7415bf21a3d270d00019f5c0e7789a90000040300473045022100b36654c2a5ab3981f14ecc4806781c51841c8b85adff1ed727f43882f2f8521022087209ca21827fad44e56207be5f9b93bd3af7927380aa4b9efe86b5b29ba88108
#[scts]
#scts = SEQUENCE:sct_list

#[sct_list]
#sct1 = FORMAT:HEX,OCT:$(xxd -p -c 10000 sct.bin | tr -d '\n')


echo "Creating final CSR..."
openssl req -new \
  -key ../docker/ssl/server.key \
  -config final_cert.cnf \
  -out final.csr

# Extract Not After date in ASN1 format
SERIAL=$(openssl x509 -in precert.crt -noout -serial | cut -d'=' -f2)
NOT_BEFORE=$(openssl x509 -in precert.crt -noout -startdate | cut -d'=' -f2)
NOT_AFTER=$(openssl x509 -in precert.crt -noout -enddate | cut -d'=' -f2)

NOT_BEFORE_FORMATTED=$(TZ=UTC date -j -f "%b %e %H:%M:%S %Y %Z" "$NOT_BEFORE" "+%Y%m%d%H%M%SZ")
NOT_AFTER_FORMATTED=$(TZ=UTC date -j -f "%b %e %H:%M:%S %Y %Z" "$NOT_AFTER" "+%Y%m%d%H%M%SZ")

echo "Serial: $SERIAL"
echo "Not Before: $NOT_BEFORE_FORMATTED"
echo "Not After: $NOT_AFTER_FORMATTED"

echo "Creating final certificate with embedded SCT..."
openssl x509 -req \
  -in final.csr \
  -CA $CA_CERT \
  -CAkey $CA_KEY \
  -set_serial=0x$SERIAL \
  -out final.crt \
  -not_before $NOT_BEFORE_FORMATTED \
  -not_after $NOT_AFTER_FORMATTED \
  -extensions v3_req \
  -extfile final_cert.cnf

# Verify the final certificate has the SCT List extension
# echo "Verifying SCT List extension exists:"
# openssl x509 -in final.crt -text -noout #| grep -A 3 "CT Certificate SCTs"


CERT_DER_BASE64=$(openssl x509 -in final.crt -outform DER | base64 -w 0)

# Create the request payload
REQUEST_DATA2=$(cat << EOF
{
  "chain": [
    "${CERT_DER_BASE64}",
    "${CA_DER_BASE64}"
  ]
}
EOF
)

# Try add-chain endpoint (standard for certificates)
echo -e "\n\nAttempting add-chain..."
ADD_CHAIN_RESPONSE=$(curl --silent -X POST \
  -H "Content-Type: application/json" \
  -d "$REQUEST_DATA2" \
  http://localhost:8080/testlog/ct/v1/add-chain)

echo $ADD_CHAIN_RESPONSE | jq .


# Cleanup
# rm precert.cnf
# rm server.csr
# rm precert.crt
# rm sct.bin
# rm final_cert.cnf
# rm final.csr
# rm final.crt

# openssl x509 -in final.crt -text -noout
