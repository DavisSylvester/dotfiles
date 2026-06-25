# Hostinger Horizons API

> Base path: `/api/horizons/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/horizons) · doc portal: https://developers.hostinger.com

## Overview

Horizons is Hostinger's AI website builder. The API creates a website from a
natural-language description and returns a link where the user can preview and
edit it. Use it when a user asks to build a website, landing page, blog, or
other web application, or to fetch an edit link for an existing Horizons site.

Key concepts:

- **Prompt-driven creation** — You describe the desired site in natural
  language (the `message`) and Horizons generates it. The create call returns a
  **website URL and ID immediately**, but generation happens **asynchronously** —
  the site is built in the background after the call returns.
- **Messages** — The create request takes a `message` array of message objects.
  Each has a `type` (currently `text`) and the `text` describing what to build,
  e.g. *"Create a landing page for a coffee shop with a hero section, menu, and
  contact form."*
- **Editing in the Horizons interface** — Horizons websites can only be modified
  inside the Horizons web interface. To change an existing site, fetch its edit
  link with `GET /websites/{websiteId}` and open the returned URL — there is no
  direct content-editing API.

## Endpoints

### Websites

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/api/horizons/v1/websites` | Create a website from a prompt (async generation) |
| `GET` | `/api/horizons/v1/websites/{websiteId}` | Get a Horizons editor link for the website |

### Create Website body

| Field | Type | Description |
|-------|------|-------------|
| `message` | array | Required. Array of message objects describing the site |
| `message[].type` | string | Message type (currently `text`) |
| `message[].text` | string | The natural-language description of what to build |

## Common patterns

### Create a website from a prompt

```bash
curl -X POST "https://developers.hostinger.com/api/horizons/v1/websites" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": [
      {
        "type": "text",
        "text": "Create a landing page for a coffee shop with a hero section, menu, and contact form"
      }
    ]
  }'
```

> Returns a website URL and ID right away; the site continues generating
> asynchronously. Share the URL with the user to watch progress and preview the
> result.

### Get an edit link for an existing website

```bash
curl -X GET "https://developers.hostinger.com/api/horizons/v1/websites/12345" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

> Returns a link to edit the website in the Horizons interface. Use this
> whenever the user wants to modify, edit, or add features to an existing
> Horizons site.

## Best practices

### Prompts

- Be specific about sections, purpose, and tone in the `message` text — more
  detail yields a closer first result.
- One clear description per create call; refine afterwards in the Horizons
  interface rather than re-creating.

### Async handling

- Treat create as fire-and-forget: surface the returned URL to the user so they
  can watch generation finish.
- Don't expect a fully built site in the create response — only the URL and ID
  are immediate.

### Editing

- Always fetch a fresh edit link via `GET /websites/{websiteId}` rather than
  caching old URLs.

## Troubleshooting

### 401 Unauthorized

- Verify your API token is valid and not expired.
- Check the `Authorization: Bearer <token>` header format.

### 422 Unprocessable Content

- The `message` array is missing or empty.
- A message object is missing `type` or `text`.

### Website not ready

- Generation is asynchronous — give it time and revisit the returned URL.
- The edit link from `GET /websites/{websiteId}` opens the site in the Horizons
  interface even while it finishes building.

## References

- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI Tool: https://github.com/hostinger/api-cli
- API Changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
