# Hostinger Ecommerce API

> Base path: `/api/ecommerce/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/ecommerce) · doc portal: https://developers.hostinger.com

## Overview

The Ecommerce API manages online stores associated with your Hostinger account. You can list existing stores and create new ones. Creating a store also provisions a **primary sales channel** for it.

Core concepts:

- **Stores** — the top-level ecommerce entity tied to your account. Each store carries company details (name, email, country) and a default language used for the storefront.
- **Sales channels** — the surface through which products are sold. Every store has at least one sales channel; a primary sales channel is created alongside the store. You can supply a `sales_channel` object (e.g., `type: custom` with an `external_id`) to link the store to an external system.

## Endpoints

### Stores

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/ecommerce/v1/stores` | Get stores (paginated via `page`) |
| `POST` | `/api/ecommerce/v1/stores` | Create a store (also creates a primary sales channel) |

### Create Store body

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Store name |
| `country_code` | string | ISO country code (e.g., `us`) |
| `company_email` | string | Company contact email |
| `company_name` | string | Company name |
| `language` | string | Default storefront language (e.g., `en`) |
| `sales_channel` | object | Optional. `{ "type": "custom", "external_id": "..." }` |

## Common patterns

### List stores

```bash
curl -X GET "https://developers.hostinger.com/api/ecommerce/v1/stores" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Paginate
curl -X GET "https://developers.hostinger.com/api/ecommerce/v1/stores?page=2" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Create a store

```bash
curl -X POST "https://developers.hostinger.com/api/ecommerce/v1/stores" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Store",
    "country_code": "us",
    "company_email": "owner@example.com",
    "company_name": "My Company",
    "language": "en",
    "sales_channel": {
      "type": "custom",
      "external_id": "ext-12345"
    }
  }'
```

> A primary sales channel is created automatically with the store. The `sales_channel` object is optional — omit it to use the default.

## Best practices

### Store setup
- Set `country_code` and `language` to match your target market — they drive storefront defaults.
- Use a monitored `company_email` — it receives store-related notifications.
- Provide a `sales_channel.external_id` when integrating with an external system so you can reconcile records later.

### Listing
- Paginate with `page` when an account has many stores rather than assuming a single page.

## Troubleshooting

### 401 Unauthorized
- Verify your API token is valid and not expired.
- Check the `Authorization: Bearer <token>` header format.

### 422 Unprocessable Content
- Invalid `country_code` (use a valid ISO code like `us`) or malformed `company_email`.
- Missing or malformed `sales_channel` object when one is provided.

### Store not appearing after creation
- Re-list stores — propagation may take a moment.
- Confirm the create request returned a success status and a store ID.

## References
- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI tool: https://github.com/hostinger/api-cli
- Changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
