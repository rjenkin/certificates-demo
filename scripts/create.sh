#!/bin/bash


# openssl genrsa -out docker/ssl/ca-2.key 4096

openssl req -new -x509 \
-not_before 20250503125809Z \
-not_after 20350501125809Z \
-key docker/ssl/ca-2.key \
-out docker/ssl/ca-2.crt \
-config docker/ssl/ca-2.cnf \
-extensions req_ext \
# -set_serial '0xC3F7D0B52A30ADAF0D9121703954DDBC8970C73A'
# -set_serial '0x277b45cb6ea5ae31cb5b1d0585dc679c853d0fed' # The serial has the : removed
# -days 3650 \

openssl x509 -in docker/ssl/ca-2.crt -text -noout > docker/ssl/ca-2.crt.text

# Private key for server (no passphrase)
# openssl genrsa -out docker/ssl/server.key 2048

# Create certificate signing request
openssl req -new -key docker/ssl/server.key -out docker/ssl/server.csr -config docker/ssl/server.cnf

openssl req -in docker/ssl/server.csr -text -noout > docker/ssl/server.csr.text

# Precertificate
# openssl x509 -req \
# -not_before 20240603073302Z \
# -not_after 20250603073301Z \
# -set_serial '0x79d816d9c1f85c2c343bd655aee3e978' \
# -in docker/ssl/server.csr \
# -CA docker/ssl/ca-2.crt \
# -CAkey docker/ssl/ca-2.key \
# -CAcreateserial \
# -out docker/ssl/server-precertificate.crt \
# -extensions req_ext \
# -extfile docker/ssl/server.cnf

#     openssl x509 -in docker/ssl/ca-2.crt -outform DER -out docker/ssl/ca-2.der
#     openssl x509 -in docker/ssl/server-precertificate.crt -outform DER -out docker/ssl/server-precertificate.der

#     base64 -i docker/ssl/ca-2.der > docker/ssl/ca-2.b64
#     base64 -i docker/ssl/server-precertificate.der > docker/ssl/server-precertificate.b64

#     cat > submission.json <<EOF
#     {
#     "chain": [
#         "$(cat docker/ssl/server-precertificate.b64)",
#         "$(cat docker/ssl/ca-2.b64)"
#     ]
#     }
# EOF

# curl -X POST \
# -H "Content-Type: application/json" \
# --data @submission.json \
# http://localhost:8093/ct/v1/add-pre-chain

# curl -X POST http://localhost:8093/ct/v1/add-chain \
#   -H "Content-Type: application/json" \
#   -d '{
#     "chain": [
#         "$(cat docker/ssl/server-precertificate.b64)",
#         "$(cat docker/ssl/ca-2.b64)"
#     ]
#   }'


# {
#   "sct_version": 0,
#   "id": "...",
#   "timestamp": 1234567890,
#   "extensions": "",
#   "signature": "..."
# }


#     curl -sL http://localhost:8092/ct/v1/get-roots

# Final certificate
openssl x509 -req \
-not_before 20240603073302Z \
-not_after 20250603073301Z \
-in docker/ssl/server.csr \
-CA docker/ssl/ca-2.crt \
-CAkey docker/ssl/ca-2.key \
-CAcreateserial \
-out docker/ssl/server.crt \
-set_serial '0x79d816d9c1f85c2c343bd655aee3e978' \
-extensions req_ext2 \
-extfile docker/ssl/server.cnf


# openssl x509 -in docker/ssl/server.crt -text -noout > docker/ssl/server.csr.text

openssl x509 -in docker/ssl/server.crt -text -noout > cert1.pem.text



https://docs.openssl.org/3.4/man5/x509v3_config/#extended-key-usage
https://datatracker.ietf.org/doc/html/rfc6962#section-4

Need trillian, and certificate transparency go.
-> Convoluted setup...
-> 