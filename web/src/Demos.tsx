import { useState, useEffect, useCallback, useRef } from 'react'
import QRCode from 'qrcode'
import { encodeWebBundle, createWebBundle } from './glyphWebCrypto'
import { ALL_DEMOS, type DemoExperience } from './demoExperiences'
import './Demos.css'

// ─── AI Guess Camera (Glyph Draw — paused) ───────────────────────────
// AIGuessCamera component preserved in DrawGame.tsx.
// Draw demo commented out in demoExperiences.ts ALL_DEMOS array.
// To re-enable: uncomment the draw entry in ALL_DEMOS and restore
// the isDrawDemo logic + AIGuessCamera usage in DemoCard below.

// ─── Cycling QR Display ──────────────────────────────────────────────

function CyclingQR({
  chunks,
  intervalMs = 1200,
}: {
  chunks: string[]
  intervalMs?: number
}) {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  // Generate QR for current chunk
  useEffect(() => {
    if (chunks.length === 0) return
    const chunk = chunks[currentIndex % chunks.length]

    QRCode.toDataURL(chunk, {
      errorCorrectionLevel: 'L',
      margin: 3,
      width: 800,
      color: {
        dark: '#000000',
        light: '#ffffff',
      },
    }).then(setQrDataUrl)
  }, [chunks, currentIndex])

  // Cycle timer — restarts when intervalMs changes
  useEffect(() => {
    if (chunks.length <= 1) return

    timerRef.current = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % chunks.length)
    }, intervalMs)

    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [chunks, intervalMs])

  if (!qrDataUrl || chunks.length === 0) return null

  return (
    <div className="cycling-qr">
      <img src={qrDataUrl} alt="Cycling QR" className="cycling-qr-image" />
      <div className="cycling-qr-progress">
        <div className="cycling-qr-bar">
          {chunks.map((_, i) => (
            <div
              key={i}
              className={`cycling-qr-dot ${i === currentIndex % chunks.length ? 'active' : i < currentIndex % chunks.length ? 'done' : ''}`}
            />
          ))}
        </div>
        <span className="cycling-qr-count">
          Frame {(currentIndex % chunks.length) + 1} of {chunks.length}
        </span>
      </div>
    </div>
  )
}

// ─── Demo Card ────────────────────────────────────────────────────────

function DemoCard({ demo }: { demo: DemoExperience }) {
  const [chunks, setChunks] = useState<string[] | null>(null)
  const [isGenerating, setIsGenerating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [showQR, setShowQR] = useState(false)
  const [speed, setSpeed] = useState(1200)
  const qrRef = useRef<HTMLDivElement>(null)

  const generate = useCallback(async () => {
    setIsGenerating(true)
    setError(null)
    try {
      const bundle = createWebBundle(demo.title, demo.html, demo.templateType)
      const encryptedChunks = await encodeWebBundle(bundle)
      setChunks(encryptedChunks)
      setShowQR(true)
      setTimeout(() => {
        qrRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }, 200)
    } catch (e) {
      setError(`Failed to generate: ${e}`)
    } finally {
      setIsGenerating(false)
    }
  }, [demo])

  const speedLabel = speed >= 1000 ? `${(speed / 1000).toFixed(1)}s` : `${speed}ms`

  return (
    <div className="demo-card">
      <div className="demo-header">
        <span className="demo-icon">{demo.icon}</span>
        <div className="demo-info">
          <h3 className="demo-title">{demo.title}</h3>
          <span className="demo-type">{demo.templateType}</span>
        </div>
      </div>
      <p className="demo-description">{demo.description}</p>
      <div className="demo-meta">
        <span className="demo-frames">{demo.estimatedFrames}</span>
        <span className="demo-badge">AES-256-GCM + gzip</span>
      </div>

      {!showQR ? (
        <button
          className="demo-btn"
          onClick={generate}
          disabled={isGenerating}
        >
          {isGenerating ? 'Encrypting & chunking...' : 'Generate Cycling QR'}
        </button>
      ) : (
        <button
          className="demo-btn demo-btn-stop"
          onClick={() => {
            setShowQR(false)
            setChunks(null)
          }}
        >
          ■ Stop
        </button>
      )}

      {error && <div className="demo-error">{error}</div>}

      {showQR && chunks && (
        <div className="demo-qr-container" ref={qrRef}>
          <CyclingQR chunks={chunks} intervalMs={speed} />
          <div className="speed-control">
            <label className="speed-label">
              Speed: <strong>{speedLabel}</strong> per frame
            </label>
            <div className="speed-slider-row">
              <span className="speed-end">Fast</span>
              <input
                type="range"
                className="speed-slider"
                min={300}
                max={3000}
                step={100}
                value={speed}
                onChange={(e) => setSpeed(Number(e.target.value))}
              />
              <span className="speed-end">Slow</span>
            </div>
          </div>
          <p className="demo-scan-hint">
            Point your <strong>Glyph</strong> app camera at this cycling QR to
            receive the full experience
          </p>
        </div>
      )}
    </div>
  )
}

// ─── Demos Page ───────────────────────────────────────────────────────

export default function DemosPage() {
  return (
    <main className="demos-page">
      <div className="demos-content">
        <div className="demos-hero">
          <div className="demos-badge">Live Demos</div>
          <h1 className="demos-title">
            Experience <span className="demos-accent">Glyph</span>
          </h1>
          <p className="demos-subtitle">
            Each demo below generates a real encrypted, multi-frame QR
            experience. Open the Glyph app, tap scan, and point at the cycling
            QR code. The app reassembles the frames and decrypts the full
            experience on your device.
          </p>
        </div>

        <div className="demos-how">
          <div className="demos-how-step">
            <span className="demos-how-num">1</span>
            <span>Click &ldquo;Generate Cycling QR&rdquo; on any demo</span>
          </div>
          <div className="demos-how-arrow">&rarr;</div>
          <div className="demos-how-step">
            <span className="demos-how-num">2</span>
            <span>Open Glyph app &rarr; Scan</span>
          </div>
          <div className="demos-how-arrow">&rarr;</div>
          <div className="demos-how-step">
            <span className="demos-how-num">3</span>
            <span>Point camera at the cycling QR</span>
          </div>
          <div className="demos-how-arrow">&rarr;</div>
          <div className="demos-how-step">
            <span className="demos-how-num">4</span>
            <span>Experience opens on your phone!</span>
          </div>
        </div>

        <div className="demos-grid">
          {ALL_DEMOS.map((demo) => (
            <DemoCard key={demo.id} demo={demo} />
          ))}
        </div>
      </div>
    </main>
  )
}
