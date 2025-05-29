# Certificate Transparency Logs

Return [home](../README.md)

> **Preparation Note:** Setting up the local CT log server later in this exercise requires downloading git submodules and Docker images, which can take some time. To save time later, you can run the setup commands in the `Start local log server` section now while you continue with the current exercises.

Certificate Transparency logs help protect end users by making it possible to detect and fix fraudulent or mistakenly issued website security certificates, reducing the risk of impersonation or malicious websites. When a certificate is issued by a Certificate Authority, it can be submitted to public, append-only CT logs maintained by independent operators. These logs create cryptographically verifiable records of all certificates, allowing website owners, browsers, and security researchers to monitor and audit certificate issuance. Each logged certificate receives a Signed Certificate Timestamp (SCT) as proof of inclusion, which can be embedded in the certificate itself.

Certificate Transparency uses a two-step process for logging certificates:
1. **Precertificate Submission:** Before issuing the final certificate, the CA creates a "precertificate" - a version of the certificate containing a special critical poison extension (OID 1.3.6.1.4.1.11129.2.4.3). The critical poison extension prevents the certificate from being used. This precertificate is submitted to CT logs.
2. **SCT Inclusion in Final Certificate:** After receiving SCTs from logs, the CA removes the poison extension and embeds the collected SCTs in the final certificate using the Precertificate Signed Certificate Timestamps extension (OID 1.3.6.1.4.1.11129.2.4.2).

The precertificate and final certificate are identical except for these extensions, ensuring that the SCTs remain valid for the final certificate despite being generated for the precertificate. A certificate can be submitted to multiple log servers.

**Topics:**
- [Verifying a SCT](./ct_verifying.md)
- [Log Servers](./ct_log_servers.md)
- [SCT encoding](./ct_encoding.md)
- [Generating certificates with embedded SCTs](./ct_certificates.md)
