# herdr-extensions

Versioned pi extensions for herdr orchestration (this directory is tracked by
the dotfiles repo).

| File | Contents |
|------|----------|
| `herdr-orchestration.ts` | The customization point: `herdr_delegate`, `herdr_fleet`, `herdr_worker_status`, `herdr_worker_steer`, `herdr_finalize`, `/herdr-workers`. |

## How pi loads it

`~/.pi/agent/settings.json` → `"extensions": ["/Users/jorgerojas/.dotfiles/herdr-extensions"]`.

Important:

- The entry must be a **plain directory path**. A glob entry only *filters*
  already-discovered files (pi's `resolveLocalEntries`: globs are patterns
  applied over plain paths + auto-discovery, they do not discover files).
- A directory entry is scanned like an extensions dir: top-level `*.ts` are
  loaded, subdirectories only if they contain `index.ts` (or a pi manifest).
- The auto-discovered `~/.pi/agent/extensions` must **not** contain a copy of
  `herdr-orchestration.ts` (double registration). The herdr-managed
  `herdr-agent-state.ts` and the `*_bridge.ts` hooks stay there on purpose.
- Extension changes apply on the next pi session (they are loaded at startup);
  do not forget `/reload` never re-reads an old copy.

## Hygiene

- Edit here, never in `~/.pi/agent/extensions`.
- Keep `HERDR_ORCH_STATE_EXT` (default `~/.pi/agent/extensions/herdr-agent-state.ts`)
  pointing at the herdr-managed state reporter.
- Smoke-check every edit with `node smoke-load.mjs` — it loads the extension
  through the exact jiti loader pi uses (createJiti, `moduleCache: false`) and
  runs the factory with a stub API. Do NOT rely on `pi --list-models` for this:
  pi collects extension load errors as diagnostics there and still exits 0, so a
  parse error like `ParseError: Unexpected token` only surfaces on a real startup.