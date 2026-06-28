---
name: dns-change-report
description: Render a polished HTML report and a Teams Adaptive Card summarizing a DNS or domain operation — the inputs used to create it and the result. Use after a Hostinger DNS/domain operation (pairs with the hostinger-dns agent) to produce report.html + card.json for email/Teams/Slack notifications. Invoke when the user says "report this DNS change", "make a card for this", "summarize the domain operation", or wants a nice card/HTML of what was created and the outcome.
---

# DNS / Domain Change Report

Turn the details of a DNS or domain operation (what was requested + the result)
into **channel-ready artifacts for Teams, Slack, and email** — one render, all four:

| File | Channel | What it is |
|---|---|---|
| `card.json` | **Teams** | Adaptive Card in the Power Automate "workflows" message envelope |
| `slack.json` | **Slack** | Block Kit payload (`text` + colored `attachments[].blocks`) |
| `report.html` | **Email** | Clean inline-styled HTML (tables, status band) |
| `report.txt` | **Email / generic** | Plain-text fallback |

A Teams Adaptive Card does **not** render in Slack and vice-versa, so each channel
gets its native format. Pairs with the `hostinger-dns` agent, which POSTs the right
file to each channel's webhook / email.

## How to run

1. Assemble a **details JSON** (schema below) describing the operation and result.
2. Render with **`bun` or `node`** (either works; the script is plain ESM `.mjs`
   using only `node:fs`/`node:path`, so it runs on Windows, macOS, and Linux).
   Writes to `./dns-report/` by default; pass an `outDir` to change it.

   **macOS / Linux / Git Bash:**
   ```bash
   bun  "$HOME/.claude/skills/dns-change-report/render.mjs" details.json [outDir]
   node "$HOME/.claude/skills/dns-change-report/render.mjs" details.json [outDir]
   echo "$JSON" | node "$HOME/.claude/skills/dns-change-report/render.mjs" - [outDir]   # stdin
   ```

   **Windows PowerShell:**
   ```powershell
   node "$HOME\.claude\skills\dns-change-report\render.mjs" details.json [outDir]
   $JSON | node "$HOME\.claude\skills\dns-change-report\render.mjs" - [outDir]          # stdin
   ```
   (PowerShell defines `$HOME`; in cmd.exe use `%USERPROFILE%`.) Prefer passing a
   **file path** over stdin for the most consistent behavior across shells. The
   script prints the two output paths on success.
3. Dispatch to any channel whose webhook/recipient is configured (each is
   independent and best-effort — skip silently if its env var is unset):
   ```bash
   # Teams — note the charset=utf-8 (cards contain —, ·, …, emoji; Power Automate
   # rejects them with HTTP 400 "Unable to translate bytes [E2]" without it)
   [ -n "$POWER_AUTOMATE_WEBHOOK_URL" ] && curl -fsS -X POST "$POWER_AUTOMATE_WEBHOOK_URL" \
     -H "Content-Type: application/json; charset=utf-8" --data-binary @dns-report/card.json || true
   # Slack
   [ -n "$SLACK_WEBHOOK_URL" ] && curl -fsS -X POST "$SLACK_WEBHOOK_URL" \
     -H "Content-Type: application/json; charset=utf-8" --data-binary @dns-report/slack.json || true
   # Email (SMTP via curl; HTML body, text fallback exists as report.txt)
   if [ -n "$NOTIFY_EMAIL_TO" ] && [ -n "$SMTP_URL" ]; then
     { printf 'From: %s\nTo: %s\nSubject: %s\nMIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8\n\n' \
         "${NOTIFY_EMAIL_FROM:-noreply@localhost}" "$NOTIFY_EMAIL_TO" "DNS change report"; cat dns-report/report.html; } \
     | curl -fsS --ssl-reqd --url "$SMTP_URL" \
         --mail-from "${NOTIFY_EMAIL_FROM:-noreply@localhost}" --mail-rcpt "$NOTIFY_EMAIL_TO" --upload-file - || true
   fi
   ```
   (Teams = `card.json`, Slack = `slack.json`, email = `report.html`/`report.txt`.)

   **PowerShell `Invoke-RestMethod`** mangles the UTF‑8 body (HTTP 400 byte `[E2]`).
   Send raw bytes with an explicit charset instead:
   ```powershell
   $bytes = [IO.File]::ReadAllBytes("$env:TEMP\dns-report\card.json")
   Invoke-RestMethod -Method POST -Uri $env:POWER_AUTOMATE_WEBHOOK_URL `
     -ContentType 'application/json; charset=utf-8' -Body $bytes
   ```
   Power Automate webhook URLs must be **complete** — include `&sv=…&sig=…`; a URL
   missing the `sig` returns HTTP 401 `DirectApiAuthorizationRequired`.

## Details JSON schema

```jsonc
{
  "title": "Bind custom domain — onboard.davaco.cloud",   // headline
  "operation": "Azure Container App custom domain",        // optional subtitle/op name
  "domain": "davaco.cloud",                                // the zone operated on
  "status": "success",                                     // success | failure | partial
  "timestamp": "2026-06-27T18:30:00Z",                     // optional ISO time
  "actor": "davis",                                        // optional who ran it
  "inputs": [                                              // the values used to create
    { "label": "Container App", "value": "prediction-ui" },
    { "label": "Resource group", "value": "dv-rg-container-apps" },
    { "label": "Verification id", "value": "43F7…E8A8" }
  ],
  "records": [                                             // DNS records added/changed
    { "name": "asuid.onboard", "type": "TXT",   "value": "43F7…E8A8", "ttl": 300, "action": "created" },
    { "name": "onboard",       "type": "CNAME", "value": "prediction-ui.salmonrock-….azurecontainerapps.io.", "ttl": 300, "action": "created" }
  ],
  "result": {
    "summary": "Domain bound; Azure-managed TLS issued.",
    "details": [ { "label": "HTTPS", "value": "200" }, { "label": "Cert", "value": "Managed (SNI)" } ],
    "links":   [ { "title": "Open site", "url": "https://onboard.davaco.cloud" } ]
  },
  "error": ""                                              // set on failure/partial
}
```

Only `status` (and ideally `title`) is required; every other field is optional and
omitted from the output when empty. For a **domain registration** report, put the
SKU/price/contacts in `inputs` and the registered domain + lock/privacy state in
`result.details` — no `records` needed.

## Guidance

- Never put the API token, full secrets, or payment details in the report — mask
  long values (e.g. show first/last 4 chars of a verification id).
- Pick `status` honestly: `partial` when some steps succeeded and others didn't
  (e.g. DNS created but cert still provisioning).
- The card's container colour follows status (good / attention / warning); the HTML
  header band matches.
