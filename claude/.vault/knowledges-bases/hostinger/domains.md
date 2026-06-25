# Hostinger Domains API

> Base path: `/api/domains/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/domains) · doc portal: https://developers.hostinger.com

## Overview

The Domains API provides full domain lifecycle management — from checking availability and purchasing to configuring nameservers, forwarding, WHOIS profiles, domain locks, and privacy protection.

Core concepts:

- **Domain portfolio** — all domains registered under your Hostinger account. Each domain has configuration for nameservers, WHOIS contacts, lock status, and privacy protection.
- **Domain availability** — check if a domain name is available across one or more TLDs before purchasing; supports alternative domain suggestions.
- **Domain forwarding** — redirect a domain to another URL using 301 (permanent) or 302 (temporary) redirects.
- **WHOIS profiles** — contact information associated with domain registrations. Each TLD may require specific WHOIS details. Profiles can be reused across multiple domains.
- **Domain lock** — prevents unauthorized domain transfers. Must be disabled before transferring a domain to another registrar.
- **Privacy protection** — hides the domain owner's personal information from public WHOIS databases.
- **Domain access verification** — some operations require proof that you control a domain. The Domain Access Verifier returns pending and completed verifications for a set of domains so you can check verification status before relying on a domain. This endpoint lives under a different base path — `/api/v2/direct/` — not `/api/domains/v1/`.

## Endpoints

### Availability

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/api/domains/v1/availability` | Check domain availability (rate limit: 10/min) |

### Portfolio

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/domains/v1/portfolio` | List all domains |
| `POST` | `/api/domains/v1/portfolio` | Purchase a new domain |
| `GET` | `/api/domains/v1/portfolio/{domain}` | Get domain details |
| `PUT` | `/api/domains/v1/portfolio/{domain}/nameservers` | Update nameservers |

### Forwarding

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/api/domains/v1/forwarding` | Create domain forwarding |
| `GET` | `/api/domains/v1/forwarding/{domain}` | Get forwarding config |
| `DELETE` | `/api/domains/v1/forwarding/{domain}` | Delete forwarding |

### WHOIS

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/domains/v1/whois` | List WHOIS profiles (optional `?tld=` filter) |
| `POST` | `/api/domains/v1/whois` | Create WHOIS profile |
| `GET` | `/api/domains/v1/whois/{whoisId}` | Get WHOIS profile |
| `DELETE` | `/api/domains/v1/whois/{whoisId}` | Delete WHOIS profile |
| `GET` | `/api/domains/v1/whois/{whoisId}/usage` | Get profile usage (which domains use it) |

### Nameservers

| Method | Path | Summary |
|--------|------|---------|
| `PUT` | `/api/domains/v1/portfolio/{domain}/nameservers` | Update nameservers |

### Domain lock

| Method | Path | Summary |
|--------|------|---------|
| `PUT` | `/api/domains/v1/portfolio/{domain}/domain-lock` | Enable domain lock (prevent transfers) |
| `DELETE` | `/api/domains/v1/portfolio/{domain}/domain-lock` | Disable domain lock (before transfer) |

### Privacy protection

| Method | Path | Summary |
|--------|------|---------|
| `PUT` | `/api/domains/v1/portfolio/{domain}/privacy-protection` | Enable privacy protection |
| `DELETE` | `/api/domains/v1/portfolio/{domain}/privacy-protection` | Disable privacy protection |

### Domain Access Verifier (different base path)

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/v2/direct/verifications/active` | Get pending and completed domain verifications (body: `domains` string array) |

## Common patterns

### Check domain availability

```bash
curl -X POST "https://developers.hostinger.com/api/domains/v1/availability" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "myawesomesite",
    "tlds": ["com", "net", "org"],
    "with_alternatives": true
  }'
```

> Rate limited to 10 requests per minute. TLDs should be without a leading dot (e.g. `com` not `.com`). For alternative suggestions, provide only one TLD and set `with_alternatives: true`.

### Purchase a domain

```bash
curl -X POST "https://developers.hostinger.com/api/domains/v1/portfolio" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "my-new-domain.com",
    "item_id": "hostingercom-domain-com-usd-1y",
    "payment_method_id": 1327362,
    "domain_contacts": {
      "owner_id": 741288,
      "admin_id": 741288,
      "billing_id": 741288,
      "tech_id": 741288
    }
  }'
```

> Get `item_id` from the billing catalog (`GET /api/billing/v1/catalog?category=domain`). If no payment method is provided, your default is used. If no WHOIS info is provided, default contact information for that TLD is used.

### List and view domains

```bash
# List all domains
curl -X GET "https://developers.hostinger.com/api/domains/v1/portfolio" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Get domain details
curl -X GET "https://developers.hostinger.com/api/domains/v1/portfolio/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Update nameservers

```bash
curl -X PUT "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/nameservers" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ns1": "ns1.custom-dns.com",
    "ns2": "ns2.custom-dns.com"
  }'
```

> Hostinger's default nameservers are `ns1.dns-parking.com` / `ns2.dns-parking.com`. The Hostinger DNS API only works with Hostinger nameservers; once you point to an external provider (Cloudflare, Route53, etc.), DNS is managed there.

### Domain forwarding

```bash
# Create forwarding (301 permanent redirect)
curl -X POST "https://developers.hostinger.com/api/domains/v1/forwarding" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "old-domain.com",
    "redirect_type": "301",
    "redirect_url": "https://new-domain.com"
  }'

# Get forwarding config
curl -X GET "https://developers.hostinger.com/api/domains/v1/forwarding/old-domain.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Delete forwarding
curl -X DELETE "https://developers.hostinger.com/api/domains/v1/forwarding/old-domain.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### WHOIS profile management

```bash
# List WHOIS profiles (optionally filter by TLD)
curl -X GET "https://developers.hostinger.com/api/domains/v1/whois?tld=com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Create a WHOIS profile
curl -X POST "https://developers.hostinger.com/api/domains/v1/whois" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tld": "com",
    "entity_type": "individual",
    "country": "US",
    "whois_details": {
      "first_name": "John",
      "last_name": "Doe",
      "email": "john@example.com",
      "phone": "+1.5551234567",
      "address": "123 Main St",
      "city": "New York",
      "state": "NY",
      "zip": "10001"
    }
  }'

# Check which domains use a WHOIS profile
curl -X GET "https://developers.hostinger.com/api/domains/v1/whois/741288/usage" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Delete a WHOIS profile
curl -X DELETE "https://developers.hostinger.com/api/domains/v1/whois/741288" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

> For an organization profile, set `entity_type: "organization"` and include `company_name` in `whois_details`.

### Domain lock & privacy protection

```bash
# Enable domain lock (prevent transfers)
curl -X PUT "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/domain-lock" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Disable domain lock (before transfer)
curl -X DELETE "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/domain-lock" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Enable privacy protection
curl -X PUT "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/privacy-protection" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Disable privacy protection
curl -X DELETE "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/privacy-protection" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Check domain verifications

```bash
# Get pending and completed verifications for one or more domains
curl -X GET "https://developers.hostinger.com/api/v2/direct/verifications/active" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "domains": ["example.com", "example.net"] }'
```

## Domain transfers

### Domain purchase workflow

1. **Check availability** — `POST /api/domains/v1/availability` with the desired name and TLDs. Rate limit 10/min. For alternative suggestions, provide only one TLD and set `with_alternatives: true`.
2. **Ensure a WHOIS profile exists** — list profiles for the target TLD (`GET /api/domains/v1/whois?tld=com`) and create one if needed (`POST /api/domains/v1/whois`).
3. **Get pricing from the catalog** — `GET /api/billing/v1/catalog?category=domain`. Look for `item_id` values like `hostingercom-domain-com-usd-1y`.
4. **Purchase** — `POST /api/domains/v1/portfolio` with `domain`, `item_id`, optional `payment_method_id`, and `domain_contacts`.
5. **Secure the domain** — enable domain lock and privacy protection via `PUT .../domain-lock` and `PUT .../privacy-protection`.

### Preparing for a transfer out (away from Hostinger)

```bash
# Step 1: Disable domain lock
curl -X DELETE "https://developers.hostinger.com/api/domains/v1/portfolio/example.com/domain-lock" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Step 2: Get domain details (includes auth/EPP code info)
curl -X GET "https://developers.hostinger.com/api/domains/v1/portfolio/example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Step 3: Initiate the transfer at the new registrar using the EPP code
#         (Done outside the Hostinger API)

# Step 4: Approve the transfer when notified
#         (Done via email or hPanel)
```

Transfer prerequisites and notes:

- **Domain lock must be disabled** before a transfer can proceed.
- **EPP / auth code** — retrieved from the domain details endpoint; supplied to the gaining registrar to authorize the transfer.
- **Status checks** — use the Domain Access Verifier (`GET /api/v2/direct/verifications/active`) to check pending/completed verifications; check registration/transfer status in [hPanel](https://hpanel.hostinger.com/).
- **Transfer lock periods** may apply after registration (typically 60 days for `.com`), during which a transfer cannot be initiated.

## Best practices

### Registration
- Always check availability before attempting to purchase.
- Ensure a WHOIS profile exists for the target TLD before registering.
- Some TLDs require `additional_details` during purchase — check requirements per TLD.
- Keep domain lock enabled to prevent unauthorized transfers.

### Security
- Enable **privacy protection** to hide personal information from public WHOIS.
- Enable **domain lock** on all production domains.
- Only disable domain lock immediately before an intended transfer.

### Nameservers
- Improper nameserver configuration makes the domain unresolvable.
- Always have at least 2 nameservers configured.
- Verify nameservers are responding before switching.

### Forwarding
- Use `301` (permanent) for SEO-preserving redirects.
- Use `302` (temporary) for short-term redirects.
- Remove forwarding before pointing the domain to hosting.

### TLD-specific considerations
- Some TLDs require `additional_details` during purchase (varies by TLD).
- WHOIS profile requirements differ by TLD — always specify the correct `tld` when creating profiles.
- Not all TLDs support domain lock or privacy protection.

## Troubleshooting

### Domain not resolving after nameserver change
- Nameserver changes can take up to 48 hours to propagate.
- Verify new nameservers are configured correctly: `dig NS example.com`.
- Check that DNS records exist on the new nameserver.

### Domain purchase failed
- Check registration status in [hPanel](https://hpanel.hostinger.com/).
- Verify the WHOIS profile is complete for the target TLD.
- Ensure the payment method has sufficient funds.

### Domain lock cannot be disabled
- Some TLDs have registrar-imposed lock periods after registration.
- Contact support if the lock state doesn't change.

### WHOIS profile deletion fails
- The profile may be in use by active domains.
- Check usage with the `/whois/{whoisId}/usage` endpoint first.

## References
- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI Tool: https://github.com/hostinger/api-cli
- API Changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
