import { useState, useCallback, useRef, useEffect } from 'react'
import QRCode from 'qrcode'
import {
  encryptMessage,
  createMessage,
  EXPIRATION_OPTIONS,
} from './glyphCrypto'
import DemosPage from './Demos'
import './App.css'

// ─── Preset Messages ─────────────────────────────────────────────────

const PRESETS = [
  {
    label: 'Hello World',
    text: 'Hello from Glyph! This message will vanish after you read it.',
    expiration: 30,
  },
  {
    label: 'Secret Note',
    text: "This is a secret. Once your timer runs out, it\u2019s gone forever. No screenshots. No traces.",
    expiration: 10,
  },
  {
    label: 'Read Once',
    text: 'You get ONE look at this message. Make it count.',
    expiration: -1,
  },
  {
    label: '5 Minute Memo',
    text: 'You have 5 minutes to read this. Take your time... but not too much time.',
    expiration: 300,
  },
  {
    label: 'Welcome Tester',
    text: "Welcome to the Glyph beta! You\u2019re one of the first people to use vanishing QR messages. Try creating your own in the app!",
    expiration: 60,
  },
  {
    label: 'Permanent',
    text: 'This message lives forever. No timer, no expiration. Just a message in a QR code.',
    expiration: -2,
  },
]

// ─── App ──────────────────────────────────────────────────────────────

export default function App() {
  const [activeTab, setActiveTab] = useState<'home' | 'generate' | 'demos'>('home')

  return (
    <div className="app">
      <nav className="navbar">
        <div className="nav-brand">
          <img src={`${import.meta.env.BASE_URL}glyph-logo.svg`} alt="Glyph" className="nav-logo" />
          <span className="nav-title">Glyph</span>
        </div>
        <div className="nav-links">
          <button
            className={`nav-link ${activeTab === 'home' ? 'active' : ''}`}
            onClick={() => setActiveTab('home')}
          >
            Home
          </button>
          <button
            className={`nav-link ${activeTab === 'generate' ? 'active' : ''}`}
            onClick={() => setActiveTab('generate')}
          >
            Generate QR
          </button>
          <button
            className={`nav-link ${activeTab === 'demos' ? 'active' : ''}`}
            onClick={() => setActiveTab('demos')}
          >
            Demos
          </button>
          <a
            href="https://testflight.apple.com/join/YOUR_LINK"
            className="nav-cta"
            target="_blank"
            rel="noopener"
          >
            Get TestFlight
          </a>
        </div>
      </nav>

      {activeTab === 'home' ? (
        <HeroSection onGenerate={() => setActiveTab('generate')} onDemos={() => setActiveTab('demos')} />
      ) : activeTab === 'demos' ? (
        <DemosPage />
      ) : (
        <GeneratorSection />
      )}

      <footer className="footer">
        <div className="footer-content">
          <img src={`${import.meta.env.BASE_URL}glyph-logo.svg`} alt="Glyph" className="footer-logo" />
          <p>Glyph — Vanishing QR Messages</p>
          <p className="footer-sub">
            End-to-end encrypted with AES-256-GCM. Messages exist only in the
            moment.
          </p>
        </div>
      </footer>
    </div>
  )
}

// ─── Hero Section ─────────────────────────────────────────────────────

function HeroSection({ onGenerate, onDemos }: { onGenerate: () => void; onDemos: () => void }) {
  return (
    <main className="hero">
      <div className="hero-content">
        <div className="hero-badge">Beta — Now on TestFlight</div>
        <h1 className="hero-title">
          Messages that
          <br />
          <span className="hero-accent">vanish.</span>
        </h1>
        <p className="hero-subtitle">
          Compose a message. Encode it into an encrypted QR code. The receiver
          scans it — then it self-destructs. No servers. No cloud. No trace.
        </p>

        <div className="hero-actions">
          <button className="btn btn-primary" onClick={onGenerate}>
            Generate a Test QR
          </button>
          <button className="btn btn-secondary" onClick={onDemos}>
            Try Live Demos
          </button>
          <a
            href="https://testflight.apple.com/join/YOUR_LINK"
            className="btn btn-secondary"
            target="_blank"
            rel="noopener"
          >
            Download on TestFlight
          </a>
        </div>

        <div className="features">
          <div className="feature-card">
            <div className="feature-icon">AES</div>
            <h3>AES-256-GCM</h3>
            <p>
              Military-grade encryption. Every message gets a unique 256-bit
              key.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">T</div>
            <h3>Self-Destructing</h3>
            <p>
              Set a timer — 10 seconds, 30 seconds, read-once. Then it's gone.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">QR</div>
            <h3>No Servers</h3>
            <p>
              Everything lives in the QR code. No cloud, no database, no
              accounts.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">///</div>
            <h3>Scan to Reveal</h3>
            <p>
              Point your camera. The message appears. The countdown begins.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">AI</div>
            <h3>AI Agents</h3>
            <p>
              Chat with 6 unique AI personas — Oracle, Poet, Glitch, and more.
            </p>
          </div>
          <div className="feature-card">
            <div className="feature-icon">EXP</div>
            <h3>Experiences</h3>
            <p>
              Create interactive web experiences — trivia, stories, surveys —
              all in a QR code.
            </p>
          </div>
        </div>

        <div className="how-it-works">
          <h2>How It Works</h2>
          <div className="steps">
            <div className="step">
              <div className="step-number">1</div>
              <h3>Compose</h3>
              <p>Type your message in the app. Choose how long it lives.</p>
            </div>
            <div className="step-arrow">→</div>
            <div className="step">
              <div className="step-number">2</div>
              <h3>Encrypt</h3>
              <p>
                AES-256-GCM encrypts your message into a QR code on your device.
              </p>
            </div>
            <div className="step-arrow">→</div>
            <div className="step">
              <div className="step-number">3</div>
              <h3>Share</h3>
              <p>Show the QR code. The other person scans it with Glyph.</p>
            </div>
            <div className="step-arrow">→</div>
            <div className="step">
              <div className="step-number">4</div>
              <h3>Vanish</h3>
              <p>Timer starts. Message is read. Then it self-destructs.</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}

// ─── QR Generator Section ─────────────────────────────────────────────

function GeneratorSection() {
  const [message, setMessage] = useState('')
  const [expiration, setExpiration] = useState(30)
  const [senderName, setSenderName] = useState('')
  const [flashOnScan, setFlashOnScan] = useState(true)
  const [qrDataUrl, setQrDataUrl] = useState<string | null>(null)
  const [isGenerating, setIsGenerating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [encodedPayload, setEncodedPayload] = useState<string | null>(null)
  const qrRef = useRef<HTMLDivElement>(null)

  const generate = useCallback(async () => {
    if (!message.trim()) {
      setError('Type a message first!')
      return
    }

    setIsGenerating(true)
    setError(null)

    try {
      const payload = createMessage(message.trim(), {
        expirationSeconds: expiration,
        flashOnScan,
        senderName: senderName.trim() || undefined,
        senderHandle: senderName.trim() ? `@${senderName.trim().toLowerCase().replace(/\s+/g, '')}` : undefined,
      })

      const encrypted = await encryptMessage(payload)
      setEncodedPayload(encrypted)

      // Generate QR code as data URL
      const dataUrl = await QRCode.toDataURL(encrypted, {
        errorCorrectionLevel: 'L',
        margin: 2,
        width: 600,
        color: {
          dark: '#f0f0f5',
          light: '#0a0a0f',
        },
      })

      setQrDataUrl(dataUrl)

      // Scroll to QR
      setTimeout(() => {
        qrRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }, 100)
    } catch (e) {
      setError(`Encryption failed: ${e}`)
    } finally {
      setIsGenerating(false)
    }
  }, [message, expiration, senderName, flashOnScan])

  const loadPreset = (preset: (typeof PRESETS)[number]) => {
    setMessage(preset.text)
    setExpiration(preset.expiration)
    setQrDataUrl(null)
    setEncodedPayload(null)
  }

  const downloadQR = () => {
    if (!qrDataUrl) return
    const a = document.createElement('a')
    a.href = qrDataUrl
    a.download = `glyph-qr-${Date.now()}.png`
    a.click()
  }

  const expirationLabel =
    EXPIRATION_OPTIONS.find((o) => o.value === expiration)?.label ?? '30 seconds'

  return (
    <main className="generator">
      <div className="generator-content">
        <h1 className="generator-title">
          Generate a Glyph QR
        </h1>
        <p className="generator-subtitle">
          Create an encrypted QR code that Glyph app users can scan. The message
          is encrypted with AES-256-GCM — identical to what the app produces.
        </p>

        {/* Presets */}
        <div className="presets">
          <label className="field-label">Quick Presets</label>
          <div className="preset-grid">
            {PRESETS.map((p) => (
              <button
                key={p.label}
                className="preset-btn"
                onClick={() => loadPreset(p)}
              >
                {p.label}
              </button>
            ))}
          </div>
        </div>

        {/* Compose Form */}
        <div className="compose-form">
          <div className="field">
            <label className="field-label">Message</label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Type something that vanishes..."
              maxLength={2000}
            />
            <span className="char-count">{message.length}/2000</span>
          </div>

          <div className="field-row">
            <div className="field">
              <label className="field-label">Timer</label>
              <select
                value={expiration}
                onChange={(e) => setExpiration(Number(e.target.value))}
              >
                {EXPIRATION_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="field">
              <label className="field-label">Sender Name (optional)</label>
              <input
                type="text"
                value={senderName}
                onChange={(e) => setSenderName(e.target.value)}
                placeholder="Your name"
                maxLength={30}
              />
            </div>
          </div>

          <div className="field-row">
            <label className="toggle-field">
              <input
                type="checkbox"
                checked={flashOnScan}
                onChange={(e) => setFlashOnScan(e.target.checked)}
              />
              <span className="toggle-label">Flash on scan</span>
            </label>
          </div>

          <button
            className="btn btn-primary btn-generate"
            onClick={generate}
            disabled={isGenerating || !message.trim()}
          >
            {isGenerating ? 'Encrypting...' : 'Generate Encrypted QR'}
          </button>

          {error && <div className="error-msg">{error}</div>}
        </div>

        {/* QR Output */}
        {qrDataUrl && (
          <div className="qr-output" ref={qrRef}>
            <div className="qr-card">
              <div className="qr-badge">
                AES-256-GCM Encrypted \u00b7 {expirationLabel}
              </div>
              <img
                src={qrDataUrl}
                alt="Glyph QR Code"
                className="qr-image"
              />
              <p className="qr-instructions">
                Scan with the <strong>Glyph</strong> app to decrypt this message
              </p>
              <div className="qr-actions">
                <button className="btn btn-secondary" onClick={downloadQR}>
                  Download PNG
                </button>
                <button
                  className="btn btn-secondary"
                  onClick={() => {
                    if (encodedPayload) {
                      navigator.clipboard.writeText(encodedPayload)
                    }
                  }}
                >
                  Copy Payload
                </button>
              </div>
            </div>

            {encodedPayload && (
              <details className="payload-details">
                <summary>View encrypted payload ({encodedPayload.length} chars)</summary>
                <pre className="payload-text">{encodedPayload}</pre>
              </details>
            )}
          </div>
        )}
      </div>
    </main>
  )
}
