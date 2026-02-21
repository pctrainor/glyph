import { useState, useRef, useCallback, useEffect } from 'react'
import { pickRandomWord, fuzzyMatch, type DrawWord } from './wordBank'
import './DrawGame.css'

// ─── Types ────────────────────────────────────────────────────────────

interface Stroke {
  points: { x: number; y: number }[]
  color: string
  width: number
}

interface RoundResult {
  round: number
  word: DrawWord
  playerGuess: string
  playerCorrect: boolean
  aiGuess: string
  aiCorrect: boolean
  drawingDataUrl: string
}

type GamePhase = 'menu' | 'drawing' | 'guessing' | 'ai-thinking' | 'result' | 'final'

// ─── Constants ────────────────────────────────────────────────────────

const COLORS = ['#66d9ff', '#9966ff', '#ff4466', '#44dd88', '#ffaa33', '#ffffff']
const BRUSH_SIZES = [3, 6, 12]
const TIMER_OPTIONS = [15, 30, 60]
const TOTAL_ROUNDS = 5

// ─── Component ────────────────────────────────────────────────────────

export default function DrawGame() {
  // Game state
  const [phase, setPhase] = useState<GamePhase>('menu')
  const [round, setRound] = useState(0)
  const [timerDuration, setTimerDuration] = useState(30)
  const [timeLeft, setTimeLeft] = useState(30)
  const [currentWord, setCurrentWord] = useState<DrawWord | null>(null)
  const [playerGuess, setPlayerGuess] = useState('')
  const [aiGuess, setAiGuess] = useState('')
  const [aiThinking, setAiThinking] = useState(false)
  const [results, setResults] = useState<RoundResult[]>([])
  const [playerScore, setPlayerScore] = useState(0)
  const [aiScore, setAiScore] = useState(0)
  const [showConfetti, setShowConfetti] = useState(false)
  const [difficulty, setDifficulty] = useState<DrawWord['difficulty']>('easy')
  const [drawingSnapshot, setDrawingSnapshot] = useState('')

  // Canvas state
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [isDrawing, setIsDrawing] = useState(false)
  const [strokes, setStrokes] = useState<Stroke[]>([])
  const [currentStroke, setCurrentStroke] = useState<Stroke | null>(null)
  const [selectedColor, setSelectedColor] = useState(COLORS[0])
  const [brushSize, setBrushSize] = useState(BRUSH_SIZES[1])

  // Timer ref
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const guessInputRef = useRef<HTMLInputElement>(null)

  // ── Canvas Drawing ──────────────────────────────────────────────

  const getCanvasPoint = useCallback(
    (e: React.MouseEvent | React.TouchEvent) => {
      const canvas = canvasRef.current
      if (!canvas) return { x: 0, y: 0 }
      const rect = canvas.getBoundingClientRect()
      const scaleX = canvas.width / rect.width
      const scaleY = canvas.height / rect.height
      if ('touches' in e) {
        const touch = e.touches[0]
        return {
          x: (touch.clientX - rect.left) * scaleX,
          y: (touch.clientY - rect.top) * scaleY,
        }
      }
      return {
        x: (e.clientX - rect.left) * scaleX,
        y: (e.clientY - rect.top) * scaleY,
      }
    },
    []
  )

  const startDrawing = useCallback(
    (e: React.MouseEvent | React.TouchEvent) => {
      if (phase !== 'drawing') return
      e.preventDefault()
      const point = getCanvasPoint(e)
      setIsDrawing(true)
      setCurrentStroke({ points: [point], color: selectedColor, width: brushSize })
    },
    [phase, getCanvasPoint, selectedColor, brushSize]
  )

  const continueDrawing = useCallback(
    (e: React.MouseEvent | React.TouchEvent) => {
      if (!isDrawing || !currentStroke || phase !== 'drawing') return
      e.preventDefault()
      const point = getCanvasPoint(e)
      setCurrentStroke((prev) =>
        prev ? { ...prev, points: [...prev.points, point] } : null
      )
    },
    [isDrawing, currentStroke, phase, getCanvasPoint]
  )

  const stopDrawing = useCallback(() => {
    if (!isDrawing || !currentStroke) return
    setStrokes((prev) => [...prev, currentStroke])
    setCurrentStroke(null)
    setIsDrawing(false)
  }, [isDrawing, currentStroke])

  // Redraw canvas whenever strokes change
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'

    const allStrokes = currentStroke ? [...strokes, currentStroke] : strokes
    for (const stroke of allStrokes) {
      if (stroke.points.length < 2) continue
      ctx.strokeStyle = stroke.color
      ctx.lineWidth = stroke.width
      ctx.beginPath()
      ctx.moveTo(stroke.points[0].x, stroke.points[0].y)
      for (let i = 1; i < stroke.points.length; i++) {
        ctx.lineTo(stroke.points[i].x, stroke.points[i].y)
      }
      ctx.stroke()
    }
  }, [strokes, currentStroke])

  // ── Undo / Clear ────────────────────────────────────────────────

  const undo = () => setStrokes((prev) => prev.slice(0, -1))
  const clearCanvas = () => setStrokes([])

  // ── Game Flow ───────────────────────────────────────────────────

  const startGame = () => {
    setResults([])
    setPlayerScore(0)
    setAiScore(0)
    setRound(1)
    startRound(1)
  }

  const startRound = (roundNum: number) => {
    const word = pickRandomWord(difficulty)
    setCurrentWord(word)
    setStrokes([])
    setCurrentStroke(null)
    setPlayerGuess('')
    setAiGuess('')
    setTimeLeft(timerDuration)
    setPhase('drawing')
    setRound(roundNum)
  }

  // ── Capture drawing and move to guessing ─────────────────────

  const finishDrawing = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current)
    // Capture the canvas content BEFORE changing phase (which unmounts the canvas)
    const canvas = canvasRef.current
    const snapshot = canvas?.toDataURL('image/png') || ''
    setDrawingSnapshot(snapshot)
    if (navigator.vibrate) navigator.vibrate([200, 100, 200])
    setPhase('guessing')
    setTimeout(() => guessInputRef.current?.focus(), 100)
  }, [])

  // Timer countdown during drawing phase
  useEffect(() => {
    if (phase !== 'drawing') return

    timerRef.current = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timerRef.current!)
          // Time's up — capture and move to guessing
          // Use setTimeout to let the final render complete before capturing
          setTimeout(() => finishDrawing(), 50)
          return 0
        }
        return prev - 1
      })
    }, 1000)

    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [phase, finishDrawing])

  // ── Submit Guess → Ask AI ───────────────────────────────────────

  const submitGuess = async () => {
    if (!currentWord) return
    setPhase('ai-thinking')
    setAiThinking(true)

    // Use the captured snapshot (canvas is already unmounted)
    const dataUrl = drawingSnapshot

    // Call OpenAI Vision
    let aiGuessText = '(no guess)'
    try {
      aiGuessText = await askAI(dataUrl)
    } catch (err) {
      console.error('AI Vision error:', err)
      aiGuessText = '(error)'
    }

    setAiGuess(aiGuessText)
    setAiThinking(false)

    // Score
    const playerCorrect = fuzzyMatch(playerGuess, currentWord)
    const aiCorrect = fuzzyMatch(aiGuessText, currentWord)

    if (playerCorrect) {
      setPlayerScore((s) => s + 1)
      setShowConfetti(true)
      setTimeout(() => setShowConfetti(false), 2000)
    }
    if (aiCorrect) setAiScore((s) => s + 1)

    const roundResult: RoundResult = {
      round,
      word: currentWord,
      playerGuess,
      playerCorrect,
      aiGuess: aiGuessText,
      aiCorrect,
      drawingDataUrl: dataUrl,
    }
    setResults((prev) => [...prev, roundResult])
    setPhase('result')
  }

  // ── Next Round / End Game ───────────────────────────────────────

  const nextRound = () => {
    if (round >= TOTAL_ROUNDS) {
      setPhase('final')
      if (navigator.vibrate) navigator.vibrate([100, 50, 100, 50, 300])
    } else {
      startRound(round + 1)
    }
  }

  const backToMenu = () => {
    setPhase('menu')
    setResults([])
    setPlayerScore(0)
    setAiScore(0)
    setRound(0)
    setStrokes([])
  }

  // ── OpenAI Vision API (via serverless proxy) ─────────────────

  const askAI = async (imageDataUrl: string): Promise<string> => {
    const response = await fetch('/api/vision', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ imageDataUrl }),
    })

    if (!response.ok) {
      console.error('Vision API error:', response.status)
      return '(error)'
    }

    const data = await response.json()
    return data.guess || '(no response)'
  }

  // ── Render ──────────────────────────────────────────────────────

  return (
    <main className="draw-game">
      {/* ── Scoreboard (always visible during game) ── */}
      {phase !== 'menu' && phase !== 'final' && (
        <div className="dg-scoreboard">
          <div className="dg-score-item">
            <span className="dg-score-label">🧑 You</span>
            <span className="dg-score-value">{playerScore}</span>
          </div>
          <div className="dg-round-badge">
            Round {round}/{TOTAL_ROUNDS}
          </div>
          <div className="dg-score-item">
            <span className="dg-score-label">🤖 AI</span>
            <span className="dg-score-value">{aiScore}</span>
          </div>
        </div>
      )}

      {/* ── MENU ── */}
      {phase === 'menu' && (
        <div className="dg-menu">
          <div className="dg-menu-icon">🎨</div>
          <h1 className="dg-menu-title">Glyph Draw</h1>
          <p className="dg-menu-sub">
            Draw a picture. Then guess what you drew.
            <br />
            Can you beat the AI?
          </p>

          <div className="dg-menu-options">
            <div className="dg-option-group">
              <label className="dg-option-label">Timer</label>
              <div className="dg-option-buttons">
                {TIMER_OPTIONS.map((t) => (
                  <button
                    key={t}
                    className={`dg-option-btn ${timerDuration === t ? 'active' : ''}`}
                    onClick={() => { setTimerDuration(t); setTimeLeft(t) }}
                  >
                    {t}s
                  </button>
                ))}
              </div>
            </div>

            <div className="dg-option-group">
              <label className="dg-option-label">Difficulty</label>
              <div className="dg-option-buttons">
                {(['easy', 'medium', 'hard'] as const).map((d) => (
                  <button
                    key={d}
                    className={`dg-option-btn ${difficulty === d ? 'active' : ''}`}
                    onClick={() => setDifficulty(d)}
                  >
                    {d}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <button className="dg-start-btn" onClick={startGame}>
            Start Game
          </button>

          <p className="dg-menu-hint">
            Powered by OpenAI Vision · {TOTAL_ROUNDS} rounds · You vs. AI
          </p>
        </div>
      )}

      {/* ── DRAWING PHASE ── */}
      {phase === 'drawing' && currentWord && (
        <div className="dg-drawing-phase">
          <div className="dg-prompt">
            <span className="dg-prompt-label">Draw:</span>
            <span className="dg-prompt-word">{currentWord.word}</span>
            <span className={`dg-timer ${timeLeft <= 5 ? 'urgent' : ''}`}>
              {timeLeft}s
            </span>
          </div>

          <div className="dg-canvas-wrapper">
            <canvas
              ref={canvasRef}
              width={800}
              height={800}
              className="dg-canvas"
              onMouseDown={startDrawing}
              onMouseMove={continueDrawing}
              onMouseUp={stopDrawing}
              onMouseLeave={stopDrawing}
              onTouchStart={startDrawing}
              onTouchMove={continueDrawing}
              onTouchEnd={stopDrawing}
            />
          </div>

          <div className="dg-toolbar">
            <div className="dg-colors">
              {COLORS.map((c) => (
                <button
                  key={c}
                  className={`dg-color-btn ${selectedColor === c ? 'active' : ''}`}
                  style={{ backgroundColor: c }}
                  onClick={() => setSelectedColor(c)}
                />
              ))}
            </div>
            <div className="dg-brushes">
              {BRUSH_SIZES.map((s) => (
                <button
                  key={s}
                  className={`dg-brush-btn ${brushSize === s ? 'active' : ''}`}
                  onClick={() => setBrushSize(s)}
                >
                  <span
                    className="dg-brush-dot"
                    style={{ width: s + 4, height: s + 4 }}
                  />
                </button>
              ))}
            </div>
            <div className="dg-actions">
              <button className="dg-action-btn" onClick={undo} title="Undo">
                ↩
              </button>
              <button className="dg-action-btn" onClick={clearCanvas} title="Clear">
                ✕
              </button>
            </div>
          </div>

          <button
            className="dg-done-btn"
            onClick={finishDrawing}
          >
            Done Drawing
          </button>
        </div>
      )}

      {/* ── GUESSING PHASE ── */}
      {phase === 'guessing' && currentWord && (
        <div className="dg-guessing-phase">
          <div className="dg-guess-header">
            <div className="dg-guess-icon">⏱️</div>
            <h2>Time's up!</h2>
            <p>Now guess what you drew — the AI will guess too.</p>
          </div>

          <div className="dg-canvas-preview">
            <img
              src={drawingSnapshot}
              alt="Your drawing"
              className="dg-canvas small"
            />
          </div>

          <div className="dg-guess-input-wrapper">
            <input
              ref={guessInputRef}
              type="text"
              className="dg-guess-input"
              placeholder="Type your guess..."
              value={playerGuess}
              onChange={(e) => setPlayerGuess(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && playerGuess.trim()) submitGuess()
              }}
              autoComplete="off"
            />
            <button
              className="dg-guess-submit"
              disabled={!playerGuess.trim()}
              onClick={submitGuess}
            >
              Submit
            </button>
          </div>
        </div>
      )}

      {/* ── AI THINKING ── */}
      {phase === 'ai-thinking' && (
        <div className="dg-thinking">
          <div className="dg-thinking-spinner" />
          <h2>AI is analyzing your drawing...</h2>
          <p>GPT-4o Vision is studying your masterpiece</p>
        </div>
      )}

      {/* ── ROUND RESULT ── */}
      {phase === 'result' && currentWord && (
        <div className="dg-result">
          {showConfetti && <div className="dg-confetti" />}
          <div className="dg-result-answer">
            <span className="dg-result-label">The answer was</span>
            <span className="dg-result-word">{currentWord.word}</span>
          </div>

          <div className="dg-result-card-row">
            <div className={`dg-result-card ${results[results.length - 1]?.playerCorrect ? 'correct' : 'wrong'}`}>
              <div className="dg-result-card-icon">🧑</div>
              <div className="dg-result-card-label">You guessed</div>
              <div className="dg-result-card-guess">"{playerGuess || '(nothing)'}"</div>
              <div className="dg-result-card-verdict">
                {results[results.length - 1]?.playerCorrect ? '✅ Correct!' : '❌ Wrong'}
              </div>
            </div>

            <div className="dg-vs">VS</div>

            <div className={`dg-result-card ${results[results.length - 1]?.aiCorrect ? 'correct' : 'wrong'}`}>
              <div className="dg-result-card-icon">🤖</div>
              <div className="dg-result-card-label">AI guessed</div>
              <div className="dg-result-card-guess">"{aiGuess}"</div>
              <div className="dg-result-card-verdict">
                {results[results.length - 1]?.aiCorrect ? '✅ Correct!' : '❌ Wrong'}
              </div>
            </div>
          </div>

          <div className="dg-result-scores">
            <span>🧑 You: {playerScore}</span>
            <span>🤖 AI: {aiScore}</span>
          </div>

          <button className="dg-next-btn" onClick={nextRound}>
            {round >= TOTAL_ROUNDS ? 'See Final Results' : `Next Round →`}
          </button>
        </div>
      )}

      {/* ── FINAL RESULTS ── */}
      {phase === 'final' && (
        <div className="dg-final">
          <div className="dg-final-icon">
            {playerScore > aiScore ? '🏆' : playerScore === aiScore ? '🤝' : '🤖'}
          </div>
          <h1 className="dg-final-title">
            {playerScore > aiScore
              ? 'You Win!'
              : playerScore === aiScore
              ? "It's a Tie!"
              : 'AI Wins!'}
          </h1>
          <div className="dg-final-scores">
            <div className={`dg-final-score ${playerScore >= aiScore ? 'winner' : ''}`}>
              <span className="dg-final-score-label">🧑 You</span>
              <span className="dg-final-score-value">{playerScore}</span>
            </div>
            <div className={`dg-final-score ${aiScore >= playerScore ? 'winner' : ''}`}>
              <span className="dg-final-score-label">🤖 AI</span>
              <span className="dg-final-score-value">{aiScore}</span>
            </div>
          </div>

          <div className="dg-final-history">
            <h3>Round History</h3>
            {results.map((r, i) => (
              <div key={i} className="dg-history-row">
                <img src={r.drawingDataUrl} alt={r.word.word} className="dg-history-thumb" />
                <div className="dg-history-info">
                  <span className="dg-history-word">{r.word.word}</span>
                  <span className="dg-history-guesses">
                    You: "{r.playerGuess}" {r.playerCorrect ? '✅' : '❌'} · AI: "{r.aiGuess}" {r.aiCorrect ? '✅' : '❌'}
                  </span>
                </div>
              </div>
            ))}
          </div>

          <div className="dg-final-actions">
            <button className="dg-start-btn" onClick={startGame}>
              Play Again
            </button>
            <button className="dg-back-btn" onClick={backToMenu}>
              Back to Menu
            </button>
          </div>

          <div className="dg-final-cta">
            <p>Play Glyph Draw with friends — no internet needed.</p>
            <a
              href="https://testflight.apple.com/join/pJ72EpPS"
              target="_blank"
              rel="noopener"
              className="dg-cta-link"
            >
              Get Glyph on TestFlight →
            </a>
          </div>
        </div>
      )}
    </main>
  )
}
