import { cloudflare } from "@cloudflare/vite-plugin";
import { markable, markableClientScript } from "@f12o/markable/vite";
import { defineConfig } from "vite-plus";
import moonbit from "vite-plugin-moonbit";

const markable_options = {
  mode: "feedback" as const,
  locale: "ja" as const,
  endpoint: "/__markable/comments",
  poweredBy: true,
};

export default defineConfig(({ command }) => ({
  publicDir: "static",
  plugins: [
    moonbit({
      target: "js",
      watch: command === "serve",
      showLogs: true,
    }),
    markable({
      mode: "auto",
      locale: markable_options.locale,
      commentsFile: ".markable/comments.json",
      endpoint: markable_options.endpoint,
      poweredBy: markable_options.poweredBy,
    }),
    {
      name: "blog-markable-source",
      resolveId(id) {
        if (id === "virtual:blog-markable-source") {
          return "\0virtual:blog-markable-source";
        }
      },
      load(id) {
        if (id === "\0virtual:blog-markable-source") {
          return `export default ${JSON.stringify(markableClientScript(markable_options))};`;
        }
      },
    },
    cloudflare(),
  ],
  run: {
    tasks: {
      "moon:check": {
        command: "moon check --deny-warn --target js",
      },
      "moon:test": {
        command: "moon test --target js",
      },
      "release-check": {
        command:
          "moon fmt && moon info && moon check --deny-warn --target js && moon test --target js && pnpm exec vp build -c vite.markable.config.ts && moon build --release --target js && pnpm exec vp check src/worker-entry.ts src/client/markable.ts src/types.d.ts vite.config.ts vite.markable.config.ts package.json tsconfig.json && pnpm exec vp build",
      },
    },
  },
}));
