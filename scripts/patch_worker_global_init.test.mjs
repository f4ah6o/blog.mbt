import assert from "node:assert/strict";
import { test } from "node:test";

import { patch_worker_bundle } from "./patch_worker_global_init.mjs";

test("moves MoonBit hasher randomness out of global scope", () => {
  const source = [
    "var _M0FPB12random__seed = () => crypto.getRandomValues(new Uint32Array(1))[0];",
    "var _M0FPB4seed = _M0FPB12random__seed();",
    "function hash() { return (_M0FPB4seed >>> 0); }",
  ].join("\n");

  const patched = patch_worker_bundle(source);
  assert.match(patched, /var _M0FPB4seed = 0;/);
  assert.match(patched, /function _M0FPB4get_seed\(\)/);
  assert.match(patched, /return \(_M0FPB4get_seed\(\) >>> 0\);/);
  assert.doesNotMatch(patched, /var _M0FPB4seed = _M0FPB12random__seed\(\);/);
});
