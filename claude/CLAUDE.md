# Global Development Standards

> Machine-wide defaults. Project-level `CLAUDE.md` overrides where needed.

## Custom Agents

- **`oda-agent`** — Autonomous code generation agent. Generates a PRD, breaks it into ordered tasks, then runs a Worker→Reviewer loop per task until all pass. Invoke for end-to-end feature implementation.

## Git

- Use git flow for all git commands
- Use conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`

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
- Use `readonly` on interface properties and function params where appropriate
- **One interface per file** — use `i-` prefix (e.g. `i-card.mts`); group in `interfaces/` folder by feature; barrel via `index.mts`
- Ensure `.mts` imports are switched to `.mjs` in import specifiers
- If imports use `.mts` extension, ensure `tsconfig.json` has `noEmit` set to `true`

### Error Handling

- Use `Result<T, E>` types or discriminated unions for recoverable errors
- Reserve `throw` for truly unexpected errors
- Prefer typed error classes over generic `Error`

### Validation with Zod

- Schema-first: define schema, derive type with `z.infer<typeof schema>`
- Validate all external inputs at system boundaries (API body, query, params)
- Save derived types in a `types/` folder with a barrel export

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
- Single quotes for strings
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

## Docs

- All markdown and documentation goes in `docs/`
- API docs must stay in sync with route changes
- Reference docs: [BUN.md](docs/bun.md) | [ELYSIA.md](docs/elysia.md) | [AZURE.md](docs/azure.md)

## Windows

- Do NOT use `mkdir -p` when making a directory on Windows
