# Azure Container Apps

Generic notes on Azure Container Apps. Project-specific incidents live under
`../lessons/azure/`.

## Naming constraints

### Container App resource name — **≤ 20 characters**

Azure caps the Container App resource name at **20 characters**. This is
distinct from:
- The **ACR image name**, which has no such 20-char limit (typical repo-name
  rules apply: lowercase, alphanumerics, hyphens/underscores/periods).
- The **DNS subdomain** the Container App exposes, which inherits from the
  resource name and is therefore also bound by the 20-char ceiling.

Treat the resource name and image name as independent: the image can stay
descriptive even when the resource name has to be abbreviated.

### Budgeting characters

When you have a fixed prefix and suffix (e.g. an org/product prefix and an
environment suffix), count them before naming a new app. The shared portion
eats from the 20-char budget and leaves a small allowance for the app slug:

```
<prefix>-<slug>-<env>
   |       |     |
   |       |     +-- e.g. "prd" (3) or "-prd" with the dash (4)
   |       +-- the only freely-named segment
   +-- shared product prefix
```

If `<prefix>` + separators + `<env>` already consume 12+ chars, the slug must
fit in 8 or fewer.

### Abbreviate consistently

Pick one abbreviation per word and reuse it across all envs/services:
`master`, `notif`, `report`, `collect`, `surv-def`, `doc-cons`, `dash`, etc.
Inconsistent abbreviations make resource lookup hard for humans and break
naïve string-match scripts.

---

## Detection

### Catch length violations at `terraform plan`, not at apply

Module authors typically enforce the 20-char cap with a Terraform
`validation` block on the `application_name` input variable. Validation
errors surface at **plan time**, so a local `terraform plan` against the
target environment catches the problem before any CI round-trip:

```bash
terraform -chdir=<env-dir> init   # once per workstation
terraform -chdir=<env-dir> plan
```

This is much faster than discovering the failure in a deployment job and is
worth doing on every PR that adds or renames a Container App.

### Static lint (optional but cheap)

A repo-level pre-commit hook or CI check can grep all `application_name = ".."`
literals in `*.tf` and reject any that exceed 20 chars. Even a single-line
shell script is enough:

```bash
grep -E 'application_name\s*=\s*"[^"]{21,}"' -r infrastructure/ && {
  echo "Container App name >20 chars"; exit 1
}
```

---

## Fix pattern when length is exceeded

The portable fix is to **abbreviate the resource name while keeping the image
name descriptive**:

1. In Terraform, set `application_name` (and `application_dns_name` if
   separate) to a ≤20-char abbreviation.
2. Leave `container_image_name` (the ACR repo path) at its original
   descriptive value — pulls and pushes don't care about the resource name.
3. In any deployment workflow that targets the Container App by resource
   name (e.g. `az containerapp update --name`), update the `container-name`
   parameter to match the new abbreviation. The `container-image-name`
   parameter does **not** need to change.

These three artifacts must agree on the **resource name**, but the
**image name** is a separate identifier and should stay stable.

---

## Lessons

- The 20-char cap is on the Container App **resource name** only. The ACR
  image name and the deployment-job's `container-image-name` parameter are
  not constrained the same way — they can keep the original descriptive
  identifier.
- Pre-prod (dev/qa) names are usually shorter than prod names because they
  lack the env suffix, so a Container App can pass plan in dev and still
  fail in prod. **Always run `terraform plan` against the prod environment
  too**, not just dev.
- Module-level `validation` blocks are the right place to enforce naming
  rules. They report at plan time and don't depend on Azure rejecting the
  resource at apply time.
- Don't try to backport a long name — abbreviate the resource and keep the
  image descriptive. The resource name is rarely user-facing; the image
  name appears in registry listings and is worth preserving.
