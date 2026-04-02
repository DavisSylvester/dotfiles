Update API documentation (OpenAPI + Postman) and save a conversation log.

Run this skill after commits, pushes, or at the end of a conversation session.

## Arguments

- `$ARGUMENTS` — optional: service name to scope updates (e.g. `survey-definition-service`). If omitted, detect from changed files.

## Step 1: Identify affected services

If a service name was passed, use it. Otherwise detect from recent changes:
```bash
git diff --name-only HEAD~1 -- 'apps/apis/*/src/api/routes/*'
```
Extract unique service names from the paths. If no route files changed, skip OpenAPI/Postman steps.

## Step 2: Update OpenAPI spec (per service)

For each affected service:

### 2a: Try live export first
Check if the service is running locally:
```bash
curl -sf http://localhost:<port>/swagger/json -o apps/apis/<service>/openapi.json
```
Port mapping: survey-definition-service=3001, collection-service=3002, navigation-service=3009, security-service=3001, document-service=3005, audit-service=3008, masterdata-service=3006, notification-service=3007, reporting-service=3004.

### 2b: Fall back to static generation
If the service is not running, read the route files in `apps/apis/<service>/src/api/routes/` and generate an OpenAPI 3.0 spec from the Elysia route definitions (body schemas, query params, path params, response schemas). Save to `apps/apis/<service>/openapi.json`.

## Step 3: Update Postman collection (per service)

For each affected service:

1. Read the existing Postman collection at `apps/apis/<service>/tests/postman/ctv2026.postman_collection.json` (if it exists)
2. Generate a new collection from the OpenAPI spec (`apps/apis/<service>/openapi.json`)
3. Merge: preserve existing folder structure, test scripts, and pre-request scripts from the old collection. Add new endpoints, update changed endpoints, remove endpoints no longer in the spec.
4. Write the merged collection back to `apps/apis/<service>/tests/postman/ctv2026.postman_collection.json`
5. Follow the convention: one folder per feature, never put requests at the top level.

## Step 4: Save conversation log

Determine the user identifier and date:
```bash
git config user.email | cut -d@ -f1
date +%Y-%m-%d
```

Create a conversation log at `.ai/conversations/<user>-<date>.md` with the following sections:

```markdown
# Conversation Log — <user> — <date>

## Summary
<Brief 3-5 sentence summary of what was discussed and accomplished>

## Files Modified
<List of all files created, modified, or deleted during this session>

## Commits
<List of commit hashes and messages from this session>
```bash
git log --oneline --since="<session-start>" --until="now"
```

## Transcript
<Full conversation exchange — all user messages and assistant responses>
```

If a log for the same user and date already exists, append to it with a `---` separator and a new timestamp header.

## Step 5: Report

Summarize what was updated:
1. OpenAPI specs updated (which services, live vs static)
2. Postman collections updated (endpoints added/changed/removed)
3. Conversation log saved (path and size)

If any step failed, report the error and continue with remaining steps.
