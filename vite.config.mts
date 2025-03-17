import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from "tailwindcss";
import autoprefixer from "autoprefixer";

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
    postcss: {
      plugins: [tailwindcss(), autoprefixer()],
    },
  },
  build: {
    rollupOptions: {
      input: {
        application: './app/frontend/entrypoints/application.js',
        admin: './app/frontend/entrypoints/admin.js',
      },
    },
    chunkSizeWarningLimit: 800,
    sourcemap: false,
  },
  server: {
    host: 'localhost',
    port: 3036,
    strictPort: true,
    open: true,
  },
});
