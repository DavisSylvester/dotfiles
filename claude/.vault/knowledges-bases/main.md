# Knowledge Bases

Generic, reusable engineering lessons (project-agnostic). Project-specific incidents live
under `lessons/`.

## Topics

- `azure/` — Azure notes (e.g. Container Apps naming constraints).
- `ci-cd/` — CI/CD + infrastructure-as-code lessons.
  - `ci-cd/deploy-env-vars-silent-empty.md` — backend 401s / misbehaves after a deploy
    because IaC baked a required env var as an empty string; how to diagnose + fix anywhere.
- `hostinger/` — Hostinger API reference (https://developers.hostinger.com). Per-area
  files (billing, dns, domains, ecommerce, horizons, hosting, reach, vps) covering ~114
  endpoints, auth, curl/SDK patterns. Start at `hostinger/main.md`.

## Azure Container Apps

Contains fixes for common errors when creating a Container Apps in Azure

