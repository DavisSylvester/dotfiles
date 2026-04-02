# Test Generator

Use this skill whenever generating integration or unit tests for this project. Apply every rule below without exception.

---

## Rules

### Health Check
- Always use `/health` — never `/healthz`

### Test Structure
- Always use `describe` blocks and `test()` — never `it()`
- No standalone helper functions inside test files
- Helper functions go in a `tests/helpers/` directory alongside the test file
- One `expect` assertion per line

### Service Startup
- Never spawn the service inside tests
- In `beforeAll`, check if the service is reachable via `/health`
- If the service is not running, throw:
  ```
  {service-name} service on {port} is not running! Run `bun dev` from {service-folder} to start the service.
  ```

### Environment Guards
- Fail fast in `beforeAll` if required env vars are missing
- Throw a descriptive error naming the missing variable

### External CLI Assertions (e.g. `az`)
- Always capture both `stdout` and `stderr` with `Bun.spawn`
- Read stdout, stderr, and `proc.exited` concurrently with `Promise.all`
- Check `exitCode !== 0` and throw with the stderr message before parsing stdout
- Never call `JSON.parse` on potentially empty or error output without guarding

### TypeScript
- Explicitly type all lambda parameters — never rely on implicit inference (e.g. `(f: string) => ...`)
- `@types/bun` must be in `devDependencies` — verify before writing tests; add it if missing

### tsconfig
- Add `tests/**/*` to the `include` array in `tsconfig.json`
- Remove `rootDir` from `compilerOptions` if it is set to `./src` — it conflicts with including tests

### ESLint
- Always run `bunx eslint --fix` on every test file after writing
- Report any remaining errors that could not be auto-fixed

### Cleanup
- Ask the user before adding any cleanup steps (e.g. deleting temp blobs after a test run)

---

## File Layout

```
tests/
  helpers/
    blob-helpers.mts       # az CLI assertions
    service-guard.mts      # assertServiceRunning helper
  <feature>.test.mts
```

---

## Template — integration test

```typescript
import { readdirSync } from "node:fs";
import { join } from "node:path";

import { describe, test, expect, beforeAll } from "bun:test";

import { assertServiceRunning } from "./helpers/service-guard.mts";
import { blobExists } from "./helpers/blob-helpers.mts";

const PORT = process.env["PORT"] ?? "<default-port>";
const BASE_URL = `http://localhost:${PORT}`;
const CONNECTION_STRING = process.env["AZURE_STORAGE_CONNECTION_STRING"] ?? "";
const CONTAINER_NAME = process.env["AZURE_STORAGE_CONTAINER_NAME"] ?? "documents";

beforeAll(async () => {
  if (!CONNECTION_STRING) {
    throw new Error("AZURE_STORAGE_CONNECTION_STRING must be set to run integration tests");
  }
  await assertServiceRunning("<service-name>", PORT, "apps/apis/<service-folder>");
});

describe("<service> <feature>", () => {
  test("<description>", async () => {
    // arrange
    // act
    const res = await fetch(`${BASE_URL}/api/v1/...`, { method: "POST", body: form });

    // assert — one per line
    expect(res.status)
    .toBe(202);
    expect(body.success)
    .toBe(true);
  }, 60_000);
});
```

## Template — service-guard helper

```typescript
export async function assertServiceRunning(
  serviceName: string,
  port: string,
  serviceFolder: string
): Promise<void> {
  try {
    const res = await fetch(`http://localhost:${port}/health`);
    if (!res.ok) {
      throw new Error("unhealthy");
    }
  } catch {
    throw new Error(
      `${serviceName} service on ${port} is not running! Run \`bun dev\` from ${serviceFolder} to start the service.`
    );
  }
}
```

## Template — blob-helpers helper

```typescript
export async function blobExists(
  blobName: string,
  containerName: string,
  connectionString: string
): Promise<boolean> {
  const proc = Bun.spawn(
    [
      "az", "storage", "blob", "exists",
      "--container-name", containerName,
      "--name", blobName,
      "--connection-string", connectionString,
      "--output", "json",
    ],
    { stdout: "pipe", stderr: "pipe" }
  );

  const [stdoutText, stderrText, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);

  if (exitCode !== 0) {
    throw new Error(`az storage blob exists failed (exit ${exitCode}): ${stderrText.trim()}`);
  }

  const json = JSON.parse(stdoutText) as { exists: boolean };
  return json.exists;
}
```
