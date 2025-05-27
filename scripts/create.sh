#!/bin/bash
# This script generates a chain of trust certificate structure

# Work out of the chain of trust directory
cd $(dirname "$0")
cd ../ssl/chain-of-trust

#
# Root CA
#

echo "Generating Root CA private key..."
openssl genrsa -out ca.key 2048
if [ $? -ne 0 ]; then
    echo "Error generating CA key"
    exit 1
fi

echo "Creating Root CA certificate..."
openssl req -new -x509 \
-not_before 20090707172554Z \
-not_after 20301207175554Z \
-key ca.key \
-out ca.pem \
-config ca.cnf \
-extensions req_ext \
-set_serial '0x4a538c28'

if [ $? -ne 0 ]; then
    echo "Error generating CA certificate"
    exit 1
fi

openssl x509 -in ca.pem -text -noout > ca.pem.txt


#
# Intermediate CA
#

echo "Generating Intermediate CA private key..."
openssl genrsa -out intermediate.key 2048

echo "Creating Intermediate CA certificate signing request..."
openssl req -new \
-key intermediate.key \
-config intermediate.cnf \
-out intermediate.csr

if [ $? -ne 0 ]; then
    echo "Error generating intermediate CA certificate signing request"
    exit 1
fi

echo "Creating Intermediate CA certificate..."
openssl x509 -req \
-not_before 20141215152503Z \
-not_after 20301015155503Z \
-in intermediate.csr \
-CA ca.pem \
-CAkey ca.key \
-out intermediate.pem \
-extensions req_ext \
-extfile intermediate.cnf \
-set_serial '0x61a1e7d20000000051d366a6'

if [ $? -ne 0 ]; then
    echo "Error generating intermediate CA certificate"
    exit 1
fi


openssl x509 -in intermediate.pem -text -noout > intermediate.pem.txt



#
# Server certificate
#

echo "Generating server private key..."
openssl genrsa -out server.key 2048

echo "Creating server certificate signing request..."
openssl req -new \
-key server.key \
-config server.cnf \
-out server.csr

if [ $? -ne 0 ]; then
    echo "Error generating server certificate signing request"
    exit 1
fi

echo "Creating server certificate..."
openssl x509 -req \
-not_before 20240603073302Z \
-not_after 20250603073301Z \
-in server.csr \
-CA intermediate.pem \
-CAkey intermediate.key \
-out server.pem \
-extensions req_ext2 \
-extfile server.cnf \
-set_serial '0x79d816d9c1f85c2c343bd655aee3e978'

if [ $? -ne 0 ]; then
    echo "Error generating server certificate"
    exit 1
fi


openssl x509 -in server.pem -text -noout > server.pem.txt

