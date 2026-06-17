import { get_fetch_handler } from "mbt:f4ah6o/blog.mbt/worker";
import markableSource from "virtual:blog-markable-source";

type FetchHandler = (
  request: Request,
  env: unknown,
  ctx: ExecutionContext,
  resolve?: (response: Response) => void,
  reject?: (reason: unknown) => void,
) => Response | Promise<Response> | { $tag: number; _0?: Response | unknown };

let handler: FetchHandler | null = null;

function getHandler(): FetchHandler {
  handler ??= get_fetch_handler() as FetchHandler;
  return handler;
}

function callMoonBitHandler(
  currentHandler: FetchHandler,
  request: Request,
  env: unknown,
  ctx: ExecutionContext,
): Response | Promise<Response> {
  if (currentHandler.length < 5) {
    return currentHandler(request, env, ctx) as Response | Promise<Response>;
  }

  return new Promise((resolve, reject) => {
    let settled = false;
    const safeResolve = (value: Response) => {
      if (!settled) {
        settled = true;
        resolve(value);
      }
    };
    const safeReject = (reason: unknown) => {
      if (!settled) {
        settled = true;
        reject(reason);
      }
    };

    const result = currentHandler(request, env, ctx, safeResolve, safeReject);
    if (result && typeof result === "object" && "$tag" in result) {
      if (result.$tag === 1) {
        if (result._0 !== undefined) {
          safeResolve(result._0 as Response);
        }
      } else {
        safeReject(result._0);
      }
    }
  });
}

export default {
  fetch(request: Request, env: unknown, ctx: ExecutionContext) {
    const url = new URL(request.url);
    if (url.pathname === "/generated/markable.js") {
      return new Response(markableSource, {
        headers: {
          "Cache-Control": "public, max-age=300",
          "Content-Type": "text/javascript; charset=utf-8",
        },
      });
    }
    return callMoonBitHandler(getHandler(), request, env, ctx);
  },
};
