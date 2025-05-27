# Certificate Chain of Trust

This section guides you through retrieving certificates from live websites, analyzing their structure and properties, and understanding how production certificates differ from the simpler examples created in previous exercises. You'll learn to extract certificates using OpenSSL's s_client, inspect detailed certificate extensions, and compare different certificates in a certificate chain to understand trust relationships in real-world deployments. Finally we'll try to recreate those certificates.


## Download certificates

Real-world PKI architectures typically implement a three-tiered hierarchy: a highly-secured offline root CA at the top, one or more intermediate CAs that receive their authority from the root, and end-entity certificates (like server certificates) issued by these intermediates. This design limits exposure of the root CA's private key while maintaining a chain of trust to end certificates.

```bash
openssl s_client -showcerts -connect commbank.com.au:443 </dev/null | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".pem"; print >out}'
```

**Check the subject and issuer:**
```bash
openssl x509 -in cert1.pem -noout -subject -issuer
openssl x509 -in cert2.pem -noout -subject -issuer
openssl x509 -in cert3.pem -noout -subject -issuer
```

**Compare certificate purpose:**
```bash
openssl x509 -in cert1.pem -noout -purpose > cert1.purpose.txt
openssl x509 -in cert2.pem -noout -purpose > cert2.purpose.txt
openssl x509 -in cert3.pem -noout -purpose > cert3.purpose.txt

git diff --no-index --word-diff cert1.purpose.txt cert2.purpose.txt
git diff --no-index --word-diff cert2.purpose.txt cert3.purpose.txt
```

**Compare certificate dates:**
```bash
openssl x509 -in cert1.pem -noout -dates
openssl x509 -in cert2.pem -noout -dates
openssl x509 -in cert3.pem -noout -dates
```

**Verify certificates:**

The intermediate certificate can be validated against the root certificate authority:
```bash
openssl verify -CAfile cert3.pem cert2.pem
```

To validate certificate one however, the intermediate certificate and the root certificate need to be bundled:
```bash
cat cert3.pem cert2.pem > bundle.pem

openssl verify -CAfile bundle.pem cert1.pem
```

## Recreate certificates

This exercise involves trying to recreate all three certificate with identical details. To verify whether your certificate matches, we will commit the original certificate to git, and output our certificate to the same file so that we can see what is similar or what is different. Start with the root CA as that's needed to create the intermediate certificate, and finally the server's certificate.

> Note: you won't be able to match the public key or the signature value using your own private keys.

Commit original certificates:
```bash
openssl x509 -in cert1.pem -noout -text > cert1.txt
openssl x509 -in cert2.pem -noout -text > cert2.txt
openssl x509 -in cert3.pem -noout -text > cert3.txt

git add cert1.txt cert2.txt cert3.txt
```

**Unstage changes:**

To clean up the git repo, unstage your changes

```bash
git restore --staged cert1.txt cert2.txt cert3.txt
```


**When completed verify that the certificates are valid:**

```bash
openssl verify -CAfile ssl/three-tier-certificates/ca.crt ssl/three-tier-certificates/intermediate.crt

cat three-tier-certificates/ca.crt ssl/three-tier-certificates/intermediate.crt > ssl/three-tier-certificates/bundle.crt
openssl verify -CAfile ssl/three-tier-certificates/bundle.crt ssl/three-tier-certificates/server.crt
```
