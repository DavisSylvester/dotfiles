# Hostinger Reach API

> Base path: `/api/reach/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/reach) · doc portal: https://developers.hostinger.com

## Overview

The Reach API provides email marketing capabilities — managing contacts, creating segments for targeted campaigns, and working with sender profiles. Host: `https://developers.hostinger.com`.

Core concepts:

- **Contacts** — Email recipients. Each contact has basic information (name, email, surname) and a subscription status. If double opt-in is enabled, new contacts start with a pending status and receive a confirmation email.
- **Segments** — Group contacts based on criteria (email, name, subscription status, engagement metrics, etc.). Support complex filtering with operators like `equals`, `contains`, `gte`, `lte`, `opened`, `clicked`, etc.
- **Profiles** — Sender profiles representing the email identity used to send campaigns. Each profile has basic information and is associated with your account.
- **Contact Groups** — A way to organize contacts (deprecated in favor of segments).
- **Subscription Status** — Determines whether contacts receive emails; can be used as a filter when listing contacts.

## Endpoints

### Contacts

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/reach/v1/contacts` | List contacts (paginated, filterable) |
| `POST` | `/api/reach/v1/contacts` | Create a contact (direct) |
| `POST` | `/api/reach/v1/profiles/{profileUuid}/contacts` | Create a contact scoped to a sender profile |
| `GET` | `/api/reach/v1/contacts/groups` | List contact groups |
| `DELETE` | `/api/reach/v1/contacts/{uuid}` | Delete a contact |

### Segments

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/reach/v1/segmentation/segments` | List all segments |
| `POST` | `/api/reach/v1/segmentation/segments` | Create a new segment |
| `GET` | `/api/reach/v1/segmentation/segments/{segmentUuid}` | Get segment details |
| `GET` | `/api/reach/v1/segmentation/segments/{segmentUuid}/contacts` | List segment contacts (paginated) |

### Profiles

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/reach/v1/profiles` | List sender profiles |

### Contact query parameters

| Parameter | Description |
|-----------|-------------|
| `page` | Page number |
| `group_uuid` | Filter by group UUID |
| `subscription_status` | Filter by subscription status |

### Segment condition operators

| Operator | Description |
|----------|-------------|
| `equals` / `not_equals` | Exact match |
| `contains` / `not_contains` | Partial match |
| `gte` / `lte` | Greater/less than or equal |
| `exists` | Field has a value |
| `within_last_days` / `not_within_last_days` | Date range |
| `older_than_days` | Older than N days |
| `opened` / `not_opened` | Email open engagement |
| `clicked` / `not_clicked` | Email click engagement |
| `bounced` / `not_bounced` | Bounce status |
| `delivered` / `not_delivered` | Delivery status |
| `unsubscribed` / `not_unsubscribed` | Unsubscribe status |

## Common patterns

### Create and manage contacts

```bash
# Create a new contact (direct)
curl -X POST "https://developers.hostinger.com/api/reach/v1/contacts" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "name": "John",
    "surname": "Doe",
    "phone": "+15551234567",
    "note": "Met at conference"
  }'

# Create a new contact (scoped to a specific sender profile)
curl -X POST "https://developers.hostinger.com/api/reach/v1/profiles/{profileUuid}/contacts" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "name": "John",
    "surname": "Doe"
  }'

# List contacts (paginated)
curl -X GET "https://developers.hostinger.com/api/reach/v1/contacts?page=1" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Filter contacts by subscription status
curl -X GET "https://developers.hostinger.com/api/reach/v1/contacts?subscription_status=active" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# List contact groups
curl -X GET "https://developers.hostinger.com/api/reach/v1/contacts/groups" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Delete a contact
curl -X DELETE "https://developers.hostinger.com/api/reach/v1/contacts/{uuid}" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Work with segments

```bash
# List all segments
curl -X GET "https://developers.hostinger.com/api/reach/v1/segmentation/segments" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Create a segment (e.g., engaged subscribers who opened emails)
curl -X POST "https://developers.hostinger.com/api/reach/v1/segmentation/segments" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Engaged Subscribers",
    "logic": "and",
    "conditions": [
      {
        "field": "subscription_status",
        "operator": "equals",
        "value": "active"
      },
      {
        "field": "email_engagement",
        "operator": "opened"
      }
    ]
  }'

# Get segment details
curl -X GET "https://developers.hostinger.com/api/reach/v1/segmentation/segments/{segmentUuid}" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# List contacts in a segment (paginated)
curl -X GET "https://developers.hostinger.com/api/reach/v1/segmentation/segments/{segmentUuid}/contacts?page=1&per_page=50" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Manage profiles

```bash
# List all sender profiles
curl -X GET "https://developers.hostinger.com/api/reach/v1/profiles" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## Best practices

### Contact management
- Use the direct `POST /contacts` endpoint for general contact creation; use `POST /profiles/{profileUuid}/contacts` when the contact must be tied to a specific sender profile.
- Prefer **segments** over **contact groups** for organizing contacts — groups are legacy.
- Enable double opt-in for compliance with email marketing regulations (GDPR, CAN-SPAM).
- Clean your contact list regularly by removing bounced and unsubscribed contacts.

### Segmentation
- Use `and` logic for narrow, precise targeting.
- Use `or` logic for broader audience reach.
- Combine engagement operators (`opened`, `clicked`) with time-based operators for re-engagement campaigns.
- Create segments before campaigns to preview audience size.

### Profiles
- Verify sender profiles to improve deliverability.
- Use consistent sender identity across campaigns.

## Troubleshooting

### Contact not receiving emails
- Check subscription status — contact may be unsubscribed or pending.
- If double opt-in is enabled, contact must confirm their email first.
- Verify the contact's email address is valid and not bouncing.

### Segment returns no contacts
- Verify conditions and operators are correct.
- Check that the `logic` field (`and`/`or`) matches your intent.
- Ensure contacts exist that match all/any conditions.

### 422 validation error on contact creation
- Missing required fields (email is required).
- Invalid email format.
- Duplicate email address in the system.

## References
- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI Tool: https://github.com/hostinger/api-cli
- API Changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
