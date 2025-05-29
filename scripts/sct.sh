#!/bin/bash
set -e

# Work out of the "ssl/scts" directory
cd $(dirname "$0")
cd ../ssl/scts

CA_CERT=../chain-of-trust/ca.pem
CA_KEY=../chain-of-trust/ca.key

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
  -key ../chain-of-trust/server.key \
  -config precert.cnf \
  -out server.csr


# Create precertificate
echo "Creating precertificate..."
openssl x509 -req \
  -in server.csr \
  -CA $CA_CERT \
  -CAkey $CA_KEY \
  -CAcreateserial \
  -out precert.pem \
  -days 365 \
  -extensions v3_req \
  -extfile precert.cnf

# Verify the certificate has the CT Poison extension
openssl asn1parse -in precert.pem | grep -A 2 'CT Precertificate Poison'

# Convert precert to DER and base64
PRECERT_DER_BASE64=$(openssl x509 -in precert.pem -outform DER | base64 -w 0)

# Create the precertificate request payload
cat > add-pre-chain_data.json << EOF
{
  "chain": [
    "${PRECERT_DER_BASE64}",
    "${CA_DER_BASE64}"
  ]
}
EOF

# Try add-pre-chain endpoint (standard for precertificates)
echo "Calling add pre chain"
SCT_RESPONSE=$(curl --noproxy '*' --silent -X POST \
  -H "Content-Type: application/json" \
  -d @add-pre-chain_data.json \
  http://localhost:8080/logs/ct/v1/add-pre-chain)

echo "SCT Response from CT Log Server:"
echo "$SCT_RESPONSE"
echo "$SCT_RESPONSE" | jq .

# Save response..
echo $SCT_RESPONSE > add-pre-chain_response.json

# Extract the SCT data from the response
SCT_BASE64=$(echo "$SCT_RESPONSE" | jq -r '.signature')

# Config to final certificate.
# echo "$SCT_BASE64" | base64 -d > sct.bin

# Update reference...
pushd ../../sct-encoding > /dev/null
DATA=$(pipenv run encode --scts ../ssl/scts/add-pre-chain_response.json)
popd > /dev/null

echo "Adding data: $DATA"

cat > final.cnf << EOF
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


echo "Creating final CSR..."
openssl req -new \
  -key ../chain-of-trust/server.key \
  -config final.cnf \
  -out final.csr

# Extract Not After date in ASN1 format
SERIAL=$(openssl x509 -in precert.pem -noout -serial | cut -d'=' -f2)
NOT_BEFORE=$(openssl x509 -in precert.pem -noout -startdate | cut -d'=' -f2)
NOT_AFTER=$(openssl x509 -in precert.pem -noout -enddate | cut -d'=' -f2)

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
  -out final.pem \
  -not_before $NOT_BEFORE_FORMATTED \
  -not_after $NOT_AFTER_FORMATTED \
  -extensions v3_req \
  -extfile final.cnf

# Verify the final certificate has the SCT List extension
# echo "Verifying SCT List extension exists:"
openssl asn1parse -in final.pem | grep -A 2 'CT Precertificate SCTs'

CERT_DER_BASE64=$(openssl x509 -in final.pem -outform DER | base64 -w 0)

# Create the request payload
cat > add-chain_data.json << EOF
{
  "chain": [
    "${CERT_DER_BASE64}",
    "${CA_DER_BASE64}"
  ]
}
EOF


# Try add-chain endpoint (standard for certificates)
echo -e "\n\nAttempting add-chain..."
ADD_CHAIN_RESPONSE=$(curl --noproxy '*' --silent -X POST \
  -H "Content-Type: application/json" \
  -d @add-chain_data.json \
  http://localhost:8080/logs/ct/v1/add-chain)

echo $ADD_CHAIN_RESPONSE
echo $ADD_CHAIN_RESPONSE | jq .
echo $ADD_CHAIN_RESPONSE > add-chain_response.json
