# Hostinger DNS API

> Base path: `/api/dns/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/dns) · doc portal: https://developers.hostinger.com

## Overview

The DNS API enables full management of DNS zone records for domains hosted on Hostinger. You can create, update, delete, validate, and reset DNS records, as well as manage DNS snapshots for backup and restore operations.

### DNS record types

Standard DNS record types are supported:

| Type | Purpose | Example |
|------|---------|---------|
| A | IPv4 address | `192.168.1.1` |
| AAAA | IPv6 address | `2001:db8::1` |
| CNAME | Canonical name alias | `www.example.com.` |
| ALIAS | ANAME/ALIAS record | `example.com.` |
| MX | Mail exchange | `mail.example.com.` |
| TXT | Text record | `v=spf1 include:...` |
| NS | Name server | `ns1.example.com.` |
| SOA | Start of authority | Zone authority info |
| SRV | Service locator | `_sip._tcp.example.com.` |
| CAA | Certificate authority auth | `0 issue "letsencrypt.org"` |

### Zone updates and the `overwrite` flag

When updating DNS records, the `overwrite` flag controls behavior:

- `overwrite: true` (default) — Replaces existing records matching name and type with the new records.
- `overwrite: false` — Updates TTL on existing records, appends new records; if no match found, creates them.

### Snapshots

DNS snapshots capture the state of a domain's DNS zone at a point in time. Use them to restore previous configurations if something goes wrong.

### TTL (Time-To-Live)

TTL controls how long DNS resolvers cache a record. Default is `14400` seconds (4 hours). Lower values propagate changes faster but increase DNS query load.

## Endpoints

### Zone records

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/dns/v1/zones/{domain}` | Get DNS records |
| `PUT` | `/api/dns/v1/zones/{domain}` | Update (create/update) DNS records |
| `DELETE` | `/api/dns/v1/zones/{domain}` | Delete DNS records |
| `POST` | `/api/dns/v1/zones/{domain}/reset` | Reset DNS to defaults |
| `POST` | `/api/dns/v1/zones/{domain}/validate` | Validate DNS records |

### Snapshots

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/dns/v1/snapshots/{domain}` | List DNS snapshots |
| `GET` | `/api/dns/v1/snapshots/{domain}/{snapshotId}` | Get snapshot with contents |
| `POST` | `/api/dns/v1/snapshots/{domain}/{snapshotId}/restore` | Restore from snapshot |

## Common patterns

### Get DNS records for a domain

```bash
curl -X GET "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Create/update DNS records

```bash
# Add an A record for www subdomain
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": true,
    "zone": [
      {
        "name": "www",
        "type": "A",
        "ttl": 14400,
        "records": [
          { "content": "192.168.1.1" }
        ]
      }
    ]
  }'

# Add MX records for email
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": true,
    "zone": [
      {
        "name": "@",
        "type": "MX",
        "ttl": 14400,
        "records": [
          { "content": "10 mail1.example.com." },
          { "content": "20 mail2.example.com." }
        ]
      }
    ]
  }'

# Add a TXT record for SPF (append, don't overwrite)
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": false,
    "zone": [
      {
        "name": "@",
        "type": "TXT",
        "ttl": 14400,
        "records": [
          { "content": "v=spf1 include:_spf.google.com ~all" }
        ]
      }
    ]
  }'
```

### Validate before updating

Returns `200` if valid, `422` if invalid.

```bash
curl -X POST "https://developers.hostinger.com/api/dns/v1/zones/example.com/validate" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": true,
    "zone": [
      {
        "name": "www",
        "type": "CNAME",
        "ttl": 14400,
        "records": [
          { "content": "example.com." }
        ]
      }
    ]
  }'
```

### Delete specific DNS records

Filters match by `name` AND `type` — both must match.

```bash
curl -X DELETE "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "filters": [
      { "name": "www", "type": "A" },
      { "name": "old", "type": "CNAME" }
    ]
  }'
```

### Reset DNS to defaults

Use `whitelisted_record_types` to preserve records, and `reset_email_records: false` to keep email records intact.

```bash
curl -X POST "https://developers.hostinger.com/api/dns/v1/zones/example.com/reset" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "sync": true,
    "reset_email_records": false,
    "whitelisted_record_types": ["MX", "TXT"]
  }'
```

### Work with DNS snapshots

```bash
# List available snapshots
curl -X GET "https://developers.hostinger.com/api/dns/v1/snapshots/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Get a specific snapshot with contents
curl -X GET "https://developers.hostinger.com/api/dns/v1/snapshots/example.com/42" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Restore from a snapshot
curl -X POST "https://developers.hostinger.com/api/dns/v1/snapshots/example.com/42/restore" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## Email DNS setup

Proper email DNS configuration is critical for deliverability and preventing spoofing. Email DNS requires four record kinds:

| Record | Purpose | Type |
|--------|---------|------|
| **MX** | Routes email to mail servers | MX |
| **SPF** | Declares which servers can send email for your domain | TXT |
| **DKIM** | Cryptographic signature verifying email authenticity | TXT (CNAME for Microsoft 365) |
| **DMARC** | Policy for handling emails that fail SPF/DKIM | TXT |

### MX records

MX records tell other mail servers where to deliver email for your domain.

**Google Workspace**

```bash
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": true,
    "zone": [
      {
        "name": "@",
        "type": "MX",
        "ttl": 3600,
        "records": [
          { "content": "1 aspmx.l.google.com." },
          { "content": "5 alt1.aspmx.l.google.com." },
          { "content": "5 alt2.aspmx.l.google.com." },
          { "content": "10 alt3.aspmx.l.google.com." },
          { "content": "10 alt4.aspmx.l.google.com." }
        ]
      }
    ]
  }'
```

**Microsoft 365**

```bash
{ "content": "0 example-com.mail.protection.outlook.com." }
```

**Hostinger Email**

```bash
{ "content": "5 mx1.hostinger.com." }
{ "content": "10 mx2.hostinger.com." }
```

### SPF records (TXT)

SPF declares which mail servers are authorized to send email for your domain. Use `overwrite: false` to preserve other TXT records.

- **Google Workspace:** `v=spf1 include:_spf.google.com ~all`
- **Microsoft 365:** `v=spf1 include:spf.protection.outlook.com ~all`
- **Multiple senders (combined):** `v=spf1 include:_spf.google.com include:mailgun.org ip4:198.51.100.10 ~all`

> **Important:** Only one SPF record per domain. Multiple SPF records cause validation failures.

```bash
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": false,
    "zone": [
      {
        "name": "@",
        "type": "TXT",
        "ttl": 3600,
        "records": [
          { "content": "v=spf1 include:_spf.google.com ~all" }
        ]
      }
    ]
  }'
```

### DKIM records

DKIM adds a cryptographic signature. Your email provider gives you the DKIM key value.

**Google Workspace (TXT)** — name `google._domainkey`:

```bash
{ "content": "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY_FROM_GOOGLE_ADMIN" }
```

**Microsoft 365 (CNAME)** — uses two selectors:

```bash
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": false,
    "zone": [
      {
        "name": "selector1._domainkey",
        "type": "CNAME",
        "ttl": 3600,
        "records": [
          { "content": "selector1-example-com._domainkey.example.onmicrosoft.com." }
        ]
      },
      {
        "name": "selector2._domainkey",
        "type": "CNAME",
        "ttl": 3600,
        "records": [
          { "content": "selector2-example-com._domainkey.example.onmicrosoft.com." }
        ]
      }
    ]
  }'
```

### DMARC records (TXT)

DMARC tells receiving servers what to do with emails that fail SPF/DKIM. Record name is `_dmarc`. Always start at `none`, monitor, then escalate.

- **Monitoring (start here):** `v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com; pct=100`
- **Quarantine (after monitoring):** `v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@example.com; pct=100`
- **Reject (full protection):** `v=DMARC1; p=reject; rua=mailto:dmarc-reports@example.com; pct=100`

```bash
curl -X PUT "https://developers.hostinger.com/api/dns/v1/zones/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": false,
    "zone": [
      {
        "name": "_dmarc",
        "type": "TXT",
        "ttl": 3600,
        "records": [
          { "content": "v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com; pct=100" }
        ]
      }
    ]
  }'
```

### Complete setup workflow

Set up all email records at once with `overwrite: false` to preserve existing records. Validate first, then apply if validation passes (`200`).

```bash
# Step 1: Validate first
curl -X POST "https://developers.hostinger.com/api/dns/v1/zones/example.com/validate" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "overwrite": false,
    "zone": [
      { "name": "@", "type": "MX", "ttl": 3600, "records": [
        { "content": "1 aspmx.l.google.com." },
        { "content": "5 alt1.aspmx.l.google.com." }
      ]},
      { "name": "@", "type": "TXT", "ttl": 3600, "records": [
        { "content": "v=spf1 include:_spf.google.com ~all" }
      ]},
      { "name": "_dmarc", "type": "TXT", "ttl": 3600, "records": [
        { "content": "v=DMARC1; p=none; rua=mailto:dmarc@example.com" }
      ]}
    ]
  }'

# Step 2: Apply via PUT with the same body if validation passes
```

### Verify with DNS lookups

```bash
dig MX example.com +short
dig TXT example.com +short | grep spf
dig TXT google._domainkey.example.com +short
dig TXT _dmarc.example.com +short
```

## Best practices

### Record management
- **Always validate** records with the `/validate` endpoint before applying changes.
- Use `overwrite: false` when adding records without removing existing ones.
- Use `overwrite: true` when you want to completely replace records of a given name/type.
- Use `@` as the name for root domain records.

### Safety
- **Take a snapshot** (or note existing records) before making bulk changes.
- Use the `whitelisted_record_types` parameter during reset to preserve email records (MX, TXT).
- Set `reset_email_records: false` when resetting if you use third-party email services.

### TTL
- Use lower TTL (300–600s) when planning changes for faster propagation.
- Increase TTL (14400s+) for stable records to reduce DNS query load.
- Old cached records persist until the previous TTL expires.

### Email records
- Be careful with MX records — incorrect changes break email delivery.
- SPF, DKIM, and DMARC records are TXT records — don't overwrite them accidentally.
- Only one SPF record per domain; combine multiple senders into one record.
- Include the trailing dot on MX hostnames (`aspmx.l.google.com.`, not `aspmx.l.google.com`).
- Don't use `overwrite: true` for TXT records — it deletes ALL TXT records including site verification.
- Start DMARC at `none`, monitor, then escalate to `quarantine`/`reject`.

## Troubleshooting

### Records not propagating
- DNS propagation can take up to 48 hours (usually much less).
- Check the TTL of the old record — resolvers cache for that duration.
- Verify with `dig` or `nslookup`: `dig @8.8.8.8 example.com A`.

### 422 validation error
- Invalid record content format (e.g., CNAME must end with `.`).
- Conflicting records (e.g., CNAME at root with other records).
- Invalid record type for the operation.

### Email stopped working after DNS change
- Check MX records: `dig example.com MX`.
- Verify SPF TXT record is intact.
- Use snapshot restore to revert if needed.

### Delete not working as expected
- Filters match by `name` AND `type` — both must match.
- If multiple records share name/type and you want to delete only some, use the update (`PUT`) endpoint instead.

## References

- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI tool: https://github.com/hostinger/api-cli
- API changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
