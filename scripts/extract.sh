#!/bin/bash
set -e

# Certificate with embedded SCTs 
CERT_WITH_SCTS="../cert1.pem"

# Create a temporary directory
mkdir -p tmp
cd tmp

# First get the full ASN.1 structure
openssl asn1parse -in "../$CERT_WITH_SCTS" > cert_asn1.txt

# Find the SCT extension by friendly name "CT Precertificate SCTs"
SCT_LINE=$(grep 'CT Precertificate SCTs' cert_asn1.txt)
if [ -z "$SCT_LINE" ]; then
    echo "Error: No SCT extension found in certificate"
    exit 1
fi
echo "Found SCT line: $SCT_LINE"

# Extract offset of the extension
SCT_OFFSET=$(echo "$SCT_LINE" | awk '{print $1}' | sed 's/://')
echo "Found SCT extension at offset: $SCT_OFFSET"

# Find the OCTET STRING line that follows the CT Precertificate SCTs line
OCTET_LINE=$(grep -A 1 'CT Precertificate SCTs' cert_asn1.txt | grep 'OCTET STRING')
if [ -z "$OCTET_LINE" ]; then
    echo "Error: Could not find SCT content in extension"
    exit 1
fi
echo "Found OCTET STRING line: $OCTET_LINE"

# Extract offset of the OCTET STRING
OCTET_OFFSET=$(echo "$OCTET_LINE" | awk -F':' '{print $1}')
echo "Found OCTET STRING at offset: $OCTET_OFFSET"

# Extract the SCT data directly from the certificate
openssl asn1parse -in "../$CERT_WITH_SCTS" -strparse "$OCTET_OFFSET" -out sct_raw.bin -noout
