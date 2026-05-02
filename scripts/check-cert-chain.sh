#!/bin/bash

# Script to check SSL certificate chain for a given host
# Usage: ./check-cert-chain.sh <connect> <servername>
# Example: ./check-cert-chain.sh example.com:443 example.com

# Check if correct number of arguments were provided
if [ $# -ne 2]; then
  echo "Usage: $0 <connect> <servername>"
  echo "Example: $0 example.com:443 example.com"
  exit 1
fi

# Assign parameters to variables
CONNECT="$1"
SERVERNAME="$2"

echo "Checking certificate chain for: $SERVERNAME (connecting to $CONNECT)"
echo "===================================================================="
echo ""

# Execute the openssl command with the provided parameters
openssl s_client -connect "$CONNECT" -servername "$SERVERNAME" -showcerts 2>/dev/null | awk '
/-----BEGIN CERTIFICATE-----/ { cert_num++; in_cert=1; cert_content="" }
in_cert { cert_content = cert_content $0 "\n" }
/-----END CERTIFICATE-----/ {
  print "=== Certificate " cert_num " ==="
  print cert_content | "openssl x509 -noout -subject -usser -dates -serial -fingerprint -sha256"
  close("openssl x509 -noout -subject -issuer -dates -serial -fingerprint -sha256")
  print ""
  in_cert=0
}'
