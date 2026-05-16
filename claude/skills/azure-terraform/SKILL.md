Fix common Azure Terraform errors by applying known patterns.

Run this skill when a `terraform plan` or `terraform apply` fails. Pass the error message as the argument.

## Arguments

- `$ARGUMENTS` — the Terraform error output (paste the full error message)

## Known Error Patterns

### Pattern 1: Resource already exists — needs import

**Error signature:** `A resource with the ID "..." already exists - to be managed via Terraform this resource needs to be imported into the State`

**Root cause:** Terraform is trying to create a resource that already exists in Azure but isn't tracked in Terraform state.

**Fix — convert to data block:**

1. Identify the resource type and name from the error (e.g. `azurerm_subnet.container_app_subnet`)
2. Find the `.tf` file containing the `resource` block
3. Convert the `resource` block to a `data` block:
   - Change `resource` to `data`
   - Remove any write-only attributes (e.g. `delegation`, `address_prefixes` for subnets)
   - Keep only the lookup attributes (`name`, `resource_group_name`, `virtual_network_name`, etc.)
4. Update ALL references across the module from `azurerm_<type>.<name>` to `data.azurerm_<type>.<name>`
   - Search in: `*.tf` files in the same module directory
   - Common locations: other resources referencing `.id`, output blocks, depends_on
5. Remove any variables that were only used by the resource block (e.g. `subnet_address_prefixes`)
6. Remove the variable from the calling module in the consumer project's `main.tf`

**Example — subnet:**
```hcl
# BEFORE (resource — causes "already exists" error)
resource "azurerm_subnet" "container_app_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
  delegation { ... }
}

# AFTER (data block — reads existing resource)
data "azurerm_subnet" "container_app_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}
```

Then update all references:
- `azurerm_subnet.container_app_subnet.id` → `data.azurerm_subnet.container_app_subnet.id`

### Pattern 2: Subnet delegation missing

**Error signature:** `ManagedEnvironmentSubnetDelegationError: The subnet of the environment must be delegated to the service 'Microsoft.App/environments'`

**Root cause:** The subnet exists but doesn't have the required service delegation.

**Fix:** This cannot be fixed with a data block alone. Options:
1. **Manual fix:** Run `az network vnet subnet update` to add delegation:
   ```bash
   az network vnet subnet update \
     --resource-group <RG> \
     --vnet-name <VNET> \
     --name <SUBNET> \
     --delegations Microsoft.App/environments
   ```
2. **Terraform fix:** Use `azurerm_subnet` as a `resource` (not data) and import it:
   ```bash
   terraform import 'module.<name>.azurerm_subnet.<name>' <subnet-resource-id>
   ```
   Then add the delegation block to the resource.

**Recommendation:** If the subnet is shared with other services, use option 1 (manual az CLI). If dedicated to Container Apps, use option 2 (Terraform manages it).

### Pattern 3: Role assignment already exists

**Error signature:** `A role assignment with the same principal and role already exists`

**Fix:** Import the existing role assignment or add `ignore_changes` lifecycle:
```hcl
resource "azurerm_role_assignment" "example" {
  # ... existing config ...
  lifecycle {
    ignore_changes = all
  }
}
```

## Execution Steps

1. Parse the error message from `$ARGUMENTS`
2. Match against known patterns above
3. Identify the affected files (module path from error)
4. Read the affected `.tf` files
5. Apply the fix
6. Search for and update all references in the module
7. Update the calling module's `main.tf` and `variables.tf` if variables were removed
8. Report what was changed

### Pattern 4: Self-hosted runner uses stale module cache

**Error signature:** Same error reappears after fix was pushed — typically delegation or resource errors that were already fixed in the module source.

**Root cause:** Self-hosted GitHub Actions runners persist `.terraform/modules/` between runs. Even with `terraform init -upgrade`, the cached module may not refresh if the git ref hasn't changed.

**Fix:** Add a cache-cleaning step before `terraform init` in the GitHub Actions workflow:
```yaml
- name: Clean Terraform module cache
  run: |
    cd ${{ env.TERRAFORM_DIR }}
    rm -rf .terraform/modules/
```

## After Fixing

Remind the user to:
1. Clean `.terraform/modules/` on self-hosted runners if module source was updated
2. Re-run `terraform init -upgrade` (if module source changed)
3. Re-run `terraform plan` to verify the fix
4. Commit and push the changes
