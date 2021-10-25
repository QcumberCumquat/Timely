import { defineConfig } from "vite";
import { createVuePlugin } from "vite-plugin-vue2";
import { VitePWA } from "vite-plugin-pwa";
import visualizer from "rollup-plugin-visualizer";
import dynamicImportVars from "@rollup/plugin-dynamic-import-vars";
const path = require("path");

export default defineConfig({
  plugins: [createVuePlugin(/* options */), VitePWA({})],
  build: {
    // generate manifest.json in outDir
    manifest: true,
    minify: true,
    sourcemap: true,
    emptyOutDir: true,
    rollupOptions: {
      // overwrite default .html entry
      input: "src/main.ts",
      plugins: [
        dynamicImportVars({
          // options
        }),
        visualizer(),
      ],
    },
    outDir: path.resolve(__dirname, "../priv/static"),
  },
  optimizeDeps: {
    exclude: ["date-fns"],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "/src"),
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/variables.scss";`,
        sassOptions: {
          quietDeps: true,
        },
      },
    },
  },
});
