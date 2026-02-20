/**
 * GlyphCrypto — Web Crypto API implementation of Glyph's AES-256-GCM encryption.
 *
 * Mirrors the Swift GlyphCrypto module exactly:
 *   Wire format: GLY1E:<key-hex>:<nonce-hex>:<ciphertext-base64>
 *
 * The key is embedded in the QR payload (Tier 1 — proximity IS the security).
 */

// ─── Helpers ──────────────────────────────────────────────────────────

function arrayToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function base64Encode(data: Uint8Array): string {
  let binary = ''
  for (let i = 0; i < data.length; i++) {
    binary += String.fromCharCode(data[i])
  }
  return btoa(binary)
}

function base64Decode(str: string): Uint8Array {
  const binary = atob(str)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes
}

// ─── Constants ────────────────────────────────────────────────────────

const MAGIC_PREFIX = 'GLY1:'
const ENCRYPTED_PREFIX = 'GLY1E:'

// ─── GlyphMessage JSON shape ─────────────────────────────────────────

export interface GlyphMessagePayload {
  text: string
  expirationSeconds: number
  createdAt: number // seconds since 1970
  imageData?: string | null
  audioData?: string | null
  expiresAt?: number | null
  signature?: {
    displayName: string
    handle: string
    emoji: string
  } | null
  flashOnScan?: boolean | null
}

// ─── Encrypt ──────────────────────────────────────────────────────────

/**
 * Encrypt a GlyphMessage payload into the GLY1E: wire format.
 * Uses AES-256-GCM with a random key embedded in the output.
 */
export async function encryptMessage(
  message: GlyphMessagePayload
): Promise<string> {
  // 1. JSON encode (matches Swift's JSONEncoder with secondsSince1970)
  const json = JSON.stringify(message)
  const jsonBytes = new TextEncoder().encode(json)

  // 2. Base64 encode → prepend GLY1:
  const base64Payload = base64Encode(jsonBytes)
  const plainPayload = MAGIC_PREFIX + base64Payload

  // 3. Encrypt with AES-256-GCM

  // Drop the GLY1: prefix before encrypting (matches Swift: encrypts the base64 part only)
  const rawBase64 = plainPayload.slice(MAGIC_PREFIX.length)
  const dataToEncrypt = base64Decode(rawBase64)

  // Generate random 256-bit key
  const key = await crypto.subtle.generateKey(
    { name: 'AES-GCM', length: 256 },
    true, // extractable
    ['encrypt']
  )

  // Generate random 12-byte nonce (IV)
  const nonce = crypto.getRandomValues(new Uint8Array(12))

  // Encrypt
  const ciphertextWithTag = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: nonce },
    key,
    dataToEncrypt.buffer as ArrayBuffer
  )

  // Export key to raw bytes
  const keyBytes = new Uint8Array(await crypto.subtle.exportKey('raw', key))

  // 4. Format: GLY1E:<key-hex>:<nonce-hex>:<ciphertext+tag-base64>
  const keyHex = arrayToHex(keyBytes)
  const nonceHex = arrayToHex(nonce)
  const ctBase64 = base64Encode(new Uint8Array(ciphertextWithTag))

  return `${ENCRYPTED_PREFIX}${keyHex}:${nonceHex}:${ctBase64}`
}

/**
 * Create a GlyphMessage payload with sensible defaults.
 */
export function createMessage(
  text: string,
  options?: {
    expirationSeconds?: number
    flashOnScan?: boolean
    senderName?: string
    senderHandle?: string
    senderEmoji?: string
  }
): GlyphMessagePayload {
  const now = Date.now() / 1000 // seconds since 1970

  return {
    text,
    expirationSeconds: options?.expirationSeconds ?? 30,
    createdAt: now,
    imageData: null,
    audioData: null,
    expiresAt: null,
    signature:
      options?.senderName
        ? {
            displayName: options.senderName,
            handle: options.senderHandle ?? '',
            emoji: options.senderEmoji ?? '◆',
          }
        : null,
    flashOnScan: options?.flashOnScan ?? true,
  }
}

// ─── Expiration options (matches Swift enum) ──────────────────────────

export const EXPIRATION_OPTIONS = [
  { label: 'Read Once', value: -1 },
  { label: '10 seconds', value: 10 },
  { label: '30 seconds', value: 30 },
  { label: '1 minute', value: 60 },
  { label: '5 minutes', value: 300 },
  { label: 'No timer', value: -2 },
] as const
