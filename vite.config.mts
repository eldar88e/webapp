import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  build: {
    outDir: 'public/vite',
    assetsDir: '',
    rollupOptions: {
      input: {
        application: 'app/frontend/entrypoints/application.js',
      },
    },
    sourcemap: false,
  },
  server: {
    host: '127.0.0.1',
    port: 5173,
    strictPort: true,
    open: true,
  },
});
