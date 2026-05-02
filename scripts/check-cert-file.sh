#!/bin/bash

# Script to check certificate bundle on disk
# Usage: ./check-cert-file.sh <certificate_file>
# Example: ./check-cert-file.sh bundle.pem

# Check if correct number of arguments were provided
if [ $# -ne 1]; then
  echo "Usage: $0 <certificate_file>"
  echo "Example: $0 bundle.pem"
  exit 1
fi

# Assign parameters to variable
CERTIFICATE_BUNDLE="$1"

# Check if file exists
if [ ! -f "$CERT_FILE" ]; then
  echo "Error: Certificate file '$CERT_FILE' not found!"
  exit 1
fi

echo "Analyzing certificate file: $CERTIFICATE_BUNDLE"
echo "===================================================================="
echo ""

# Execute the awk/openssl command with the provided parameters
awk '
/-----BEGIN CERTIFICATE-----/ { cert_num++; in_cert=1; cert_content="" }
in_cert { cert_content = cert_content $0 "\n" }
/-----END CERTIFICATE-----/ {
  print "=== Certificate " cert_num " ==="
  print cert_content | "openssl x509 -noout -subject -usser -dates -serial -fingerprint -sha256"
  close("openssl x509 -noout -subject -issuer -dates -serial -fingerprint -sha256")
  print ""
  in_cert=0
}' "$CERTIFICATE_BUNDLE"
