# Azure Reference

> Standards and patterns for all Azure development and deployments.
> See also: [Azure developer docs](https://learn.microsoft.com/en-us/azure/) | [Azure Functions docs](https://learn.microsoft.com/en-us/azure/azure-functions/)

---

## Always Invoke Best Practice Tools First

Before generating any Azure-related code or creating deployment plans, **always invoke the appropriate Azure best practice tool**. Do not skip this step.

| Scenario                          | Tool call                                                               |
|-----------------------------------|-------------------------------------------------------------------------|
| General Azure code generation     | `azure_development-get_best_practices(resource=general, action=code-generation)` |
| General Azure deployment          | `azure_development-get_best_practices(resource=general, action=deployment)` |
| Azure Functions code generation   | `azure_development-get_best_practices(resource=azurefunctions, action=code-generation)` |
| Azure Functions deployment        | `azure_development-get_best_practices(resource=azurefunctions, action=deployment)` |
| Azure Static Web Apps             | Invoke the most relevant Azure best practice tool before starting       |
| Azure Functions (any question)    | `azure_development-summarize_topic` first, to check for a matching custom mode |

**Only invoke Azure tools when the user is discussing Azure. Do not call them otherwise.**

---

## Planning Requirement

For **Azure Functions** and **Azure Static Web Apps**:

1. Always create a written plan and explain it to the user
2. Get explicit user consent before editing any files
3. Only then proceed with implementation

---

## Environment Variables

- All Azure-related environment variables must be `UPPER_SNAKE_CASE`
- Never hardcode connection strings, keys, or secrets in source code
- Use Azure Key Vault for secrets in production
- Use Managed Identity over connection strings where possible

```ts
// src/env.mts — validate at startup
import { z } from 'zod'

const schema = z.object({
  AZURE_STORAGE_CONNECTION_STRING: z.string(),
  AZURE_KEYVAULT_URI: z.string().url().optional(),
  APPLICATIONINSIGHTS_CONNECTION_STRING: z.string().optional(),
})

export const env = schema.parse(Bun.env)
```

---

## Azure Functions (Bun)

### Project Structure

```
apps/
  my-function-app/
    src/
      functions/
        <trigger-name>/
          index.mts        # function handler
          schema.mts       # input validation
    host.json
    package.json
    tsconfig.json
```

### Function Handler Pattern

```ts
// src/functions/http-trigger/index.mts
import { app } from '@azure/functions'
import { z } from 'zod'

const inputSchema = z.object({
  name: z.string().min(1),
})

app.http('httpTrigger', {
  methods: ['GET', 'POST'],
  authLevel: 'function',
  handler: async (request, context) => {
    context.log('Processing request')

    const body = inputSchema.safeParse(await request.json())
    if (!body.success) {
      return {
        status: 422,
        jsonBody: { code: 'VALIDATION_ERROR', message: body.error.message },
      }
    }

    return {
      status: 200,
      jsonBody: { message: `Hello, ${body.data.name}` },
    }
  },
})
```

---

## Configuration via DI

All configuration settings must be managed through the DI container — never direct `process.env` or `Bun.env` access in app code.

```ts
// packages/config/index.mts
import { z } from 'zod'

export const appConfigSchema = z.object({
  azure: z.object({
    storageConnectionString: z.string(),
    keyVaultUri: z.string().url().optional(),
  }),
  app: z.object({
    port: z.coerce.number().default(3000),
    nodeEnv: z.enum(['development', 'production', 'test']),
  }),
})

export type AppConfig = z.infer<typeof appConfigSchema>

export const loadConfig = (): AppConfig =>
  appConfigSchema.parse({
    azure: {
      storageConnectionString: Bun.env.AZURE_STORAGE_CONNECTION_STRING,
      keyVaultUri: Bun.env.AZURE_KEYVAULT_URI,
    },
    app: {
      port: Bun.env.PORT,
      nodeEnv: Bun.env.NODE_ENV,
    },
  })
```

---

## Security Checklist

- Use **Managed Identity** instead of connection strings wherever supported
- Store all secrets in **Azure Key Vault** — not in app config or env files
- Apply **RBAC** (Role-Based Access Control) — no broad permissions
- Enable **HTTPS only** — no plain HTTP endpoints
- Restrict CORS origins per environment
- Enable **Application Insights** for observability in production
- Never log secrets, tokens, or PII

---

## Deployment Checklist

Before any Azure deployment, invoke the deployment best practice tool (see table above), then verify:

- [ ] All secrets are in Key Vault, not in code or env files
- [ ] Managed Identity is configured
- [ ] CORS origins are restricted to production domain
- [ ] Application Insights connection string is set
- [ ] Health check endpoints (`/healthz`, `/readyz`) are reachable
- [ ] Environment variables are validated at startup

---

## SPA Auth with Microsoft Entra (MSAL)

Two distinct failure modes both surface as "can't sign in / blank page" but have different signatures and fixes. A bare or misconfigured app registration causes silent failures even when the client config is perfect.

### Problem 1 — Unsubstituted config placeholders baked into the build

- **Symptom:** redirect to `login.microsoftonline.com/<tenant-placeholder>/...&client_id=<placeholder>`; Entra returns `AADSTS90013: Invalid input received from the user`.
- **Cause:** SPA auth config (authority/tenant, clientId) lives in a **build-time** file with template placeholders that were never replaced before the image was built. There is no runtime substitution, so the literal `<...>` strings ship in the JS bundle.
- **Fix:** inject real values before build, or — better — load config at **runtime** (e.g. a `config.json` fetched in an app initializer) so one image works across environments.
- **Note:** tenant id and SPA client id are **not secrets** (visible in any browser); only the API audience/issuer are validated server-side.

### Problem 2 — Redirect response never processed → `interaction_in_progress`

- **Symptom:** sign-in at Entra succeeds, you land back on the app to a blank page; console shows `BrowserAuthError: interaction_in_progress` thrown from `loginRedirect`.
- **Cause:** in the redirect flow MSAL sets an `interaction.status` flag when `loginRedirect()` starts and only clears it when `handleRedirectPromise()` runs on the return trip. A **custom auth guard that calls `loginRedirect()` but never calls `handleRedirectPromise()`** (i.e. not using the framework's built-in guard / redirect component) leaves the auth code unexchanged, no account cached, and the flag stuck — so the guard re-fires login and throws.
- **Fix:** process the redirect response on **every page load, before routing/guards run**, e.g. in an app initializer:
  ```
  await instance.initialize();                 // msal-browser v3+ requires this first
  const res = await instance.handleRedirectPromise();
  const account = res?.account ?? instance.getAllAccounts()[0] ?? null;
  if (account) instance.setActiveAccount(account);   // so the HTTP interceptor can get tokens
  ```
- **Gotcha:** stale `interaction.status` from a prior failed attempt persists in local/session storage — always verify a fix in a **fresh incognito window** (or clear site data), or you'll re-trigger the old error and think the fix failed.

### The app registration must actually be provisioned

For a SPA + API, the registration needs all of:

- **SPA platform redirect URI** = the app's exact origin + path (e.g. `https://app.example.com/`).
- **Application ID URI** (e.g. `api://<name>`) **and an exposed delegated scope** (e.g. `access_as_user`) — the scope the SPA requests must resolve to a real exposed scope.
- **`requestedAccessTokenVersion: 2`** for MSAL.js (v2) tokens.
- **Pre-authorize** the SPA client for the scope to skip the consent screen.
- The **API validates the token `aud`** (= the App ID URI / scope resource) **and `issuer`** (tenant); keep both in sync with what the SPA requests.

### Key-components checklist (don't repeat the mistake)

- [ ] No `<placeholder>` strings in the shipped bundle (grep the built JS to confirm).
- [ ] Auth config injected at runtime, or real values committed **before** the image build.
- [ ] `handleRedirectPromise()` (or the framework's built-in guard / redirect component) runs on every load.
- [ ] `initialize()` awaited before any MSAL call (v3+).
- [ ] Active account set after the redirect so token acquisition works.
- [ ] App registration: SPA redirect URI + App ID URI + exposed scope + token v2 + pre-auth.
- [ ] API `aud`/`issuer` match the SPA's requested scope/tenant; secret-sourced config can be overridden by an explicit env var — know which one wins.
- [ ] API CORS allows the SPA origin.
- [ ] Verified in a clean (incognito) browser session to rule out stale MSAL state.
- [ ] No `console.log` in production paths — use structured logger