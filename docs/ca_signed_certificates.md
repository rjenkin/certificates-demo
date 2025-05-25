# Certificate authority signed certificates

Using a custom Certificate Authority (CA) for local development simplifies security by requiring you to trust just one root certificate instead of multiple self-signed ones. Once your system trusts your local CA, you can easily generate and use certificates for any number of development services without additional trust configuration, creating a more realistic and streamlined secure development environment.

![CA signed Certificate](ca-signed.drawio.png)

## Create the certificate authority

**Create the private key:**

Certificate authorities typically use larger key sizes (such as 4096-bit RSA) compared to server certificates (often 2048-bit) because the CA's key has greater security implications - if compromised, all certificates signed by that CA would be affected, potentially impacting thousands of systems rather than just a single server.

```bash
openssl genrsa -out docker/ssl/ca.key 4096
```

**Create the certificate:**

Creating a root CA certificate involves a direct, self-signed process without requiring a separate CSR step. We're using a configuration file to define important CA-specific extensions and attributes that distinguish it as a certificate issuer rather than an end-entity certificate. The detailed settings in the [ca config](../docker/ssl/ca.cnf) file establish critical parameters like key usage constraints and basic constraints that define this as a CA certificate.

Certificate authorities typically have much longer validity periods than server certificates. In this example, we're creating the CA certificate with a 10-year lifespan (3650 days), while the server certificates will only be valid for 1 year (365 days). This reflects real-world practice where CA certificates need to remain valid for all certificates they issue throughout their operational lifetime.

```bash
openssl req -new \
-x509 \
-days 3650 \
-key docker/ssl/ca.key \
-out docker/ssl/ca.crt \
-config docker/ssl/ca.cnf \
-extensions req_ext
```

**Read details of the certificate:**

```bash
openssl x509 -in docker/ssl/ca.crt -text -noout
```

When examining the CA certificate compared to the previously created self-signed certificate, you'll notice several important differences, particularly in the extensions section. The CA certificate will have the CA:TRUE flag in the Basic Constraints and different Key Usage values that permit certificate signing. These distinguishing features define the certificate's role in the PKI hierarchy:

```bash
openssl x509 -in docker/ssl/ca.crt -text -noout > ca.crt.txt

diff --color=always --side-by-side selfsigned.crt.txt ca.crt.txt
git diff --no-index --word-diff selfsigned.csr.txt ca.crt.txt
```

## Create the server certificates

Now that we've established our Certificate Authority, we'll create server certificates that will be signed by this CA.

**Create the private key:**
```bash
openssl genrsa -out docker/ssl/servers.key 2048
```

**Create the Certificate Signing Request:**

Each server requires its own Certificate Signing Request with specific configuration settings for its intended domain name and usage. This ensures certificates are properly scoped to their individual servers.

You can examine the differences between configurations:
```bash
diff --color=always --side-by-side docker/ssl/selfsigned-2.cnf docker/ssl/server-one.cnf

diff --color=always --side-by-side docker/ssl/server-one.cnf docker/ssl/server-two.cnf
```

Create the signing requests:
```bash
openssl req -new \
-key docker/ssl/servers.key \
-out docker/ssl/server-one.csr \
-config docker/ssl/server-one.cnf

openssl req -new \
-key docker/ssl/servers.key \
-out docker/ssl/server-two.csr \
-config docker/ssl/server-two.cnf
```

Compare the CSRs:
```bash
openssl req -in docker/ssl/server-one.csr -text -noout > server-one.csr.txt

openssl req -in docker/ssl/server-two.csr -text -noout > server-two.csr.txt

diff --color=always --side-by-side server-one.csr.txt server-two.csr.txt

git diff --no-index --word-diff server-one.csr.txt server-two.csr.txt
```

**Create the certificates with the Certificate Authority:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/server-one.csr \
-CA docker/ssl/ca.crt \
-CAkey docker/ssl/ca.key \
-CAcreateserial \
-out docker/ssl/server-one.crt \
-extensions req_ext \
-extfile docker/ssl/server-one.cnf

openssl x509 -req \
-days 365 \
-in docker/ssl/server-two.csr \
-CA docker/ssl/ca.crt \
-CAkey docker/ssl/ca.key \
-CAcreateserial \
-out docker/ssl/server-two.crt \
-extensions req_ext \
-extfile docker/ssl/server-two.cnf
```

Compare the certificates:
```bash
openssl x509 -in docker/ssl/server-one.crt -text -noout > server-one.crt.txt

openssl x509 -in docker/ssl/server-two.crt -text -noout > server-two.crt.txt

diff --color=always --side-by-side server-one.crt.txt server-two.crt.txt

git diff --no-index --word-diff server-one.csr.txt server-two.csr.txt
```

Compare server one certificate with the certificate authority:
```bash
diff --color=always --side-by-side ca.crt.txt server-one.crt.txt

git diff --no-index --word-diff ca.crt.txt server-one.crt.txt
```

**Verify that a certificate was issued by an authority:**

The certificate for server one was signed by the certificate authority so verification should pass:
```bash
openssl verify -CAfile docker/ssl/ca.crt docker/ssl/server-one.crt 
```

Our self-signed certificate was not signed by the certificate authority so verification should fail:
```bash
openssl verify -CAfile docker/ssl/ca.crt docker/ssl/selfsigned.crt 
```

## Install certificates

**Enable SSL in nginx:**

Update both server configs in [nginx config](../docker/nginx.conf) to use certificates `server-one.crt` and `server-two.crt` and restart the container:

```text
    ssl_certificate     /etc/nginx/ssl/server-one.crt;
    ssl_certificate_key /etc/nginx/ssl/servers.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
```

**Make a HTTPs request to the server using the CA certificate:**

```bash
curl --cacert docker/ssl/ca.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000

curl --cacert docker/ssl/ca.crt --resolve server-two:10000:127.0.0.1 https://server-two:10000

curl --cacert docker/ssl/ca.crt -H 'Host: server-one' https://localhost:10000/ 

curl --cacert docker/ssl/ca.crt -H 'Host: server-two' https://localhost:10000/ 
```

## Discover the certificate authority

When working in corporate environments with secure internet connections, network traffic is often routed through proxy servers that implement TLS inspection. These proxies terminate the original HTTPS connection and establish a new one with their own certificates. This can cause certificate validation issues since your system needs to trust the proxy's certificate authority rather than the website's original CA. Identifying which certificate authority is actually securing your connection becomes critical for proper certificate validation and troubleshooting.

```bash
openssl s_client -connect 127.0.0.1:10000 -servername server-one </dev/null | openssl x509 -noout -issuer
```

OpenSSL will return an error saying that it doesn't trust the server, and will then return the issuer value:

```text
Connecting to 127.0.0.1
depth=0 CN=server-one
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 CN=server-one
verify error:num=21:unable to verify the first certificate
verify return:1
depth=0 CN=server-one
verify return:1
DONE
issuer=CN=MyCertificateAuthority
```
