import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { markable } from "@f12o/markable/vite";
import { defineConfig } from "vite-plus";

const root_dir = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  plugins: [
    markable({
      mode: "auto",
      locale: "ja",
      commentsFile: ".markable/comments.json",
      endpoint: "/__markable/comments",
      poweredBy: true,
      inject: false,
    }),
  ],
  build: {
    outDir: "static/generated",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        markable: resolve(root_dir, "src/client/markable.ts"),
      },
      output: {
        entryFileNames: "[name].js",
      },
    },
  },
});
