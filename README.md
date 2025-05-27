# Certificates Demo: Learning Lab

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

**Basic Requirements (Exercises 1-5):**
- Docker for container-based services
- OpenSSL for certificate operations
- JQ for JSON processing

**Additional Requirements (Exercise 6):**
- Go programming language
- NodeJS runtime
- Python 3

If you're behind a corporate proxy or need to use internal package repositories, configure your development environment with these environment variables:
```bash
# NodeJS package source
export NPM_CONFIG_REGISTRY=https://your-internal-proxy/api/npm/npm

# Python pip package source
export PIP_INDEX_URL=https://your-internal-proxy/api/pypi/simple

# Python pipenv package source
export PIPENV_PYPI_MIRROR=https://your-internal-proxy/api/pypi/simple

# Go module proxy
export GOPROXY=https://your-internal-proxy/api/go/gocenter-proxy
```


## Exercises

1. [Prerequisite CLI commands](./docs/prerequisite-info.md)
2. [Start nginx server](./docs/nginx-server.md)
3. [Self-signed certificates](./docs/selfsigned-certificates.md)
4. [CA-signed certificates](./docs/casigned-certificates.md)
5. [Chain of Trust](./docs/chain-of-trust.md)
6. [Certificate Transparency Logs](./docs/certificate-transparency-logs.md)
7. [Other tools](./docs/other-tools.md)

