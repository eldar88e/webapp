import { defineConfig } from "vite";
import ViteRails from "vite-plugin-rails";
import tailwindcss from "@tailwindcss/vite";
import autoprefixer from "autoprefixer";
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    ViteRails({
      envVars: { RAILS_ENV: "development" },
      envOptions: { defineOn: "import.meta.env" },
      fullReload: {
        additionalPaths: ["config/routes.rb", "app/views/**/*", "app/components/**/*"],
        delay: 300,
      },
    }),
    react(),
    tailwindcss(),
  ],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
    postcss: {
      plugins: [autoprefixer()],
    },
  },
  build: {
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
