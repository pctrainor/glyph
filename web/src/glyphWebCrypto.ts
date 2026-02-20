/**
 * GlyphWebCrypto — Full web bundle encoding pipeline for TypeScript.
 *
 * Mirrors the Swift GlyphWebBundle + GlyphWebChunkSplitter + GlyphCrypto:
 *
 *   1. JSON encode GlyphWebBundle
 *   2. Deflate compress (zlib raw)
 *   3. Base64 → prepend GLYW:
 *   4. Encrypt entire payload → GLYWE:<key>:<nonce>:<ct>
 *   5. Split into chunks → GLYC: frames
 *   6. Encrypt each chunk → GLYCE:<key>:<nonce>:<ct>
 *
 * Uses Web Crypto API for AES-256-GCM and pako for zlib compression.
 */

// ─── Helpers ──────────────────────────────────────────────────────────

function arrayToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

function b64Encode(data: Uint8Array): string {
  let binary = ''
  for (let i = 0; i < data.length; i++) {
    binary += String.fromCharCode(data[i])
  }
  return btoa(binary)
}

function b64Decode(str: string): Uint8Array {
  const binary = atob(str)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes
}

function textToBytes(str: string): Uint8Array {
  return new TextEncoder().encode(str)
}

// ─── Zlib Compression (raw deflate) ──────────────────────────────────

/**
 * Compress data using raw deflate (matching Apple's COMPRESSION_ZLIB).
 * Uses the browser's CompressionStream API.
 */
async function deflateCompress(data: Uint8Array): Promise<Uint8Array> {
  const cs = new CompressionStream('deflate-raw')
  const writer = cs.writable.getWriter()
  writer.write(new Uint8Array(data.buffer.slice(0)) as unknown as BufferSource)
  writer.close()

  const reader = cs.readable.getReader()
  const chunks: Uint8Array[] = []
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    chunks.push(value)
  }

  const totalLength = chunks.reduce((sum, c) => sum + c.length, 0)
  const result = new Uint8Array(totalLength)
  let offset = 0
  for (const chunk of chunks) {
    result.set(chunk, offset)
    offset += chunk.length
  }
  return result
}

// ─── AES-256-GCM Encryption ──────────────────────────────────────────

interface EncryptResult {
  keyHex: string
  nonceHex: string
  ciphertextBase64: string
}

/**
 * Encrypt data with a fresh random AES-256-GCM key.
 * Returns key, nonce, and ciphertext+tag (all formatted for wire).
 */
async function aesEncrypt(data: Uint8Array): Promise<EncryptResult> {
  const key = await crypto.subtle.generateKey(
    { name: 'AES-GCM', length: 256 },
    true,
    ['encrypt']
  )
  const nonce = crypto.getRandomValues(new Uint8Array(12))

  const ciphertextWithTag = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: nonce },
    key,
    data.buffer as ArrayBuffer
  )

  const keyBytes = new Uint8Array(await crypto.subtle.exportKey('raw', key))

  return {
    keyHex: arrayToHex(keyBytes),
    nonceHex: arrayToHex(nonce),
    ciphertextBase64: b64Encode(new Uint8Array(ciphertextWithTag)),
  }
}

// ─── Constants ────────────────────────────────────────────────────────

const GLYW_PREFIX = 'GLYW:'
const GLYWE_PREFIX = 'GLYWE:'
const GLYC_PREFIX = 'GLYC:'
const GLYCE_PREFIX = 'GLYCE:'

/**
 * Max chars of base64 data per chunk.
 * iOS uses 800 but that produces GLYCE: strings of ~1600+ chars
 * which creates very dense QR codes (version 28+) that are nearly
 * impossible for phone cameras to scan from a screen display.
 * Using 200 keeps each GLYCE: string under ~600 chars (QR version ~15)
 * which scans reliably from monitors/screens.
 * More frames, but every frame actually scans.
 */
const MAX_CHUNK_BYTES = 200

// ─── Web Bundle Types ─────────────────────────────────────────────────

export interface GlyphWebBundle {
  title: string
  html: string
  templateType: string | null
  createdAt: number // seconds since 1970
  expiresAt: number | null
}

interface GlyphChunk {
  sessionId: string
  index: number
  total: number
  data: string // base64 slice
}

// ─── Full Pipeline ────────────────────────────────────────────────────

/**
 * Encode a GlyphWebBundle into an array of encrypted chunk strings.
 * Each string is a complete GLYCE: payload ready for QR code generation.
 *
 * Pipeline: JSON → gzip → base64 → GLYW: → encrypt → GLYWE: → chunk → GLYC: → encrypt → GLYCE:
 */
export async function encodeWebBundle(
  bundle: GlyphWebBundle
): Promise<string[]> {
  // 1. JSON encode
  const json = JSON.stringify(bundle)
  const jsonBytes = textToBytes(json)

  // 2. Compress (raw deflate, matching Apple COMPRESSION_ZLIB)
  const compressed = await deflateCompress(jsonBytes)

  console.log(
    `🗜️ Web bundle: ${jsonBytes.length} bytes → ${compressed.length} bytes (${(jsonBytes.length / compressed.length).toFixed(1)}:1)`
  )

  // 3. Base64 → GLYW: prefix
  const compressedBase64 = b64Encode(compressed)
  const plainPayload = GLYW_PREFIX + compressedBase64

  // 4. Encrypt entire payload → GLYWE:
  const payloadToEncrypt = b64Decode(compressedBase64) // encrypt the compressed data
  const bundleEncrypted = await aesEncrypt(payloadToEncrypt)
  const encryptedPayload = `${GLYWE_PREFIX}${bundleEncrypted.keyHex}:${bundleEncrypted.nonceHex}:${bundleEncrypted.ciphertextBase64}`

  console.log(`🔐 Encrypted payload: ${encryptedPayload.length} chars`)

  // 5. Convert encrypted payload to base64 for chunking
  const payloadBytes = textToBytes(encryptedPayload)
  const payloadBase64ForChunking = b64Encode(payloadBytes)

  // 6. Split into chunks
  const sessionId = crypto.randomUUID().slice(0, 8)
  const slices: string[] = []
  for (let i = 0; i < payloadBase64ForChunking.length; i += MAX_CHUNK_BYTES) {
    slices.push(payloadBase64ForChunking.slice(i, i + MAX_CHUNK_BYTES))
  }

  const total = slices.length
  console.log(`📦 Split into ${total} chunks`)

  // 7. Encode and encrypt each chunk → GLYCE:
  const encryptedChunks: string[] = []
  for (let i = 0; i < slices.length; i++) {
    const chunk: GlyphChunk = {
      sessionId,
      index: i,
      total,
      data: slices[i],
    }

    // Encode chunk as GLYC:<base64(json)>
    const chunkJson = JSON.stringify(chunk)
    const chunkBase64 = b64Encode(textToBytes(chunkJson))
    const chunkPlain = GLYC_PREFIX + chunkBase64

    // Encrypt chunk body (everything after GLYC:)
    const chunkBody = textToBytes(chunkBase64)
    const chunkEncrypted = await aesEncrypt(chunkBody)
    const encryptedChunk = `${GLYCE_PREFIX}${chunkEncrypted.keyHex}:${chunkEncrypted.nonceHex}:${chunkEncrypted.ciphertextBase64}`

    encryptedChunks.push(encryptedChunk)
  }

  console.log(`✅ Generated ${encryptedChunks.length} encrypted chunk strings`)
  return encryptedChunks
}

/**
 * Create a GlyphWebBundle from HTML content.
 */
export function createWebBundle(
  title: string,
  html: string,
  templateType: string | null = null
): GlyphWebBundle {
  return {
    title,
    html,
    templateType,
    createdAt: Date.now() / 1000,
    expiresAt: null,
  }
}
