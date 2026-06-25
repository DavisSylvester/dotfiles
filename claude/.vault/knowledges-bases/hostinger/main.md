# Hostinger API — knowledge base

Knowledge base for the **Hostinger API** (https://developers.hostinger.com). Covers
the eight public service areas: billing, DNS, domains, ecommerce, horizons, hosting,
reach, and VPS. Built from Hostinger's official agent-skills + API references.

## At a glance

- **API host / base URL:** `https://developers.hostinger.com`
- **Auth:** bearer token — `Authorization: Bearer $HOSTINGER_API_TOKEN`
  - Create tokens at https://hpanel.hostinger.com/profile/api
  - Never paste a token into chat; export it: `export HOSTINGER_API_TOKEN="…"`. Rotate immediately if exposed.
- **Response format:** JSON over HTTPS.

## Service areas

| Area | Base path | File | Endpoints |
|------|-----------|------|-----------|
| Billing | `/api/billing/v1/` | [billing.md](billing.md) | catalog, payment methods, subscriptions |
| DNS | `/api/dns/v1/` | [dns.md](dns.md) | zone records, snapshots (+ email DNS: SPF/DKIM/DMARC/MX) |
| Domains | `/api/domains/v1/` (+ `/api/v2/direct/`) | [domains.md](domains.md) | availability, portfolio, forwarding, WHOIS, nameservers, locks, privacy, access verifier |
| Ecommerce | `/api/ecommerce/v1/` | [ecommerce.md](ecommerce.md) | stores |
| Horizons | `/api/horizons/v1/` | [horizons.md](horizons.md) | AI website builder |
| Hosting | `/api/hosting/v1/` | [hosting.md](hosting.md) | datacenters, domains, orders, websites, databases, subdomains, parked domains, NodeJS, WordPress |
| Reach | `/api/reach/v1/` | [reach.md](reach.md) | email-marketing contacts, segments, profiles |
| VPS | `/api/vps/v1/` | [vps.md](vps.md) | VMs, Docker Manager, firewall, SSH keys, OS templates, post-install scripts, actions, backups, snapshots, recovery, PTR, malware scanner, metrics |

## Official SDKs & tools

| Tool | URL |
|------|-----|
| Python SDK | https://github.com/hostinger/api-python-sdk |
| TypeScript SDK | https://github.com/hostinger/api-typescript-sdk |
| PHP SDK | https://github.com/hostinger/api-php-sdk |
| CLI | https://github.com/hostinger/api-cli |
| Terraform provider | https://github.com/hostinger/terraform-provider-hostinger |
| Ansible collection | https://github.com/hostinger/ansible-collection-hostinger |
| MCP server | https://github.com/hostinger/api-mcp-server |
| n8n node | https://github.com/hostinger/api-n8n-node |
| WHMCS plugin | https://github.com/hostinger/api-whmcs-plugin |
| Postman | https://www.postman.com/hostinger-api |
| Agent skills | https://github.com/hostinger/hostinger-agent-skills |

## References

- API portal: https://developers.hostinger.com
- Changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
- Token management (hPanel): https://hpanel.hostinger.com/profile/api

_Generated 2026-06-25 from hostinger/hostinger-agent-skills (README + REFERENCES + per-area SKILL.md)._
