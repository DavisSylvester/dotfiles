# Deploy-time env vars silently baked empty → runtime 401 / misbehavior

A backend deployed by infrastructure-as-code rejects authenticated requests (commonly
**HTTP 401**) or otherwise misbehaves at runtime — even though the deploy reported success
and the data clearly exists. Restarting or redeploying doesn't help; if anything, every
deploy re-introduces the problem.

## Root cause

The IaC reads a required value from the **deploy-time process environment** with a silent
empty fallback, e.g.:

```ts
environment: {
  OIDC_ISSUER:   process.env.OIDC_ISSUER   ?? "",
  OIDC_AUDIENCE: process.env.OIDC_AUDIENCE ?? "",
}
```

The process that runs the deploy (a CI pipeline step, or a local shell) does **not** export
that variable. So the resource is provisioned with an empty string. Nothing fails at
synth/plan/deploy time — the empty value only bites at runtime (auth can't validate a token,
a client can't connect, a feature silently no-ops). Because every automated deploy re-bakes
the empty value, it also silently overwrites any manual hotfix applied to the running
resource.

This has two common variants of the same bug:
- **CI:** the pipeline's deploy step lists only some of the needed variables in its `env:` /
  secrets; the rest resolve to empty.
- **Local:** a wrapper that injects env into the *app* (e.g. an `--env-file` flag, a
  language runtime loader) does **not** inject it into the separate *deploy* subprocess.

## How to diagnose

1. Confirm the request actually **reaches the backend and is rejected there** (e.g. a 401
   with a response body), rather than being blocked earlier by CORS / DNS / TLS — check the
   network status code, not just "it didn't work."
2. Rule out "no data" vs "can't read data": inspect the datastore directly. If records
   exist, the problem is access/config, not missing data.
3. Inspect the **deployed resource's actual configuration** — do not trust that the IaC set
   it. Read the live env/config off the running resource (cloud CLI `get-configuration` /
   `describe` / container `inspect`). Look for the suspect keys being empty strings.
4. Diff the deploy runner's exported environment against **every** variable the IaC reads
   from the environment. The gap is the bug.

## How to fix

1. Provide every such variable in **all** paths that run the deploy — the CI deploy step's
   `env:`/secrets **and** any local deploy command. Non-secret values can be plain CI
   variables; secrets go in the masked secret store.
2. Re-deploy, then verify against the **live resource's config** (diagnosis step 3) — not
   just a green pipeline.
3. **Prevent recurrence:** stop defaulting required config to `""`. Either fail fast at
   startup (throw / refuse to boot when a required var is blank) or assert during IaC
   synth/plan, so a missing variable is a loud error instead of a silent runtime fault.

## One-line rule

Any config the IaC pulls from the deploy-time environment with a silent default must be
supplied by **every** path that runs the deploy; a missing one becomes a silent empty value,
not a deploy error.
