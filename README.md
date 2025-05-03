# Certificates demo


## Setup

**Start docker:**
```bash
docker-compose up -d
```

**Test docker:**
```bash
curl http://localhost:10000/

curl -H 'Host: server-one' http://localhost:10000/

curl -H 'Host: server-two' http://localhost:10000/

curl --resolve server-one:10000:127.0.0.1 http://server-one:10000/

curl --resolve server-two:10000:127.0.0.1 http://server-two:10000/
```

## Diagram

![Diagram](./docs/diagram.png)


## Self-signed certificates

### Private key

**Create the key:**
```bash
openssl genrsa -out docker/ssl/selfsigned.key 2048
```

**Check the details of the key:**
```bash
openssl rsa -in docker/ssl/selfsigned.key -text -noout | head -n 1
```

### Certificate signing request

**Create the Certificate Signing Request:**
```bash
openssl req -new \
-key docker/ssl/selfsigned.key \
-config docker/ssl/selfsigned.cnf \
-out docker/ssl/selfsigned.csr
```

**Read the details of the Certificate Signing Request:**
```bash
openssl req -in docker/ssl/selfsigned.csr -text -noout > selfsigned.csr.text
git add selfsigned.csr.text
```

### Create the certificate

**Create the certificate:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/selfsigned.csr \
-signkey docker/ssl/selfsigned.key \
-out docker/ssl/selfsigned.crt \
-extfile docker/ssl/selfsigned.cnf
```

**Read details of the certificate:**
```bash
openssl x509 -in docker/ssl/selfsigned.crt -text -noout > selfsigned.crt.text
git add selfsigned.crt.text
```

### Testing the certificate

**Enable SSL in nginx:**

Update the [nginx config](./docker/nginx.conf) and restart the container:
```
server {
    listen 80 ssl;
    server_name server-one;

    ssl_certificate     /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    ....
}
```

**Make a HTTPs request to the server:**
```bash
curl --resolve server-one:10000:127.0.0.1 https://server-one:10000/
```

This should return an untrusted certificate error

**Ignore error (not recommended):**
```bash
curl --resolve server-one:10000:127.0.0.1 https://server-one:10000/ --insecure
```

**Request with certificate:**
```bash
curl --cacert docker/ssl/selfsigned.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000/
```

**Request on different domain name:**
```bash
curl --cacert docker/ssl/selfsigned.crt https://localhost:10000/
```

### Subject Name Alternatives

Include the Subject Name Alternatives into [config](./docker/ssl/selfsigned-2.cnf)

**Create the Certificate Signing Request:**
```bash
openssl req -new \
-key docker/ssl/selfsigned.key \
-out docker/ssl/selfsigned.csr \
-config docker/ssl/selfsigned-2.cnf
```

**Read the details of the Certificate Signing Request:**
```bash
openssl req -in docker/ssl/selfsigned.csr -text -noout > selfsigned.csr.text
```

**Create the certificate:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/selfsigned.csr \
-signkey docker/ssl/selfsigned.key \
-out docker/ssl/selfsigned.crt \
-extensions req_ext \
-extfile docker/ssl/selfsigned-2.cnf
```

**Read details of the certificate:**
```bash
openssl x509 -in docker/ssl/selfsigned.crt -text -noout > selfsigned.crt.text
```

**Testing the new certificate:**
```bash
curl --cacert docker/ssl/selfsigned.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000

curl --cacert docker/ssl/selfsigned.crt -H 'Host: server-one' https://localhost:10000/ 
```

## Certificate Authority

Using a custom Certificate Authority (CA) for local development simplifies security by requiring you to trust just one root certificate instead of multiple self-signed ones. Once your system trusts your local CA, you can easily generate and use certificates for any number of development services without additional trust configuration, creating a more realistic and streamlined secure development environment.

### Create the certificate authority

**Create the private key:**
```bash
openssl genrsa -out docker/ssl/ca.key 4096
```

**Create the certificate:**
```bash
openssl req -new \
-x509 \
-days 3650 \
-key docker/ssl/ca.key \
-out docker/ssl/ca.crt \
-config docker/ssl/ca.cnf
```

### Create the server certificates

**Create a private key:**
```bash
openssl genrsa -out docker/ssl/servers.key 2048
```

**Create the Certificate Signing Request:**
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

**Create the certificates with the Certificate Authority:**
```bash
openssl x509 -req \
-days 365 \
-in docker/ssl/server-one.csr \
-CA docker/ssl/ca.crt \
-CAkey docker/ssl/ca.key \
-CAcreateserial \
-out docker/ssl/server-one.crt \
-extensions req_ext -extfile docker/ssl/server-one.cnf

openssl x509 -req \
-days 365 \
-in docker/ssl/server-two.csr \
-CA docker/ssl/ca.crt \
-CAkey docker/ssl/ca.key \
-CAcreateserial \
-out docker/ssl/server-two.crt \
-extensions req_ext -extfile docker/ssl/server-two.cnf
```

### Testing the certificates

**Enable SSL in nginx:**

Update both servers in [nginx config](./docker/nginx.conf) to use certificates `server-one.crt` and `server-two.crt` and restart the container:

**Make a HTTPs request to the server using the CA certificate:**
```bash
curl --cacert docker/ssl/ca.crt --resolve server-one:10000:127.0.0.1 https://server-one:10000

curl --cacert docker/ssl/ca.crt --resolve server-two:10000:127.0.0.1 https://server-two:10000

curl --cacert docker/ssl/ca.crt -H 'Host: server-one' https://localhost:10000/ 

curl --cacert docker/ssl/ca.crt -H 'Host: server-two' https://localhost:10000/ 
```

