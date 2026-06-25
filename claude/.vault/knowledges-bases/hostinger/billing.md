# Hostinger Billing API

> Base path: `/api/billing/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/billing) · doc portal: https://developers.hostinger.com

## Overview

The Billing API lets you browse the Hostinger service catalog, manage payment methods, and control subscriptions programmatically. Catalog prices are returned in **cents** (integer) — e.g., `1799` = `$17.99`. Orders are placed through resource-specific endpoints (e.g., domains and VPS) by referencing catalog `item_id` values and a payment method; there is no generic billing order endpoint. Orders created via the API default to automatic renewal.

## Endpoints

### Catalog

| Method | Endpoint | Summary |
|--------|----------|---------|
| `GET` | `/api/billing/v1/catalog` | Get catalog items (filterable by `category` and `name`) |

### Orders

There is **no** generic billing order endpoint. The previous `POST /api/billing/v1/orders` has been **removed**. Place orders through resource-specific endpoints instead:

- `POST /api/domains/v1/portfolio` — domain purchases
- `POST /api/vps/v1/virtual-machines` — VPS purchases

### Payment methods

| Method | Endpoint | Summary |
|--------|----------|---------|
| `GET` | `/api/billing/v1/payment-methods` | List payment methods |
| `POST` | `/api/billing/v1/payment-methods/{id}` | Set default payment method |
| `DELETE` | `/api/billing/v1/payment-methods/{id}` | Delete payment method |

> New payment methods must be added via hPanel (https://hpanel.hostinger.com/billing/payment-methods), not the API.

### Subscriptions

| Method | Endpoint | Summary |
|--------|----------|---------|
| `GET` | `/api/billing/v1/subscriptions` | List all subscriptions |
| `DELETE` | `/api/billing/v1/subscriptions/{id}/auto-renewal/disable` | Disable auto-renewal |
| `PATCH` | `/api/billing/v1/subscriptions/{id}/auto-renewal/enable` | Enable auto-renewal |

## Common patterns

### Browse the catalog

```bash
# Get available catalog items
curl -X GET "https://developers.hostinger.com/api/billing/v1/catalog" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json"

# Filter catalog by category
curl -X GET "https://developers.hostinger.com/api/billing/v1/catalog?category=vps" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

Python SDK:

```python
from hostinger_api import Hostinger

client = Hostinger(api_token="YOUR_API_TOKEN")

# List catalog items (prices are in cents)
catalog = client.billing.catalog.get_catalog_item_list()
for item in catalog:
    print(f"{item.name}: {item.price / 100:.2f} USD")
```

### Manage payment methods

```bash
# List payment methods
curl -X GET "https://developers.hostinger.com/api/billing/v1/payment-methods" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Set default payment method
curl -X POST "https://developers.hostinger.com/api/billing/v1/payment-methods/517244" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Delete a payment method
curl -X DELETE "https://developers.hostinger.com/api/billing/v1/payment-methods/517244" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Manage subscriptions

```bash
# List all subscriptions
curl -X GET "https://developers.hostinger.com/api/billing/v1/subscriptions" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Disable auto-renewal for a subscription
curl -X DELETE "https://developers.hostinger.com/api/billing/v1/subscriptions/12345/auto-renewal/disable" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Enable auto-renewal for a subscription
curl -X PATCH "https://developers.hostinger.com/api/billing/v1/subscriptions/12345/auto-renewal/enable" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## Best practices

- **Pricing**: Always fetch catalog prices before displaying to users — prices are in **cents**. Divide by 100 and format appropriately for display.
- **Orders**: The generic `/api/billing/v1/orders` endpoint has been removed. Use `POST /api/domains/v1/portfolio` for domain purchases and `POST /api/vps/v1/virtual-machines` for VPS purchases. Prefer non-credit-card payment methods to avoid verification delays.
- **Payment methods**: New payment methods must be added through hPanel, not the API. If no payment method is specified in an order, the default method is used automatically. Remove unused payment methods to keep your account clean.
- **Subscriptions**: Monitor subscriptions to avoid unexpected service interruptions. Disable auto-renewal well before expiration if you intend to cancel.

## Troubleshooting

- **401 Unauthorized**: Verify the API token is valid and not expired; confirm token permissions match the owning user's permissions; check the `Authorization: Bearer <token>` header format.
- **422 Unprocessable Content**: Invalid `item_id` in order request — verify against the catalog. Invalid `payment_method_id` — list payment methods first.
- **429 Too Many Requests**: You've exceeded rate limits — back off and retry. Repeated violations may temporarily block your IP.
- **Order not processing**: `credit_card` payments may require additional verification. Check order status in hPanel (https://hpanel.hostinger.com/). Try a different payment method.

## References
- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- API changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI tool: https://github.com/hostinger/api-cli
