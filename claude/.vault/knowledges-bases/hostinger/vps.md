# Hostinger VPS API

> Base path: `/api/vps/v1/` · Auth: `Authorization: Bearer $HOSTINGER_API_TOKEN`
> Source: hostinger/hostinger-agent-skills (skills/vps) · doc portal: https://developers.hostinger.com

## Overview

The VPS API provides comprehensive management of virtual private servers — from purchasing and setup to Docker deployments, firewall configuration, SSH keys, backups, snapshots, OS reinstallation, recovery mode, malware scanning, PTR records, and performance monitoring. Host: `https://developers.hostinger.com`.

Core concepts:

- **Virtual Machines** — VPS instances with dedicated CPU, RAM, disk, and network. Each VM has an OS template, root access, and an IP address. States: `initial` → `running` → `stopped`.
- **Actions** — asynchronous operations on VMs (start, stop, restart, recreate, etc.) return an action resource with a status you can poll.
- **Docker Manager** (experimental) — deploy and manage Docker Compose projects directly on VPS instances. Supports inline `docker-compose.yaml` content or GitHub/raw URLs.
- **Firewalls** — network security rules controlling inbound traffic. Default policy is DROP all; add explicit accept rules. Only one firewall active per VM at a time. Changes require **manual sync** to take effect.
- **SSH Public Keys** — managed at the account level, attached to specific VMs.
- **OS Templates** — pre-configured OS images (Ubuntu, Debian, CentOS, etc.), including panel templates (cPanel/Plesk).
- **Post-Install Scripts** — run after VM installation, saved to `/post_install` with executable permissions; output to `/post_install.log`. Max size 48KB.
- **Backups** — automatic periodic backups managed by Hostinger. **Snapshots** — user-initiated point-in-time captures; only one per VM (new snapshot overwrites the existing one).
- **Recovery Mode** — boot from a recovery disk image; original disk mounted at `/mnt`.
- **Malware Scanner (Monarx)** — optional security tool for malware detection/prevention.

## Endpoints

### Virtual machine

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/virtual-machines` | List all VMs |
| `POST` | `/virtual-machines` | Purchase new VM |
| `GET` | `/virtual-machines/{id}` | Get VM details |
| `POST` | `/virtual-machines/{id}/setup` | Setup purchased VM (from `initial` state) |
| `PUT` | `/virtual-machines/{id}/hostname` | Set hostname |
| `DELETE` | `/virtual-machines/{id}/hostname` | Reset hostname |
| `PUT` | `/virtual-machines/{id}/root-password` | Set root password |
| `PUT` | `/virtual-machines/{id}/panel-password` | Set panel password |
| `PUT` | `/virtual-machines/{id}/nameservers` | Set nameservers |
| `GET` | `/virtual-machines/{id}/public-keys` | Get attached SSH keys |

### Actions

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/virtual-machines/{id}/start` | Start VM |
| `POST` | `/virtual-machines/{id}/stop` | Stop VM |
| `POST` | `/virtual-machines/{id}/restart` | Restart VM |
| `POST` | `/virtual-machines/{id}/recreate` | Recreate VM (DESTRUCTIVE — all data lost) |
| `GET` | `/virtual-machines/{id}/actions` | Get action history |
| `GET` | `/virtual-machines/{id}/actions/{actionId}` | Get action details (poll status) |

### Docker Manager (experimental)

Base: `/virtual-machines/{id}/docker`

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/docker` | List projects (with container status) |
| `POST` | `/docker` | Create project (inline content or URL) |
| `GET` | `/docker/{name}` | Get project contents |
| `GET` | `/docker/{name}/containers` | Get containers with stats (CPU/memory/network) |
| `GET` | `/docker/{name}/logs` | Get project logs (last 300 entries) |
| `POST` | `/docker/{name}/start` | Start project |
| `POST` | `/docker/{name}/stop` | Stop project (preserves data) |
| `POST` | `/docker/{name}/restart` | Restart project (preserves volumes/networks) |
| `POST` | `/docker/{name}/update` | Update project (pull latest images, recreate, preserve volumes) |
| `DELETE` | `/docker/{name}/down` | Delete project — removes networks/volumes/images (irreversible) |

### Firewall

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/firewall` | List firewalls |
| `POST` | `/firewall` | Create firewall |
| `GET` | `/firewall/{id}` | Get firewall details |
| `DELETE` | `/firewall/{id}` | Delete firewall (auto-deactivates on all VMs) |
| `POST` | `/firewall/{id}/rules` | Create rule |
| `PUT` | `/firewall/{id}/rules/{ruleId}` | Update rule |
| `DELETE` | `/firewall/{id}/rules/{ruleId}` | Delete rule |
| `POST` | `/firewall/{id}/activate/{vmId}` | Activate firewall on VM |
| `POST` | `/firewall/{id}/deactivate/{vmId}` | Deactivate firewall on VM |
| `POST` | `/firewall/{id}/sync/{vmId}` | Sync rules to VM (required after changes) |

### Public Keys

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/public-keys` | List SSH keys |
| `POST` | `/public-keys` | Create SSH key |
| `DELETE` | `/public-keys/{id}` | Delete SSH key |
| `POST` | `/public-keys/attach/{vmId}` | Attach keys to VM (`{ "ids": [...] }`) |

### OS Templates

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/templates` | List OS templates |
| `GET` | `/templates/{id}` | Get template details |

### Post-install scripts

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/post-install-scripts` | List scripts |
| `POST` | `/post-install-scripts` | Create script |
| `PUT` | `/post-install-scripts` | Update script |
| `DELETE` | `/post-install-scripts` | Delete script |

### Backups

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/virtual-machines/{id}/backups` | List backups |
| `POST` | `/virtual-machines/{id}/backups/{backupId}/restore` | Restore backup (DESTRUCTIVE — overwrites all data) |

### Snapshots

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/virtual-machines/{id}/snapshot` | Get current snapshot |
| `POST` | `/virtual-machines/{id}/snapshot` | Create snapshot (overwrites existing) |
| `DELETE` | `/virtual-machines/{id}/snapshot` | Delete snapshot |
| `POST` | `/virtual-machines/{id}/snapshot/restore` | Restore from snapshot |

### Recovery

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/virtual-machines/{id}/recovery` | Start recovery mode (original disk at `/mnt`) |
| `DELETE` | `/virtual-machines/{id}/recovery` | Stop recovery mode |

### PTR records

| Method | Path | Summary |
|--------|------|---------|
| `POST` | `/virtual-machines/{id}/ptr/{ipId}` | Create PTR record |
| `DELETE` | `/virtual-machines/{id}/ptr/{ipId}` | Delete PTR record |

### Malware scanner (Monarx)

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/virtual-machines/{id}/monarx` | Get malware scanner status |
| `POST` | `/virtual-machines/{id}/monarx` | Install/enable Monarx |
| `DELETE` | `/virtual-machines/{id}/monarx` | Remove Monarx |

### Metrics

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/virtual-machines/{id}/metrics` | Get metrics (CPU, memory, disk, network, uptime) — supports `date_from` / `date_to` |

### Data centers

| Method | Path | Summary |
|--------|------|---------|
| `GET` | `/data-centers` | List data centers |

## Common patterns

### Purchase and setup a VPS

```bash
# 1. Get available OS templates
curl -X GET "https://developers.hostinger.com/api/vps/v1/templates" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# 2. Get available data centers
curl -X GET "https://developers.hostinger.com/api/vps/v1/data-centers" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# 3. Purchase a VPS
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "item_id": "hostingercom-vps-kvm2-usd-1m",
    "payment_method_id": 517244,
    "template_id": 1,
    "data_center_id": 1,
    "hostname": "my-server",
    "password": "SecurePass123!"
  }'

# 4. Setup a purchased VM (if in initial state)
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/setup" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "template_id": 1, "data_center_id": 1, "hostname": "my-server", "password": "SecurePass123!" }'
```

### Change credentials / hostname / install OS template

```bash
# Set hostname
curl -X PUT "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/hostname" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "hostname": "new-hostname.example.com" }'

# Set root password
curl -X PUT "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/root-password" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "password": "NewSecurePass123!" }'

# Recreate VM = reinstall OS template (DESTRUCTIVE — all data lost)
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/recreate" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "template_id": 1, "password": "SecurePass123!" }'
```

### SSH key management

```bash
# Create SSH key
curl -X POST "https://developers.hostinger.com/api/vps/v1/public-keys" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "name": "my-laptop", "key": "ssh-ed25519 AAAA... user@host" }'

# Attach key(s) to VM
curl -X POST "https://developers.hostinger.com/api/vps/v1/public-keys/attach/12345" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN" -H "Content-Type: application/json" \
  -d '{ "ids": [1, 2] }'
```

### Backups and snapshots

```bash
# List backups
curl -X GET "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/backups" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Restore a backup (DESTRUCTIVE — overwrites all data)
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/backups/99/restore" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Create a snapshot (overwrites existing snapshot)
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/snapshot" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Restore from snapshot
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/snapshot/restore" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### Recovery mode and metrics

```bash
# Start recovery mode (original disk mounted at /mnt)
curl -X POST "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/recovery" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"

# Get VM metrics over a time range
curl -X GET "https://developers.hostinger.com/api/vps/v1/virtual-machines/12345/metrics?date_from=2025-05-01T00:00:00Z&date_to=2025-06-01T00:00:00Z" \
  -H "Authorization: Bearer $HOSTINGER_API_TOKEN"
```

### SDK quickstart (list VMs)

```python
from hostinger_api import Hostinger
client = Hostinger(api_token="YOUR_API_TOKEN")
for vm in client.vps.virtual_machines.list():
    print(f"{vm.hostname} - {vm.state} - {vm.ip_address}")
```

```typescript
import { Hostinger } from "hostinger-api-sdk";
const client = new Hostinger({ apiToken: "YOUR_API_TOKEN" });
const vms = await client.vps.virtualMachines.list();
```

CLI: `hapi vps vm list`

## Deployment workflow

SSH-first workflow for deploying Dockerized apps: use SSH + Docker Compose as the primary deploy mechanism, and the Hostinger API for account-level infrastructure (SSH keys, firewall, snapshots/backups, VM status/restart, Monarx).

**SSH vs Docker Manager API:** use SSH + Compose for production deploys with existing compose files, complex multi-service apps with migrations, fine-grained startup-order control, and repos with existing deploy scripts. Use the Docker Manager API for quick prototyping without SSH, simple single-container deploys, and GitHub-URL deploys. Rule of thumb: if the project already has a working `docker-compose.yaml`, use SSH — don't replace it with the Docker Manager API unless asked.

**Steps:** `1. Gather Inputs → 2. SSH Key Setup → 3. VPS Baseline → 4. Deploy/Update → 5. Verify → 6. Rollback Plan → 7. API Guardrails`

1. **Gather inputs** — `HOSTINGER_API_TOKEN`, `HOSTINGER_VPS_ID`, `SSH_USER`, `SSH_HOST`, `SSH_KEY` (private key path), `REMOTE_APP_DIR`. Reuse existing repo deploy scripts/runbooks first.
2. **SSH key setup** — `ssh-keygen -t ed25519 -C "hostinger-vps" -f ~/.ssh/hostinger_vps`, register via `POST /public-keys` (with `key` = contents of the `.pub`), attach via `POST /public-keys/attach/{vmId}`, then verify: `ssh -i ~/.ssh/hostinger_vps $SSH_USER@$SSH_HOST "echo SSH_OK && whoami && hostname"`.
3. **VPS baseline (first-time)** — over SSH: install Docker (`curl -fsSL https://get.docker.com | sh`), enable/start it, install `docker-compose-plugin`, `mkdir -p ~/app`, verify `docker compose version`. Configure firewall via API (SSH + only required app ports; DB ports NOT public). Checklist: Docker running, Compose plugin present, deploy dir exists, `.env` populated, firewall allows 22 + app ports only.
4. **Deploy/update** — first deploy: `rsync -avz -e "ssh -i $SSH_KEY" --exclude='.git' --exclude='node_modules' ./ $SSH_USER@$SSH_HOST:$REMOTE_APP_DIR/`, `scp` the `.env` (never commit), then SSH in and bring up in order: **dependencies (`db redis`) → wait → migrations (`docker compose run --rm app npm run migrate`) → `docker compose up -d`**. Updates: `docker compose pull` / `docker compose up -d --build`, then run new migrations. Keep same startup order; avoid `docker compose down -v`; keep commands idempotent.
5. **Verify** — Level 1 container health (`docker compose ps`, check for restart loops), Level 2 logs (`docker compose logs --tail=200 app`, grep error/fatal/exception), Level 3 functional smoke test (`curl -sf https://app/health`). Run a real end-to-end test from the client surface.
6. **Rollback** — before risky deploys (migrations, major bumps): create a VPS snapshot via API and/or a DB dump (`pg_dump`/`mysqldump`) on the VPS. On failure: restore previous compose/image (`git checkout HEAD~1 -- docker-compose.yaml`), `docker compose up -d`, restore DB from dump if migration was incompatible. Nuclear option: `POST /virtual-machines/{id}/snapshot/restore` (overwrites everything).
7. **API guardrails / when to use what** — SSH for deploy, migrations, logs. API for registering SSH keys, firewall config, snapshots/backups, Monarx, automation status checks, and VM restart.

**Safety rules:** never print secrets; never commit `.env`; never `docker compose down -v` in prod without approval; validate critical env vars before deploy; keep commands idempotent; snapshot before migrations; don't expose DB ports publicly.

## Docker patterns

**Deployment methods (`POST .../docker`):**

- **Inline content** — `{ "project_name": "...", "content": "<docker-compose.yaml>" }`. Best for simple projects / full control.
- **GitHub repo** — `{ "project_name": "...", "url": "https://github.com/user/repo" }`. Auto-resolves to `docker-compose.yaml` in the master branch (format must be `https://github.com/[user]/[repo]`, file in repo root of master).
- **Any raw URL** — any URL returning raw `docker-compose.yaml`, e.g. `https://raw.githubusercontent.com/user/repo/main/docker-compose.yaml` (use raw URL for non-master branches).

Deploying a project with the **same name replaces** the existing one (zero-config redeploy).

**Lifecycle:** monitor via `GET /docker` (projects + status), `GET /docker/{name}/containers` (CPU/mem/net stats), `GET /docker/{name}/logs` (last 300). `POST .../update` pulls latest images and recreates containers while **preserving data volumes**. `POST .../stop` + `.../start` or `.../restart` preserve volumes/networks. `DELETE .../down` stops containers and removes networks/volumes/images (irreversible).

**Example stacks** (inline `content`): WordPress + MySQL 8.0 (named volumes `wp_data`/`db_data`, `depends_on: db`); Node 20 API + Redis 7 + Postgres 16 (`DATABASE_URL`, `REDIS_URL`, `depends_on: [db, cache]`); Traefik v3.0 reverse proxy with Let's Encrypt SSL (mounts `/var/run/docker.sock:ro`, ports 80/443, `letsencrypt` volume, router rules via `traefik.http.routers.*` labels).

**Troubleshooting:** container restart loops → check logs (missing env vars, bad image name, port conflicts); port already in use → only one service per host port, check `GET /docker`; out of disk → check `GET /metrics`, clean unused projects; GitHub URL failing → verify format and that `docker-compose.yaml` is in master root.

## Firewall patterns

How firewalls work: **default policy DROP all**; **one firewall per VM**; **manual sync required** after rule add/update/delete; firewalls are account-level resources activated on specific VMs. Lifecycle: `Create → Add Rules → Activate on VM → (Modify Rules → Sync to VM)`.

Rule body: `{ "protocol": "tcp", "port": "<port|range>", "source": "<CIDR>", "action": "accept" }`. Ports support single (`"80"`) and ranges (`"3000:3999"`).

**Common configs:**

- **Web server** — accept tcp 22, 80, 443 from `0.0.0.0/0`; activate on VM.
- **Database server (restricted)** — SSH from office IP only (`203.0.113.50/32`), Postgres `5432` / MySQL `3306` from the app server IP only (`198.51.100.10/32`).
- **Docker host** — SSH 22, HTTP/HTTPS 80/443, plus a custom app port range like `3000:3999`.
- **Mail server** — SSH 22, SMTP 25, SMTPS 465, Submission 587, IMAP 143, IMAPS 993.

**Modifying / switching:** after `PUT .../rules/{ruleId}` or `DELETE .../rules/{ruleId}`, always `POST .../sync/{vmId}`. To switch firewalls: `POST .../firewall/1/deactivate/{vmId}` then `POST .../firewall/2/activate/{vmId}`.

**Hardening checklist:** open only ports you use; restrict SSH to known IPs; use a non-standard SSH port to cut scan noise; restrict DB ports to app-server IPs; always sync after changes; review rules periodically; delete unused firewalls (deleting auto-deactivates on all VMs).

## Terraform

Uses the [Hostinger Terraform Provider](https://github.com/hostinger/terraform-provider-hostinger) (`source = "hostinger/hostinger"`). Auth via `HOSTINGER_API_TOKEN` env var or `api_token` in the `provider` block. The provider wraps the same API — resource names map to API endpoints.

**Provider + init:**

```hcl
terraform {
  required_providers {
    hostinger = { source = "hostinger/hostinger" }
  }
}
provider "hostinger" {}  # reads HOSTINGER_API_TOKEN
```

**Resources & data sources:**

- Data: `hostinger_vps_templates`, `hostinger_vps_data_centers`, `hostinger_billing_catalog` (e.g. `category = "vps"`).
- `hostinger_vps` — args: `hostname`, `template_id`, `data_center`, `item_id` (e.g. `hostingercom-vps-kvm2-usd-1m`), `password`; exports `ip_address`. Use `for_each` for multi-server clusters.
- `hostinger_vps_ssh_key` — `name`, `key` (e.g. `file("~/.ssh/id_ed25519.pub")`).
- `hostinger_vps_ssh_key_attachment` — `virtual_machine_id`, `ssh_key_ids = [...]`.
- `hostinger_vps_firewall` — `name`.
- `hostinger_vps_firewall_rule` — `firewall_id`, `protocol`, `port`, `source`, `action`.
- `hostinger_vps_firewall_activation` — `firewall_id`, `virtual_machine_id`.
- `hostinger_vps_post_install_script` — `name`, `content` (heredoc).

```hcl
data "hostinger_vps_templates" "all" {}
data "hostinger_vps_data_centers" "all" {}

resource "hostinger_vps" "web" {
  hostname    = "web-server"
  template_id = data.hostinger_vps_templates.all.templates[0].id
  data_center = data.hostinger_vps_data_centers.all.data_centers[0].id
  item_id     = "hostingercom-vps-kvm2-usd-1m"
  password    = var.root_password  # sensitive = true
}

output "server_ip" { value = hostinger_vps.web.ip_address }
```

A complete example provisions web + DB servers, attaches a shared SSH key, and gives each VM its own firewall (web: 22 from admin IP, 80/443 public; db: 22 from admin IP, 5432 from `"${hostinger_vps.web.ip_address}/32"`). Apply with `-var` flags; mark passwords/private IPs `sensitive = true`; store state remotely for teams.

## Best practices

**Security:** attach SSH keys and disable password auth when possible; configure firewalls (default DROP) and open only needed ports; **sync firewalls after every rule change**; only one firewall per VM (plan rules in one); install Monarx on production; use strong passwords (12+ chars, mixed case + numbers, not leaked).

**Backups & recovery:** snapshot before destructive ops (recreate, major changes); a new snapshot **overwrites** the existing one; backup restores **overwrite all data**; recovery mode mounts the original disk at `/mnt`.

**Docker:** Docker Manager endpoints are **experimental**; GitHub URLs resolve to master-branch `docker-compose.yaml`; deploying an existing project name **replaces** it; use the logs endpoint for debugging.

**Performance:** monitor metrics to right-size the plan; set custom nameservers only if you know what you're doing (wrong config breaks DNS).

**Post-install scripts:** max 48KB; runs as `/post_install`, output to `/post_install.log`; test on non-production VMs first.

## Troubleshooting

- **VM not starting** — check action history for errors; may be in recovery mode (stop it first); may be in `initial` state (run setup first).
- **Cannot SSH** — verify the key is attached (not just in account); firewall allows 22; firewall is synced after changes; try root password to diagnose.
- **Firewall rules not taking effect** — require manual sync (`POST .../firewall/{id}/sync/{vmId}`); only one firewall active per VM; default policy is DROP, so ensure accept rules exist.
- **Docker project not starting** — check `GET .../docker/{name}/logs`; validate the compose file; ensure ports aren't in use; ensure enough CPU/RAM/disk.
- **Password rejected during recreate** — must be 12+ chars with upper/lower/numbers; checked against leaked-password databases; use a unique complex password.
- **Action stuck in progress** — poll `GET .../actions/{actionId}`; recreate/backup-restore can take several minutes; if stuck long, contact support.

## References

- API portal: https://developers.hostinger.com
- API changelog: https://github.com/hostinger/api/blob/main/CHANGELOG.md
- Python SDK: https://github.com/hostinger/api-python-sdk
- TypeScript SDK: https://github.com/hostinger/api-typescript-sdk
- PHP SDK: https://github.com/hostinger/api-php-sdk
- CLI tool: https://github.com/hostinger/api-cli
- Terraform provider: https://github.com/hostinger/terraform-provider-hostinger
- Ansible collection: https://github.com/hostinger/ansible-collection-hostinger
- MCP server: https://github.com/hostinger/api-mcp-server
