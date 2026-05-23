# @superset/web

Main web application (app.superset.sh). See the root `AGENTS.md` for monorepo conventions.

## End-to-end tests

Playwright specs live in `apps/web/e2e/` and exist so coding agents (and you) can self-verify UI changes locally before declaring work done. They are deliberately **not** wired into CI — see the parent `AGENTS.md` / agent memory for the rationale.

### Running

First-time setup (once per machine):

```bash
cd apps/web
bunx playwright install --with-deps chromium
```

From the repo root:

```bash
bun run test:e2e
```

The Playwright config (`playwright.config.ts`) uses the `webServer` option to boot `bun run dev` automatically and reuses the server if one is already running on `WEB_PORT` (default 3000). The dev server needs the usual `.env` at the repo root — DB URL, auth secret, etc.

Override the base URL to hit a deployed preview:

```bash
PLAYWRIGHT_BASE_URL=https://preview.example.com bun run test:e2e
```

### Adding new specs

Drop a `<feature>.spec.ts` file under `apps/web/e2e/`. Mirror the shape of `sign-in.spec.ts`.

### What's currently covered

- `e2e/sign-in.spec.ts` — `/sign-in` renders the "Welcome back" heading, the GitHub + Google provider buttons, and a sign-up link.
