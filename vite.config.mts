import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import tailwindcss from "tailwindcss";
import autoprefixer from "autoprefixer";

export default defineConfig({
  plugins: [
    RubyPlugin(),
  ],
  css: {
    postcss: {
      plugins: [tailwindcss(), autoprefixer()],
    },
  },
  build: {
    outDir: 'public/vite',
    assetsDir: '',
    rollupOptions: {
      input: {
        application: './app/frontend/entrypoints/application.js',
        admin: './app/frontend/entrypoints/admin.js',
      },
    },
    sourcemap: false,
  },
  appType: 'custom',
  server: {
    host: 'localhost',
    port: 3036,
    strictPort: true,
    open: true,
  },
});
