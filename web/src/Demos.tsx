import { useState, useEffect, useCallback, useRef } from 'react'
import QRCode from 'qrcode'
import { encodeWebBundle, createWebBundle } from './glyphWebCrypto'
import { ALL_DEMOS, type DemoExperience } from './demoExperiences'
import './Demos.css'

// ─── AI Guess Camera ─────────────────────────────────────────────────

function AIGuessCamera({ onClose }: { onClose: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const [phase, setPhase] = useState<'camera' | 'thinking' | 'result'>('camera')
  const [aiGuess, setAiGuess] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [capturedImage, setCapturedImage] = useState<string | null>(null)

  // Start camera
  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
        })
        if (cancelled) {
          stream.getTracks().forEach((t) => t.stop())
          return
        }
        streamRef.current = stream
        if (videoRef.current) {
          videoRef.current.srcObject = stream
          videoRef.current.play()
        }
      } catch (err) {
        setError('Could not access camera. Please allow camera permissions.')
      }
    })()
    return () => {
      cancelled = true
      streamRef.current?.getTracks().forEach((t) => t.stop())
    }
  }, [])

  const capture = useCallback(async () => {
    const video = videoRef.current
    const canvas = canvasRef.current
    if (!video || !canvas) return

    // Capture frame
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    const ctx = canvas.getContext('2d')!
    ctx.drawImage(video, 0, 0)
    const dataUrl = canvas.toDataURL('image/jpeg', 0.8)
    setCapturedImage(dataUrl)

    // Stop camera
    streamRef.current?.getTracks().forEach((t) => t.stop())

    // Send to AI
    setPhase('thinking')
    try {
      const response = await fetch('/api/vision', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ imageDataUrl: dataUrl }),
      })

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`)
      }

      const data = await response.json()
      setAiGuess(data.guess || '(no response)')
      setPhase('result')
    } catch (err) {
      console.error('AI Vision error:', err)
      setError('Failed to get AI guess. Please try again.')
      setPhase('result')
    }
  }, [])

  const retry = useCallback(async () => {
    setCapturedImage(null)
    setAiGuess('')
    setError(null)
    setPhase('camera')
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
      })
      streamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        videoRef.current.play()
      }
    } catch {
      setError('Could not access camera.')
    }
  }, [])

  return (
    <div className="ai-guess-overlay">
      <div className="ai-guess-modal">
        <button className="ai-guess-close" onClick={onClose}>✕</button>

        {phase === 'camera' && (
          <>
            <h2 className="ai-guess-title">🤖 AI Guess</h2>
            <p className="ai-guess-sub">
              Point your camera at the drawing on your phone, then capture!
            </p>
            {error ? (
              <div className="ai-guess-error">{error}</div>
            ) : (
              <>
                <div className="ai-guess-viewfinder">
                  <video ref={videoRef} playsInline muted className="ai-guess-video" />
                  <div className="ai-guess-crosshair" />
                </div>
                <button className="ai-guess-capture" onClick={capture}>
                  📸 Capture & Guess
                </button>
              </>
            )}
          </>
        )}

        {phase === 'thinking' && (
          <div className="ai-guess-thinking">
            <div className="dg-thinking-spinner" />
            <h2>AI is analyzing...</h2>
            <p>GPT-4o Vision is studying the drawing</p>
          </div>
        )}

        {phase === 'result' && (
          <div className="ai-guess-result">
            {capturedImage && (
              <img src={capturedImage} alt="Captured" className="ai-guess-captured" />
            )}
            {error ? (
              <div className="ai-guess-error">{error}</div>
            ) : (
              <>
                <div className="ai-guess-answer">
                  <span className="ai-guess-label">The AI guesses:</span>
                  <span className="ai-guess-word">{aiGuess}</span>
                </div>
                <p className="ai-guess-hint">Did the AI get it right? Check the answer on your phone!</p>
              </>
            )}
            <div className="ai-guess-actions">
              <button className="ai-guess-retry" onClick={retry}>
                📸 Try Again
              </button>
              <button className="ai-guess-done" onClick={onClose}>
                Done
              </button>
            </div>
          </div>
        )}

        <canvas ref={canvasRef} style={{ display: 'none' }} />
      </div>
    </div>
  )
}

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
  const [showAIGuess, setShowAIGuess] = useState(false)
  const qrRef = useRef<HTMLDivElement>(null)
  const isDrawDemo = demo.id === 'draw'

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
            {isDrawDemo ? (
              <>
                Scan with <strong>Glyph</strong> to get the draw game on your phone.
                Once you&apos;ve drawn, hold up your phone and click the button below!
              </>
            ) : (
              <>
                Point your <strong>Glyph</strong> app camera at this cycling QR to
                receive the full experience
              </>
            )}
          </p>
          {isDrawDemo && (
            <button
              className="demo-btn ai-guess-btn"
              onClick={() => setShowAIGuess(true)}
            >
              🤖 AI Guess My Drawing
            </button>
          )}
        </div>
      )}

      {showAIGuess && (
        <AIGuessCamera onClose={() => setShowAIGuess(false)} />
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
