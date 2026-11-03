---
name: migrate-resources-to-stack
description: Bring existing Azure resources that no deployment stack manages (built in the portal, by scripts, or by older deployments) under a new deployment stack without changing them. Use when someone asks to migrate, adopt, import or move existing resources or a resource group into a deployment stack.
---

# Migrate existing resources to a deployment stack

The goal is a stack that manages the resources exactly as they are today. Move them in first and
clean up the template later. Stacks What-If is how you show that nothing changes.

## 1. Look at what's there

- List the resources: `az resource list --resource-group <rg> --output table`
- Check for stacks that already manage them: `az stack group list --resource-group <rg> --output table`
- Stop and ask before going further if the group has resources a stack can't manage well:
  resources another service creates for you (like the node resource group of an AKS cluster),
  Key Vault secrets, or Microsoft Graph resources.

## 2. Export the group to Bicep

Check that the Azure CLI points at the subscription with the resource group, with
`az account show --query name`, and switch with `az account set --subscription <name>` if it doesn't.

```powershell
az group export --name <rg> --export-format bicep --skip-all-params --output tsv > export.bicep
```

The export is a starting point. It often doesn't build as is.

## 3. Clean up the export

Only fix what stops it from building or from matching what's deployed. Keep every other property
and value the way the export has it, including tags that a policy added. The stack doesn't exist
yet, so it has no noise baseline, and anything you drop shows up in What-If as a change.

- Child resources that are also defined inline, like security rules in a network security group
  or subnets in a virtual network: keep the inline version, delete the separate resource, and
  delete the `id:` lines inside the inline array. These cause the BCP080 cycle errors.
- Storage `blobServices`, `fileServices`, `queueServices` and `tableServices` named `default`:
  delete them unless someone changed their settings. Azure creates them with the account.
- Read-only properties the linter flags with BCP073, like `sku.tier`: delete them.
- Resource types the export couldn't read (it prints an error for each one): leave them out and
  say so in your summary.
- A hardcoded `location`: use `param location string = resourceGroup().location` when every
  resource is in the resource group's region.
- Don't change resource names, types or API versions. A different name means a new resource,
  not a migrated one.

Save the result as `main.bicep` and run `bicep lint main.bicep` until it has no errors.

## 4. Preview the migration with Stacks What-If

Run What-If against the stack you're going to create. It doesn't need to exist yet. In PowerShell,
run `Set-AzContext -Subscription <subscription-id>` first if the current context might point
somewhere else.

```powershell
New-AzResourceGroupDeploymentStackWhatIfResult `
  -Name migrate-preview `
  -ResourceGroupName <rg> `
  -StackResourceId /subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Resources/deploymentStacks/<stack-name> `
  -TemplateFile main.bicep `
  -ActionOnUnmanage DetachAll `
  -DenySettingsMode None `
  -RetentionInterval PT1H `
  -Force
```

The retention interval has to be between PT1H and PT3H. `-Force` replaces an older result with
the same name instead of asking.

A clean migration looks like this:

- Every existing resource shows `=` with `Management Status: "notManaged" => "managed"` and
  nothing else.
- Nothing shows `+` (create). A create means the name or type doesn't match what's deployed.
- No property changes. If one shows up, put that property back the way the export had it and
  run What-If again.

## 5. Hand it back

Don't create the stack. Show the What-If result and the command to create it with the safe
settings for a first migration:

```powershell
New-AzResourceGroupDeploymentStack -Name <stack-name> -ResourceGroupName <rg> -TemplateFile main.bicep `
  -ActionOnUnmanage DetachAll -DenySettingsMode None
```

DetachAll means nothing gets deleted if something is missing from the template, and no deny
settings means nothing breaks on day one. After the first deployment, run Stacks What-If again
with the same template. It should come back as all NoChange, and from then on the stack has a
baseline, so the template can be trimmed safely. To add deny settings and set up the deployment,
use the convert-template-to-stack skill.
