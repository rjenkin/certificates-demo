/**
 * This script validates a certificate against a Certificate Transparency (CT) log.
 * Validation works by removing the SCT from the certificate, creating a Merkle Tree Leaf hash,
 * and then verifying the certificate's existence in the CT log using a Merkle proof.
 */
import fs from 'fs';
import { b64DecodeBytes, b64EncodeBytes, loadCertificateDER, toHexString, base64EncodeLogId, base64EncodePublicKey } from "./conversion";
import { CTLogClient } from "./ct_log_client";
import { CtLogStore } from "./ct_log_store";
import { leafHashForPreCert, sctsFromCertDer } from "./ct_parsing";
import { validateProof } from "./ct_proof_validation";

(async() => {
    if (process.argv.length < 4) {
        console.error("Usage: npm run ct-verify <cert.pem> <issuer.pem>");
        process.exit(1);
    }

    // Load the certificate and issuer files
    const certFilename = process.argv[2];
    if (!fs.existsSync(certFilename)) {
        console.error(`Certificate file ${certFilename} does not exist.`);
        process.exit(1);
    }
    const certificate = loadCertificateDER(certFilename);

    const issuerFilename = process.argv[3];
    if (!fs.existsSync(issuerFilename)) {
        console.error(`Issuer file ${issuerFilename} does not exist.`);
        process.exit(1);
    }
    const issuer = loadCertificateDER(issuerFilename);

    try {
      const ctLogStore = await CtLogStore.getInstance();

      // Add your CT Log server
      ctLogStore.addLog({
        description: "Local CT Logs",
        log_id: base64EncodeLogId("8F:3B:1F:EF:8C:43:FE:21:45:30:4B:22:F4:62:B4:C4:A3:3C:0C:84:4B:69:65:E6:B7:41:5B:F2:1A:3D:27:0D"),
        key: base64EncodePublicKey("\x30\x59\x30\x13\x06\x07\x2a\x86\x48\xce\x3d\x02\x01\x06\x08\x2a\x86\x48\xce\x3d\x03\x01\x07\x03\x42\x00\x04\x44\x6d\x69\x2c\x00\xec\xf3\xc7\xbb\x87\x7e\x57\xea\x04\xc3\x4b\x49\x01\xc4\x9a\x19\xf2\x49\x9b\x4c\x44\x1c\xac\xe0\xff\x27\x11\xce\x94\xa8\x85\xd9\xed\x42\x22\x5c\x54\xf6\x33\x73\xa3\x3d\x8b\xe8\x53\x48\xf5\x57\x50\x61\x96\x30\x5b\xc4\x9b\xa3\x04\xc3\x4b"),
        url: "http://localhost:8080/logs/",
        mmd: 86400,
        state: {
            usable: {
                timestamp: "2022-11-01T18:54:00Z"
            }
        },
        temporal_interval: {
            start_inclusive: "2025-01-01T00:00:00Z",
            end_exclusive: "2026-01-01T00:00:00Z"
        }
      });

      const scts = sctsFromCertDer(certificate);
      console.log(`Found ${scts.length} SCTs in certificate`);
      if (scts.length === 0) {
        console.warn(`No Signed Certificate Timestamps found in certificate ${certFilename}`);
        return;
      }

      for (const sct of scts) {
        const b64LogId = b64EncodeBytes(new Uint8Array(sct.logId));

        // This returns the log, i.e DigiCert log
        const log = ctLogStore.getLogById(b64LogId);
        if (log === undefined) {
          console.warn(`CT Log ${b64LogId} not found`);
          continue;
        }

        const leafHash = await leafHashForPreCert(
          certificate,
          issuer,
          sct.timestamp,
          new Uint8Array(sct.extensions),
        );

        const b64LeafHash = b64EncodeBytes(leafHash);

        const ctClient = new CTLogClient(log.url);

        const logSth = await ctClient.getSignedTreeHead();
        const expectedRootHash = b64DecodeBytes(logSth.sha256_root_hash);

        const proof = await ctClient.getProofByHash(
          b64LeafHash,
          logSth.tree_size,
        );

        const verificationResult = await validateProof(
          proof,
          leafHash,
          expectedRootHash,
        );

        console.log(`SCT ${verificationResult ? 'successfully verified' : 'verification failed'} in log "${log.description}", "${toHexString(sct.logId)}"`);
        // console.log(`SCT ${verificationResult ? 'successfully verified' : 'verification failed'} in log "${toHexString(sct.logId)}"`);
      }

    } catch (error) {
      console.error("Error validating cert:", error);
    }
})();
