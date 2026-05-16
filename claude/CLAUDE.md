# Global Development Standards

> Machine-wide defaults. Project-level `CLAUDE.md` overrides where needed.

## Security

- **Never read `.env` files.** Do not read, cat, print, or display the contents of any `.env`, `.env.local`, `.env.production`, or similar environment files. Reference `.env.example` for variable names instead.

## Custom Agents

- **`oda-agent`** — Autonomous code generation agent. Generates a PRD, breaks it into ordered tasks, then runs a Worker→Reviewer loop per task until all pass. Invoke for end-to-end feature implementation.

## Git

- Use git flow for all git commands
- Use conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- **Never add Co-Authored-By lines** to commit messages
- Commits and pushes are authored by the user only

## Bun

> **Full reference → [docs/BUN.md](docs/bun.md)** — runtime, package management, file extensions, imports, native APIs, env vars, testing, tsconfig.

All projects use **Bun** unless a project-level `CLAUDE.md` says otherwise.

- Use Winston logger for logging — no `console.log` statements

## TypeScript

> tsconfig baseline and file extension rules are in [docs/BUN.md](docs/bun.md).

All TypeScript must be in **strict mode**. No exceptions.

- **Never use `any`** — use explicit types, interfaces, or `unknown`
- Prefer `interface` for object shapes; `type` for unions and aliases
- Use `satisfies` over type assertions; avoid `as` unless absolutely necessary
- Use `as const` objects or `const enum` — not regular enums
- All functions must have explicit return types and access modifiers
- Use `readonly` on interface properties only when explicitly required — do not add readonly by default
- **One interface per file** — use `i-` prefix (e.g. `i-card.mts`); group in `interfaces/` folder by feature; barrel via `index.mts`
- Ensure `.mts` imports are switched to `.mjs` in import specifiers
- If imports use `.mts` extension, ensure `tsconfig.json` has `noEmit` set to `true`

### Error Handling

- Use `Result<T, E>` types or discriminated unions for recoverable errors
- Reserve `throw` for truly unexpected errors
- Prefer typed error classes over generic `Error`

### Validation with TypeBox

- **Use TypeBox for all schema validation. Do not use Zod.**
- Elysia routes: use `t` from `'elysia'` for body/query/params. Elysia's runtime validation is TypeBox-native.
- Env validation: use `Value.Parse()` from `@sinclair/typebox/value`.
- Mongo parse-on-read, internal contracts, anywhere a runtime schema is needed: TypeBox.
- Schema-first: define schema, derive type with `Static<typeof schema>` from `'@sinclair/typebox'`.
- Save derived types in a `types/` folder with a barrel export.

## Architecture & Dependency Injection

> Full API patterns, layer details, repository try-catch, and code examples are in [docs/ELYSIA.md](docs/elysia.md).

| Layer       | Responsibility                                                                     |
|-------------|------------------------------------------------------------------------------------|
| Router      | HTTP in/out only — routes, request parsing, response shape similar to controllers  |
| Service     | Business logic, orchestration of repositories and services                         |
| Repository  | All data access — DB queries, cache reads, DAL calls                               |

- All services, repositories, and API clients must be registered and resolved through DI
- No direct instantiation (`new`) inside services or controllers
- All configuration settings must be managed through DI
- Controllers and services must **never** access the data layer directly

## Angular

- Standalone components only (no NgModules)
- Separate HTML and stylesheet files (no inline templates or styles)
- Use Angular CLI for scaffolding
- No paid UI libraries — prefer plain CSS or Angular Material

## Styles

- SCSS only — no plain CSS
- CSS variables for theming
- Flexbox for layout

## Azure

> **Full reference → [docs/AZURE.md](docs/azure.md)** — best practice tool invocations, planning requirements, env var standards, Functions patterns, DI config, security checklist, deployment checklist.

## Code Formatting

- Blank line after class opening brace and before first property/method
- Double quotes for strings
- Trailing commas in multiline expressions
- Arrow functions for callbacks
- Named exports over default exports

## Linting

- ESLint on all TypeScript files after **every** set of changes
- Fix all lint errors before considering a task complete
- Do not suppress lint rules without explicit justification
- After agent model changes, run `eslint --fix`

## Testing

- Unit tests with `bun test` on all new code
- Tests must be isolated, deterministic, and well-documented
- Identify and fill coverage gaps

## API Generation & Verification

Applies to any code generation / modification against an HTTP API project (Elysia, Express, Fastify, Azure Functions HTTP, etc.).

### 🚨 Health endpoints — read this every time

- **Use `/health` for liveness and `/ready` for readiness. Never `/healthz`, never `/readyz`. No exceptions.**
- This applies everywhere a health endpoint is referenced: Elysia / Express / Fastify route handlers, Dockerfile `HEALTHCHECK CMD`, Kubernetes / ACA probes, GitHub Actions smoke checks, `proxy.conf.json`, terminal `curl` commands, README snippets, comments, and chat output.
- The Kubernetes-style `/healthz` / `/readyz` convention is in your training data because it dominates k8s manifests — that does not make it correct here. If you find yourself typing `healthz`, stop and use `health`. If you encounter an existing `/healthz` reference while editing nearby code, fix it as part of the same change.

### Verification

- **A passing `bun test` is not sufficient.** Unit tests that stub the container do not prove the app can boot.
- After any codegen pass on an API, the server **must actually start** and `/health` (liveness) plus `/openapi.json` (spec path) must return 200 before the task is considered complete. Add `/ready` (readiness — pings real deps) alongside.
- Prefer one of these patterns, in priority order:
  1. A socket-bound boot test inside `bun test` that calls `.listen(0)`, issues real `fetch` requests, and tears the server down. No env-var dependency.
  2. A `bun run smoke` script that does the same and exits 0/1.
  3. A chained `bun run verify` script (`type-check && lint && test && smoke`) that agents run as the single finish gate.
- **Missing env vars are a blocker, not a skip.** If the real entrypoint (`src/index.mts` or equivalent) cannot boot because required env is absent, report that as a blocker and point at the offending keys. Do not declare success.
- Do not fall back to `app.handle(new Request(...))` as the only boot evidence — that path never binds a socket and will pass even when `.listen()` would throw.

## Docs

- All markdown and documentation goes in `docs/`
- API docs must stay in sync with route changes
- Reference docs: [BUN.md](docs/bun.md) | [ELYSIA.md](docs/elysia.md) | [AZURE.md](docs/azure.md)

## Windows

- Do NOT use `mkdir -p` when making a directory on Windows
