import type { VercelRequest, VercelResponse } from '@vercel/node'

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')

  if (req.method === 'OPTIONS') {
    return res.status(200).end()
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  const apiKey = process.env.OPENAI_API_KEY
  if (!apiKey) {
    return res.status(500).json({ error: 'API key not configured' })
  }

  try {
    const { imageDataUrl } = req.body

    if (!imageDataUrl || typeof imageDataUrl !== 'string') {
      return res.status(400).json({ error: 'Missing imageDataUrl' })
    }

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        max_tokens: 20,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: 'This is a hand-drawn sketch from a Pictionary game. What is this a drawing of? Respond with ONLY your single best guess — one or two words, nothing else.',
              },
              {
                type: 'image_url',
                image_url: { url: imageDataUrl, detail: 'low' },
              },
            ],
          },
        ],
      }),
    })

    if (!response.ok) {
      const errData = await response.json().catch(() => ({}))
      return res.status(response.status).json({
        error: 'OpenAI API error',
        detail: errData,
      })
    }

    const data = await response.json()
    const guess =
      data.choices?.[0]?.message?.content
        ?.trim()
        .toLowerCase()
        .replace(/[."'!]/g, '') || '(no response)'

    return res.status(200).json({ guess })
  } catch (err: any) {
    console.error('Vision API error:', err)
    return res.status(500).json({ error: 'Internal server error' })
  }
}
