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
- [ ] No `console.log` in production paths — use structured logger
