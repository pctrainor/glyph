// ─── Word Bank for Glyph Draw ─────────────────────────────────────────
// Simple, drawable words categorized by difficulty.

export interface DrawWord {
  word: string
  category: string
  difficulty: 'easy' | 'medium' | 'hard'
  hints?: string[] // acceptable alternate answers
}

export const WORD_BANK: DrawWord[] = [
  // ── Animals ──
  { word: 'cat', category: 'Animals', difficulty: 'easy', hints: ['kitten', 'kitty'] },
  { word: 'dog', category: 'Animals', difficulty: 'easy', hints: ['puppy', 'doggy'] },
  { word: 'fish', category: 'Animals', difficulty: 'easy' },
  { word: 'bird', category: 'Animals', difficulty: 'easy' },
  { word: 'snake', category: 'Animals', difficulty: 'easy' },
  { word: 'elephant', category: 'Animals', difficulty: 'medium' },
  { word: 'giraffe', category: 'Animals', difficulty: 'medium' },
  { word: 'butterfly', category: 'Animals', difficulty: 'medium' },
  { word: 'penguin', category: 'Animals', difficulty: 'medium' },
  { word: 'octopus', category: 'Animals', difficulty: 'hard' },
  { word: 'dolphin', category: 'Animals', difficulty: 'medium' },
  { word: 'turtle', category: 'Animals', difficulty: 'easy', hints: ['tortoise'] },
  { word: 'frog', category: 'Animals', difficulty: 'easy', hints: ['toad'] },
  { word: 'shark', category: 'Animals', difficulty: 'medium' },
  { word: 'spider', category: 'Animals', difficulty: 'easy' },

  // ── Food ──
  { word: 'pizza', category: 'Food', difficulty: 'easy' },
  { word: 'hamburger', category: 'Food', difficulty: 'easy', hints: ['burger', 'cheeseburger'] },
  { word: 'ice cream', category: 'Food', difficulty: 'easy', hints: ['icecream'] },
  { word: 'apple', category: 'Food', difficulty: 'easy' },
  { word: 'banana', category: 'Food', difficulty: 'easy' },
  { word: 'cake', category: 'Food', difficulty: 'easy' },
  { word: 'donut', category: 'Food', difficulty: 'easy', hints: ['doughnut'] },
  { word: 'taco', category: 'Food', difficulty: 'easy' },
  { word: 'sushi', category: 'Food', difficulty: 'medium' },
  { word: 'watermelon', category: 'Food', difficulty: 'medium' },

  // ── Objects ──
  { word: 'house', category: 'Objects', difficulty: 'easy', hints: ['home'] },
  { word: 'car', category: 'Objects', difficulty: 'easy', hints: ['automobile'] },
  { word: 'airplane', category: 'Objects', difficulty: 'medium', hints: ['plane', 'aeroplane', 'jet'] },
  { word: 'bicycle', category: 'Objects', difficulty: 'medium', hints: ['bike'] },
  { word: 'umbrella', category: 'Objects', difficulty: 'easy' },
  { word: 'guitar', category: 'Objects', difficulty: 'medium' },
  { word: 'piano', category: 'Objects', difficulty: 'medium' },
  { word: 'rocket', category: 'Objects', difficulty: 'medium', hints: ['spaceship'] },
  { word: 'lighthouse', category: 'Objects', difficulty: 'hard' },
  { word: 'telescope', category: 'Objects', difficulty: 'hard' },
  { word: 'scissors', category: 'Objects', difficulty: 'medium' },
  { word: 'key', category: 'Objects', difficulty: 'easy' },
  { word: 'clock', category: 'Objects', difficulty: 'easy', hints: ['watch'] },
  { word: 'book', category: 'Objects', difficulty: 'easy' },
  { word: 'candle', category: 'Objects', difficulty: 'easy' },

  // ── Nature ──
  { word: 'sun', category: 'Nature', difficulty: 'easy' },
  { word: 'moon', category: 'Nature', difficulty: 'easy' },
  { word: 'star', category: 'Nature', difficulty: 'easy' },
  { word: 'tree', category: 'Nature', difficulty: 'easy' },
  { word: 'flower', category: 'Nature', difficulty: 'easy' },
  { word: 'mountain', category: 'Nature', difficulty: 'easy' },
  { word: 'ocean', category: 'Nature', difficulty: 'medium', hints: ['sea', 'waves'] },
  { word: 'volcano', category: 'Nature', difficulty: 'medium' },
  { word: 'rainbow', category: 'Nature', difficulty: 'easy' },
  { word: 'lightning', category: 'Nature', difficulty: 'medium', hints: ['thunder', 'bolt'] },

  // ── People & Body ──
  { word: 'eye', category: 'People', difficulty: 'easy' },
  { word: 'hand', category: 'People', difficulty: 'easy' },
  { word: 'robot', category: 'People', difficulty: 'medium' },
  { word: 'ghost', category: 'People', difficulty: 'easy' },
  { word: 'alien', category: 'People', difficulty: 'medium' },
  { word: 'ninja', category: 'People', difficulty: 'medium' },
  { word: 'pirate', category: 'People', difficulty: 'medium' },

  // ── Places ──
  { word: 'castle', category: 'Places', difficulty: 'medium' },
  { word: 'island', category: 'Places', difficulty: 'medium' },
  { word: 'bridge', category: 'Places', difficulty: 'medium' },
  { word: 'train', category: 'Places', difficulty: 'easy' },
  { word: 'boat', category: 'Places', difficulty: 'easy', hints: ['ship'] },
]

/**
 * Pick a random word, optionally filtered by difficulty.
 */
export function pickRandomWord(difficulty?: DrawWord['difficulty']): DrawWord {
  const pool = difficulty ? WORD_BANK.filter(w => w.difficulty === difficulty) : WORD_BANK
  return pool[Math.floor(Math.random() * pool.length)]
}

/**
 * Fuzzy match a guess against the correct answer.
 * Returns true if close enough.
 */
export function fuzzyMatch(guess: string, answer: DrawWord): boolean {
  const normalize = (s: string) => s.toLowerCase().trim().replace(/[^a-z0-9 ]/g, '')
  const g = normalize(guess)
  const a = normalize(answer.word)

  // Exact match
  if (g === a) return true

  // Check hints
  if (answer.hints?.some(h => normalize(h) === g)) return true

  // Contains match (for compound words)
  if (a.includes(g) && g.length >= 3) return true
  if (g.includes(a) && a.length >= 3) return true

  // Levenshtein distance ≤ 2 for words > 4 chars
  if (a.length > 4 && levenshtein(g, a) <= 2) return true

  return false
}

function levenshtein(a: string, b: string): number {
  const m = a.length, n = b.length
  const dp: number[][] = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0))
  for (let i = 0; i <= m; i++) dp[i][0] = i
  for (let j = 0; j <= n; j++) dp[0][j] = j
  for (let i = 1; i <= m; i++)
    for (let j = 1; j <= n; j++)
      dp[i][j] = Math.min(
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)
      )
  return dp[m][n]
}
