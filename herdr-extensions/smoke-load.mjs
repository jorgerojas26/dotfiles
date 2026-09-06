// Smoke test: load herdr-orchestration.ts with the SAME jiti loader pi uses
// (createJiti + moduleCache:false) and run its factory with a stub API.
//
// Why this exists: `pi --list-models` does NOT surface extension load errors
// (pi collects them as diagnostics and still exits 0), so it is useless as a
// parse check. Load pi the way pi does: jiti/static.
//
// Run:   node smoke-load.mjs   (from this directory or anywhere)
// Fails (exit 1) with the exact error pi shows on startup if the file does not
// parse or the factory throws.

import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const EXT = process.env.HERDR_ORCH_EXT || join(HERE, "herdr-orchestration.ts");

// Resolve the pi global node_modules (the extension imports typebox, which pi
// provides to extensions as an alias; jiti needs the same alias here).
const CANDIDATES = [
  process.env.PI_GLOBAL_NM,
  "/Users/jorgerojas/.bun/install/global/node_modules",
  "/usr/local/lib/node_modules",
].filter(Boolean);

function joinIfExists(base, p) {
  const full = join(base, p);
  return existsSync(full) ? full : undefined;
}

function resolveCandidates(rel) {
  for (const base of CANDIDATES) {
    const found = joinIfExists(base, rel);
    if (found) return found;
  }
  throw new Error(`Cannot find ${rel} under any of: ${CANDIDATES.join(", ")}`);
}

const jitiStatic = resolveCandidates("jiti/lib/jiti-static.mjs");
const typebox = resolveCandidates("typebox/build/index.mjs");
const typeboxCompile = resolveCandidates("typebox/build/compile/index.mjs");
const typeboxValue = resolveCandidates("typebox/build/value/index.mjs");

const { createJiti } = await import(jitiStatic);

const jiti = createJiti(import.meta.url, {
  moduleCache: false,
  alias: {
    typebox,
    "typebox/compile": typeboxCompile,
    "typebox/value": typeboxValue,
    "@sinclair/typebox": typebox,
  },
});

const mod = await jiti.import(EXT, { default: true });
if (typeof mod !== "function") {
  throw new Error(`Extension does not export a factory function (got ${typeof mod})`);
}

const tools = [];
const commands = [];
const stubPi = {
  on: () => {},
  registerTool: (t) => tools.push(t.name),
  registerCommand: (n) => commands.push(n),
};
await mod(stubPi);

const expected = ["herdr_delegate", "herdr_fleet", "herdr_worker_status", "herdr_worker_steer", "herdr_finalize"];
const missing = expected.filter((t) => !tools.includes(t));
if (missing.length) {
  throw new Error(`Missing expected tools: ${missing.join(", ")} (got: ${tools.sort().join(", ")})`);
}
console.log(`OK: ${EXT}`);
console.log(`  tools: ${tools.sort().join(", ")}`);
console.log(`  commands: ${commands.join(", ") || "(none)"}`);