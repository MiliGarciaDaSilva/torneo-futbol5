import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Todo lo que empieza con /api se reenvía al backend sin el /api (así el navegador no choca con CORS).
// En docker compose API_URL apunta al servicio api.
const API_URL = process.env.API_URL ?? 'http://localhost:8000'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: API_URL,
        changeOrigin: true,
        rewrite: (ruta) => ruta.replace(/^\/api/, ''),
      },
    },
  },
})
