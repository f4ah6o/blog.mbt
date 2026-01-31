let handler = null;
export default {
  async fetch(request, env, ctx) {
    if (handler === null) {
      const mod = await import("../target/js/release/build/worker/worker.js");
      handler = mod.get_fetch_handler();
    }
    if (handler.length >= 5) {
      return new Promise((resolve, reject) => {
        let settled = false;
        const safeResolve = (value) => {
          if (!settled) {
            settled = true;
            resolve(value);
          }
        };
        const safeReject = (err) => {
          if (!settled) {
            settled = true;
            reject(err);
          }
        };
        const result = handler(request, env, ctx, safeResolve, safeReject);
        if (result && typeof result === "object" && "$tag" in result) {
          if (result.$tag === 1) {
            if (result._0 !== undefined) {
              safeResolve(result._0);
            }
          } else {
            safeReject(result._0);
          }
        }
      });
    }
    return handler(request, env, ctx);
  },
};
