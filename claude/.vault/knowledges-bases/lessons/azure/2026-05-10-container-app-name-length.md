# 2026-05-10 — Azure Container App resource name exceeded 20-char limit

**Project**: ctv2026 (Davaco)
**Incident**: prod deploy of new `dashboard` app failed at terraform plan
**Workflow run**: [25616761361 / job 75196928174](https://github.com/DavacoLP/ctv2026/actions/runs/25616761361/job/75196928174) — `deploy-prod-infrastructure` step
**Fix PR**: [#113](https://github.com/DavacoLP/ctv2026/pull/113) (commit `f9c9a34`, branch `fix/dashboard-prd-name`)
**Generic knowledge**: see `../../azure/container-apps.md`

## What happened

Adding a new Angular frontend `dashboard` to the existing `deploy.yml`
pipeline. The dev side deployed cleanly (`ctv2026-dashboard`, 17 chars). The
prod side failed at `deploy-prod-infrastructure` with:

```
Error: Invalid value for variable

  on main.tf line 445, in module "dashboard_container_app":
 445:   application_name = "ctv2026-dashboard-prd"
    ├────────────────
    │ var.application_name is "ctv2026-dashboard-prd"

The application name must be 20 characters or fewer.

This was checked by the validation rule at
.terraform/modules/dashboard_container_app/modules/container-app/variables.tf:25,3-13.
```

`ctv2026-dashboard-prd` is 21 characters. The shared
`davaco-terraform-modules//modules/container-app` module rejected it.

## Why it slipped through

The dev-side resource name (`ctv2026-dashboard`, 17 chars) was within budget
and applied successfully, so a single `terraform plan` against the dev
environment would have shown a clean plan. Prod adds the `-prd` suffix, which
pushed it over the 20-char cap. We didn't run `terraform plan` against the
prod env locally before merging the CI/CD PR.

## Fix

In `infrastructure/terraform/ctv2026/envs/production/main.tf`:

```hcl
module "dashboard_container_app" {
  application_name     = "ctv2026-dash-prd"   # was ctv2026-dashboard-prd (21)
  application_dns_name = "ctv2026-dash-prd"
  container_image_name = "clearthread.azurecr.io/ctv2026-dashboard-prd"  # unchanged
  ...
}
```

In `.github/workflows/deploy.yml`, both the `build-and-push-prod-frontend`
matrix entry and the `update-prod-apps` matrix entry for `dashboard` had
their `container-name` updated to `ctv2026-dash-prd`. Their
`container-image-name` stayed `ctv2026-dashboard-prd`.

## Existing abbreviation pattern

Other prod apps in this repo already abbreviate to fit. New additions should
match:

| App | Image (ACR, descriptive) | Container App name (≤20) |
|---|---|---|
| survey-definition-service | `ctv2026-survey-definition-service` | `ctv2026-surv-def-prd` (20) |
| collection-service | `ctv2026-collection-service` | `ctv2026-collect-prd` (19) |
| masterdata-service | `ctv2026-masterdata-service` | `ctv2026-master-prd` (18) |
| notification-service | `ctv2026-notification-service` | `ctv2026-notif-prd` (17) |
| reporting-service | `ctv2026-reporting-service` | `ctv2026-report-prd` (18) |
| document-service-consumer | `ctv2026-document-service-consumer` | `ctv2026-doc-cons-prd` (20) |
| dashboard | `ctv2026-dashboard-prd` | `ctv2026-dash-prd` (16) |

Budget for new prod apps in this repo: `ctv2026-` (8) + `-prd` (4) = 12 fixed,
leaving **8 chars** for the slug.

## Detection going forward

Run a prod `terraform plan` locally before merging any PR that adds or
renames a Container App in this repo:

```bash
terraform -chdir=infrastructure/terraform/ctv2026/envs/production init
terraform -chdir=infrastructure/terraform/ctv2026/envs/production plan
```

Validation errors surface at plan time, so this catches the problem in
seconds without a CI round-trip.
