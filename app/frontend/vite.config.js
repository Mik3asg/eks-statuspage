import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      // Forward API calls and WebSocket to the backend during local dev
      '/api': 'http://localhost:3000',
      '/ws':  { target: 'ws://localhost:3000', ws: true },
    },
  },
});
