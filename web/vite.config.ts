import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/glyph/',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
