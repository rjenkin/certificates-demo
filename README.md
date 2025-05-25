# Certificate Learning Lab

A comprehensive hands-on repository for mastering SSL/TLS certificates through practical exercises and real-world scenarios. This educational toolkit guides you through the complete certificate lifecycle and ecosystem.

What You'll Learn
- Create and manage self-signed certificates for development environments
- Generate Certificate Signing Requests (CSRs) and work with Certificate Authorities
- Inspect and validate certificate chains and trust relationships
- Query Certificate Transparency (CT) logs to monitor certificate issuance
- Understand ASN.1, DER, and PEM encodings that underpin certificate structures
- Debug common certificate issues and deployment problems

Features
- Step-by-step exercises progressing from basics to advanced topics
- Real-world scenarios mimicking production certificate challenges
- Deep dives into certificate inspection using OpenSSL and alternative tools
- Hands-on exploration of Certificate Transparency logs and monitoring
- Practical examples for securing web servers, APIs, and client applications
- Decode and analyze the binary structures of certificates and keys

Perfect for developers, security professionals, and system administrators looking to build practical knowledge of PKI concepts and SSL/TLS certificate management beyond theoretical understanding.

## Requirements

These exercises require Docker, OpenSSL, Go, and JQ to be installed.


```bash
brew install openssl
brew install cmake
xcode-select --install

export OPENSSL_ROOT_DIR=$(brew --prefix openssl@3)
export CFLAGS="-I$OPENSSL_ROOT_DIR/include"
export LDFLAGS="-L$OPENSSL_ROOT_DIR/lib"
```

## Exercises

1. [Prerequisite CLI commands](./docs/prerequisite_cli_commands.md)
2. [Start nginx server](./docs/nginx_server.md)
3. [Self-signed certificates](./docs/selfsigned_certificates.md)
4. [CA-signed certificates](./docs/ca_signed_certificates.md)
5. [Real world certificates](./docs/realworld_certificates.md)
6. [Certificate Transparency Logs](./docs/certificate_transparency_logs.md)

