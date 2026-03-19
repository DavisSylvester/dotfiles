# Global Development Standards

> Machine-wide configuration for all projects. Project-level `CLAUDE.md` overrides these settings where needed.

---

## Table of Contents

- [Global Development Standards](#global-development-standards)
  - [Table of Contents](#table-of-contents)
  - [Bun](#bun)
  - [TypeScript](#typescript)
    - [tsconfig.json Baseline](#tsconfigjson-baseline)
    - [Rules](#rules)
    - [Error Handling](#error-handling)
    - [Validation with Zod](#validation-with-zod)
  - [Elysia API Patterns](#elysia-api-patterns)
  - [Architecture \& Dependency Injection](#architecture--dependency-injection)
    - [DI Rules](#di-rules)
    - [Layer Responsibilities](#layer-responsibilities)
    - [Repository Rules](#repository-rules)
    - [Repository & Try-Catch](#repository--try-catch)
  - [Azure](#azure)
  - [Code Formatting](#code-formatting)
  - [Linting](#linting)
  - [Docs](#docs)

---

## Bun

> **Full reference → [`docs/bun.md`](docs/BUN.md)**

This machine uses **Bun** as the runtime, package manager, and test runner. All projects are assumed to use Bun unless a project-level `CLAUDE.md` says otherwise.

**Key rules (see BUN.md for full detail):**

- Use `bun add` / `bun remove` / `bun run` — never `npm`, `yarn`, or `pnpm`
- All source files use `.mts` extension; import specifiers must be explicit (`./file.mts`)
- Use `bun --watch` for dev mode — never `nodemon` or `ts-node`
- Prefer Bun-native APIs (`Bun.file`, `Bun.write`, `Bun.serve`) over Node.js equivalents
- Use `bun test` with `bun:test` imports — no jest or vitest packages
- Use `bun-types` — do **not** install `@types/node`
- Never access env vars directly — always go through the typed `src/env.mts` module

---

## TypeScript

All TypeScript must be written in **strict mode**. No exceptions.

### tsconfig.json Baseline

```json
{
  "compilerOptions": {
    "strict": true,
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "types": ["bun-types"],
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

### Rules

- **Never use `any`** — use explicit types, interfaces, or `unknown` when truly unknown
- Prefer `interface` for object shapes; `type` for unions and aliases
- Use `satisfies` operator over type assertions; avoid `as` unless absolutely necessary
- Use `as const` objects or `const enum` — not regular enums
- All functions must have explicit return types and access modifiers
- Use `readonly` on interface properties and function params where appropriate
- All async

### Error Handling

```ts
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E }
```

- Use Result types or discriminated unions for recoverable errors
- Reserve `throw` for truly unexpected errors
- Prefer typed error classes over generic `Error`

### Validation with Zod

- Schema-first: define schema, derive type with `z.infer<typeof schema>`
- Validate all env vars at startup via `src/env.mts`
- Validate all external inputs at system boundaries (API body, query, params)
- After creating a schema create an associated type using `z.infer<typeof schema>` and save in a folder called `types`
- Add all types to a barrel

---

## Elysia API Patterns

> **Full reference → [`docs/ELYSIA.md`](docs/ELYSIA.md)**

**Key rules (see ELYSIA.md for full detail):**

- Group endpoints by domain: `src/api/<domain>/router.mts`
- Every route must have `zod` or `typebox` schemas for `body`, `query`, and `params`
- Controllers handle HTTP only — business logic belongs in services
- Resolve all services via DI — no `new` inside controllers or services
- All DB access goes through repositories — services never touch the DB directly
- Define shared DTOs in `packages/interfaces` — no duplication across apps
- Mount `@elysiajs/swagger`; every endpoint must have API documentation
- All routes versioned under `/api/v1`; bump major version on breaking changes
- Standardize pagination: `{ items, total, pageInfo }` response shape
- Use centralized error middleware — no inline `try/catch` in controllers
- Auth as middleware/guards only — never inline in controllers
- Expose `/healthz` and `/readyz` on every service
- No `console.log` — use shared structured logger with correlation IDs

---

## Architecture & Dependency Injection

### DI Rules

- All services, repositories, and API clients must be registered and resolved through the DI container
- No direct instantiation (`new`) of services inside other services or controllers
- All configuration settings must be managed through DI

### Layer Responsibilities

| Layer       | Responsibility                                              |
|-------------|-------------------------------------------------------------|
| Controller  | HTTP in/out only — routes, request parsing, response shape  |
| Service     | Business logic, orchestration of repositories and services  |
| Repository  | All data access — DB queries, cache reads, DAL calls        |

### Repository Rules

- All DB/data layer access must go through repositories
- Repositories are injected into services — never called from controllers
- **Controllers and services must never access the data layer directly**

### Repository & Try-Catch

Repositories are an external system boundary — the DB can fail for reasons outside your control (timeouts, constraint violations, connection drops). All repository methods that call the database **must** be wrapped in `try/catch` and return a `Result<T, E>` type.

```ts
async findById(id: string): Promise<Result<Survey, DbError>> {
  try {
    const row = await this.db.query(...);
    return { ok: true, value: row };
  } catch (e) {
    // Translate low-level DB error into a typed domain error
    return { ok: false, error: toDbError(e) };
  }
}
```

**Rules:**

- Every repository method must return `Result<T, DbError>` — never throw raw DB/ORM errors
- The `catch` block must translate the error into a typed domain error — do not re-throw the raw error
- Do not swallow errors silently (e.g. `catch { return null }`)
- Services receive the `Result` and decide how to respond — retry, fallback, surface as 503, etc.
- Raw ORM/driver errors must never leak past the repository layer

**What to avoid:**

```ts
// Bad — swallows the error, breaks callers
try { ... } catch { return null; }

// Bad — re-throws raw with no translation or benefit
try { ... } catch (e) { throw e; }

// Bad — throws a domain error instead of returning Result
try { ... } catch (e) { throw new NotFoundException(); }
```

---

## Azure

> **Full reference → [`docs/AZURE.md`](docs/AZURE.md)**

**Key rules (see AZURE.md for full detail):**

- Always invoke the appropriate Azure best practice tool **before** generating code or deployment plans
- For Azure Functions and Static Web Apps: always write a plan, get user consent, then implement
- All Azure env variables must be `UPPER_SNAKE_CASE`
- Use Managed Identity over connection strings in production
- Store secrets in Azure Key Vault — never in source or env files
- All config goes through DI — never direct `Bun.env` access in app code

---

## Code Formatting

- All class declarations must have a blank line after the opening brace and before the first property or method
- Consistent spacing throughout for readability
- Single quotes for strings
- Trailing commas in multiline expressions
- Arrow functions preferred for callbacks
- Named exports preferred over default exports
- All environment variables must be `UPPER_SNAKE_CASE`

---

## Linting

- Use **ESLint** for linting all TypeScript files
- Run ESLint after **every** set of changes — not just at the end
- Fix all lint errors before considering a task complete
- Do not suppress lint rules without explicit justification

---

## Docs

- All documentation and markdown files must be placed in the `docs/` directory
- API docs must be kept in sync with route changes — update on every addition or modification
- Reference docs for this machine's standards:
  - [`docs/BUN.md`](docs/BUN.md) — Bun runtime, APIs, testing, toolchain
  - [`docs/ELYSIA.md`](docs/ELYSIA.md) — Elysia routing, controllers, services, repositories
  - [`docs/AZURE.md`](docs/AZURE.md) — Azure development, Functions, deployment standards
