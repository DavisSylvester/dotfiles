# Hostinger Hosting API

> Base path: `/api/hosting/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/hosting) · doc portal: https://developers.hostinger.com

## Overview

The Hosting API manages shared hosting services: creating websites, listing orders, selecting datacenters, verifying domain ownership, generating free subdomains, managing MySQL databases, subdomains and parked domains, deploying Node.js applications, and installing WordPress.

Key concepts:

- **Websites** — the core hosting resource, each tied to a domain and a hosting order (types: main, addon). Creating the first website on a plan triggers hosting account provisioning.
- **Orders** — purchased hosting plans, filterable by status and ID. Shared-access orders (granted by other accounts) appear alongside your own.
- **Datacenters** — required when creating the *first* website on a new plan. The first item in the datacenter list is the best match for the order; later websites reuse the same datacenter automatically.
- **Domain verification** — required before using a custom domain. Add the provided TXT record to DNS and verify; propagation can take up to 10 minutes. Hostinger free subdomains (`*.hostingersite.com`) skip verification.
- **Free subdomains** — free hostnames under `*.hostingersite.com` for immediate use without a custom domain.
- **Hosting accounts (`username`)** — many operations are scoped to a hosting account identified by its `username`, returned in the websites list. It is the path root for databases, subdomains, parked domains, Node.js builds, and per-account WordPress installs (`/api/hosting/v1/accounts/{username}/...`). Database names and users are auto-prefixed with this username.
- **Databases** — each account holds multiple MySQL databases, each with its own user/password, assigned to a website domain. Supports create, delete, change-password, repair, and phpMyAdmin SSO link.
- **Subdomains** — additional hostnames under a website (`blog.example.com`), each with its own document root.
- **Parked domains** (alias domains) — additional domains that serve the *same* content as the parent website.
- **Node.js applications** — build pipeline on Node.js-capable plans. Recommended flow uploads a project archive, auto-detects settings from `package.json`, and starts a build in one step. Each build has a `uuid` and a state (`pending`, `running`, `completed`, `failed`); poll logs with `from_line` to stream output.
- **WordPress** — install on an existing website (create it first, then poll). Installation is asynchronous; poll the installations list to confirm readiness.

## Endpoints

### Datacenters

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/datacenters` | List available datacenters (requires `order_id` query param) |

### Domains

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/api/hosting/v1/domains/free-subdomains` | Generate a free subdomain |
| `POST` | `/api/hosting/v1/domains/verify-ownership` | Verify domain ownership |

### Orders

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/orders` | List hosting orders (paginated, filterable; e.g. `statuses`) |

### Websites

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/websites` | List websites (paginated, filterable) |
| `POST` | `/api/hosting/v1/websites` | Create a new website |

Website query params: `page`, `per_page`, `username`, `order_id`, `is_enabled`, `domain`.

### Databases

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/accounts/{username}/databases` | List account databases (filters: `page`, `per_page`, `domain`, `is_assigned`, `search`) |
| `POST` | `/api/hosting/v1/accounts/{username}/databases` | Create a database with user and password |
| `DELETE` | `/api/hosting/v1/accounts/{username}/databases/{name}` | Delete a database (use full prefixed name) |
| `PATCH` | `/api/hosting/v1/accounts/{username}/databases/{name}/change-password` | Change database user password |
| `GET` | `/api/hosting/v1/accounts/{username}/databases/{name}/phpmyadmin-link` | Get phpMyAdmin single sign-on link |
| `PATCH` | `/api/hosting/v1/accounts/{username}/databases/{name}/repair` | Repair corrupted tables (async) |

### Subdomains

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/accounts/{username}/websites/{domain}/subdomains` | List website subdomains |
| `POST` | `/api/hosting/v1/accounts/{username}/websites/{domain}/subdomains` | Create a subdomain |
| `DELETE` | `/api/hosting/v1/accounts/{username}/websites/{domain}/subdomains/{subdomain}` | Delete a subdomain |

### Parked domains

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/accounts/{username}/websites/{domain}/parked-domains` | List parked (alias) domains |
| `POST` | `/api/hosting/v1/accounts/{username}/websites/{domain}/parked-domains` | Create a parked domain |
| `DELETE` | `/api/hosting/v1/accounts/{username}/websites/{domain}/parked-domains/{parkedDomain}` | Delete a parked domain |

### NodeJS

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/api/hosting/v1/accounts/{username}/websites/{domain}/nodejs/builds` | List builds (filters: `page`, `per_page`, `states`) |
| `POST` | `/api/hosting/v1/accounts/{username}/websites/{domain}/nodejs/builds/from-archive` | Create and start a build from an archive |
| `GET` | `/api/hosting/v1/accounts/{username}/websites/{domain}/nodejs/builds/{uuid}/logs` | Get build logs (poll with `from_line`) |

### WordPress

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/api/hosting/v1/accounts/{username}/wordpress/installations` | Install WordPress on an existing website |
| `GET` | `/api/hosting/v1/wordpress/installations` | List WordPress installations (filters: `username`, `domain`, `ownership`) |

## Common patterns

### Create a website (full flow)

```bash
# Step 1: List available datacenters for your order
curl -X GET "https://developers.hostinger.com/api/hosting/v1/datacenters?order_id=12345" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Step 2: Generate a free subdomain (optional, if no custom domain)
curl -X POST "https://developers.hostinger.com/api/hosting/v1/domains/free-subdomains" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Step 3: Verify domain ownership (skip for *.hostingersite.com)
curl -X POST "https://developers.hostinger.com/api/hosting/v1/domains/verify-ownership" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "domain": "example.com" }'

# Step 4: Create the website
curl -X POST "https://developers.hostinger.com/api/hosting/v1/websites" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "order_id": 12345,
    "datacenter_code": "us-east-1"
  }'
```

### List websites

```bash
# All websites
curl -X GET "https://developers.hostinger.com/api/hosting/v1/websites" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Filter by order ID
curl -X GET "https://developers.hostinger.com/api/hosting/v1/websites?order_id=12345" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Filter by domain
curl -X GET "https://developers.hostinger.com/api/hosting/v1/websites?domain=example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Paginate
curl -X GET "https://developers.hostinger.com/api/hosting/v1/websites?page=2&per_page=25" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### List hosting orders

```bash
# All orders
curl -X GET "https://developers.hostinger.com/api/hosting/v1/orders" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Filter by status
curl -X GET "https://developers.hostinger.com/api/hosting/v1/orders?statuses=active" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Manage databases

```bash
# List databases for an account (filter by domain / assignment / search)
curl -X GET "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/databases?domain=example.com&is_assigned=true" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Create a database (name and user are auto-prefixed with the account username)
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/databases" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "appdb",
    "user": "appuser",
    "password": "SecurePass123!",
    "website_domain": "example.com"
  }'

# Change the database user password (also update it in your site config)
curl -X PATCH "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/databases/u123456789_appdb/change-password" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "password": "NewSecurePass456!" }'

# Get a single sign-on phpMyAdmin link
curl -X GET "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/databases/u123456789_appdb/phpmyadmin-link" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Repair corrupted tables (asynchronous)
curl -X PATCH "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/databases/u123456789_appdb/repair" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Delete a database (use the full name from the list endpoint)
curl -X DELETE "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/databases/u123456789_appdb" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Manage subdomains and parked domains

```bash
# List subdomains for a website
curl -X GET "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/subdomains" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Create a subdomain (optionally with a custom directory)
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/subdomains" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subdomain": "blog",
    "directory": "blog",
    "is_using_public_directory": false
  }'

# Delete a subdomain
curl -X DELETE "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/subdomains/blog" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Park a domain so it serves the same content as the parent website
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/parked-domains" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "parked_domain": "example.net" }'

# Remove a parked domain
curl -X DELETE "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/parked-domains/example.net" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Deploy a Node.js application

```bash
# Create and start a build from a project archive (settings auto-detected from package.json)
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/nodejs/builds/from-archive" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "archive": "uploads/my-app.zip",
    "node_version": 20,
    "app_type": "ssr",
    "build_script": "build",
    "entry_file": "server.js",
    "package_manager": "npm"
  }'

# List builds (filter by state)
curl -X GET "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/nodejs/builds?states[]=running" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Stream build logs while running (poll with from_line = previously returned line count)
curl -X GET "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/websites/example.com/nodejs/builds/3f9a.../logs?from_line=0" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Install WordPress

```bash
# Step 1: ensure the website exists (POST /websites, then poll GET /websites)
# Step 2: install WordPress on it
curl -X POST "https://developers.hostinger.com/api/hosting/v1/accounts/u123456789/wordpress/installations" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "example.com",
    "site_title": "My Site",
    "language": "en_US",
    "directory": "public_html",
    "auto_updates": "minor",
    "credentials": {
      "email": "owner@example.com",
      "login": "admin",
      "password": "SecureAdminPass123!"
    }
  }'

# Step 3: poll for readiness (installation is asynchronous)
curl -X GET "https://developers.hostinger.com/api/hosting/v1/wordpress/installations?username=u123456789&domain=example.com" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

## Best practices

**Website creation**
- Select the recommended datacenter (first in the list) unless you have geographic requirements.
- `datacenter_code` is only required for the **first** website on a new hosting plan.
- Domain name cannot start with `www.` — use the bare domain.
- Creation takes up to a few minutes — poll the list endpoint to check status.

**Domain verification**
- Skip verification for Hostinger free subdomains (`*.hostingersite.com`).
- DNS TXT record propagation can take up to 10 minutes; verify before creating the website.

**Free subdomains**
- Use them for testing or quick starts; you can connect a custom domain later.

**Orders**
- Use filters to narrow results instead of fetching everything. Shared-access orders appear alongside your own.

**Databases**
- `name` and `user` are auto-prefixed with the account `username` — always use the **full name** from the list endpoint for delete / change-password / repair / phpMyAdmin calls.
- After `change-password`, update credentials in any site config (e.g. `wp-config.php`) that uses the database.
- `repair` runs asynchronously — re-list or retry rather than expecting an immediate result.

**Subdomains & parked domains**
- Use **subdomains** for separate content under a host (`blog.example.com`); use **parked domains** to serve the same content from another domain.
- Subdomain DNS must point to Hostinger for the host to resolve.

**Node.js**
- Prefer the `from-archive` endpoint — it auto-detects build settings from `package.json` in one step.
- Poll the logs endpoint with `from_line` (the previous `lines` count) to stream only new output while the build state is `running`.

**WordPress**
- The target website must exist **before** installing — create it first and poll the websites list.
- Installation is asynchronous; confirm completion by polling `GET /wordpress/installations`.
- Use `auto_updates: minor` (default-safe) unless you have a reason to disable updates.

## Troubleshooting

**Website creation failing** — Verify domain ownership first (unless using a free subdomain); ensure `order_id` is valid and belongs to an active plan; `datacenter_code` is required for the first website; domain cannot start with `www.`.

**Domain verification failing** — TXT record may not have propagated (wait up to 10 minutes); confirm with `dig TXT example.com`; verify the bare domain, not a subdomain.

**Datacenter list empty** — Ensure `order_id` is provided and valid; the order may have no available capacity in any datacenter.

**Website not appearing after creation** — Provisioning takes a few minutes; poll the websites list until it becomes available.

**Database operation returns 404** — Use the **full** prefixed database name (e.g. `u123456789_appdb`) from the list endpoint, not the short name passed to create; confirm the `username` in the path owns the database.

**Node.js build fails** — Check build logs (`GET .../nodejs/builds/{uuid}/logs`); verify `package.json` exists in the archive and `build_script`/`entry_file` are correct; ensure `node_version` matches your app.

**WordPress install not completing** — Confirm the website exists first (`GET /websites`); installation is async, so poll `GET /wordpress/installations` (filter by `username` + `domain`); set `overwrite: true` only if you intend to replace existing files in the target directory.

## References

- API portal: https://developers.hostinger.com
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI Tool: https://github.com/hostinger/api-cli
- API Changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
