import fs from 'fs';
import { AsnSerializer, AsnParser } from "@peculiar/asn1-schema";
import { Certificate } from "@peculiar/asn1-x509";

/**
 * Utility method to convert base64 to Uint8Array
 */
export function b64DecodeBytes(base64: string): Uint8Array {
  const buffer = Buffer.from(base64, 'base64');
  return new Uint8Array(buffer);
}

/**
 * Utility method to convert Uint8Array to base64
 */
export function b64EncodeBytes(bytes: Uint8Array): string {
  return Buffer.from(bytes).toString('base64');
}

/**
 * Outputs a hex string representation of an ArrayBuffer
 * 
 * This can be used for debugging the log ID
 * 
 * @param buffer
 * @returns
 */
export const toHexString = (buffer: ArrayBuffer): string => {
  const bytes = new Uint8Array(buffer);
  return Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0').toUpperCase())
    .join(':');
}

/**
 * Load PEM certificate and convert it to DER format
 *
 * @param filename
 * @returns
 */
export const loadCertificateDER = (filename: string) => {
  const pem = fs.readFileSync(filename, 'utf8')
      .replace('-----BEGIN CERTIFICATE-----','')
      .replace('-----END CERTIFICATE-----','')
      .replace(/\n/g,'');

  const cert = AsnParser.parse(Buffer.from(pem, "base64"), Certificate);

  return new Uint8Array(AsnSerializer.serialize(cert))
};

export const base64EncodeLogId = (logIdHex: string): string => {
  const bytes = new Uint8Array(logIdHex.split(':').map(byte => parseInt(byte, 16)));
    return b64EncodeBytes(bytes);
}

export const base64EncodePublicKey = (publicKeyDer: string): string => {
  const bytes = new Uint8Array(publicKeyDer.split('').map(byte => byte.charCodeAt(0)));
  return b64EncodeBytes(bytes);
}
