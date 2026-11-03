# Copilot chat: bringing hand-built resources under a stack

Recorded on 7 October 2026 in VS Code with GitHub Copilot in Agent mode (GPT-5.6 Sol), using the two skills in `.github/skills`. Every command needed an approval, and nothing was deployed.

---

## You

> The resources in rg-demo-nic2026-brownfield were built by hand in the portal, and nothing manages them. Bring them under a new deployment stack called stack-brownfield without changing anything. Put the template in a brownfield folder and show me the Stacks What-If before anything gets deployed.

## Copilot

*Used the skill* `migrate-resources-to-stack`

I’ll inventory the resource group and existing stacks first. If the group contains service-managed resources, secrets, or Graph objects, I’ll stop before exporting.

*Ran:* Check current Azure subscription

```powershell
az account show --query "{name:name,id:id,tenantId:tenantId}" --output json
```

```text
{
  "id": "00000000-0000-0000-0000-000000000000",
  "name": "your test subscription",
  "tenantId": "00000000-0000-0000-0000-000000000000"
}
```

*Ran:* List brownfield resources

```powershell
az resource list --resource-group rg-demo-nic2026-brownfield --output table
```

```text
Name                ResourceGroup               Location    Type                                     Status
------------------  --------------------------  ----------  ---------------------------------------  ---------
nsg-legacy          rg-demo-nic2026-brownfield  norwayeast  Microsoft.Network/networkSecurityGroups  Succeeded
vnet-legacy         rg-demo-nic2026-brownfield  norwayeast  Microsoft.Network/virtualNetworks        Succeeded
stlegacyann4ujmzac  rg-demo-nic2026-brownfield  norwayeast  Microsoft.Storage/storageAccounts        Succeeded
```

*Ran:* List existing deployment stacks

```powershell
az stack group list --resource-group rg-demo-nic2026-brownfield --output table
```

*(no output)*

The group contains only an NSG, VNet, and storage account, and no deployment stack currently manages them. I’m exporting the live configuration into the requested `brownfield` folder, then I’ll make only build/match fixes.

*Ran:* Export resource group to Bicep

```powershell
New-Item -ItemType Directory -Path .\brownfield -Force | Out-Null; az group export --name rg-demo-nic2026-brownfield --export-format bicep --skip-all-params --output tsv 1> .\brownfield\export.bicep 2> .\brownfield\export-errors.txt; $exitCode = $LASTEXITCODE; Write-Output "ExitCode=$exitCode"; if (Test-Path .\brownfield\export-errors.txt) { Get-Content .\brownfield\export-errors.txt }; exit $exitCode
```

```text
ExitCode=0
```

*Read* `brownfield/export.bicep`

*Read* `brownfield/export-errors.txt`

*Created* `brownfield/main.bicep`

The cleaned template preserves all exported resource properties while removing duplicate inline child definitions, default storage service children, and the read-only storage SKU tier. I’m validating it now; after that, I’ll run only the stack What-If.

*Ran:* Lint brownfield Bicep template

```powershell
bicep lint .\brownfield\main.bicep
```

*(no output)*

*Ran:* Run deployment stack What-If

```powershell
$subscriptionId = '00000000-0000-0000-0000-000000000000'; Set-AzContext -Subscription $subscriptionId | Out-Null; New-AzResourceGroupDeploymentStackWhatIfResult -Name stack-brownfield-preview -ResourceGroupName rg-demo-nic2026-brownfield -StackResourceId "/subscriptions/$subscriptionId/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Resources/deploymentStacks/stack-brownfield" -TemplateFile .\brownfield\main.bicep -ActionOnUnmanage DetachAll -DenySettingsMode None -RetentionInterval PT1H -Force | Out-String -Width 240 | Tee-Object -FilePath .\brownfield\what-if.txt
```

```text
Getting the latest status of all resources...
Resource Id: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Resources/deploymentStacksWhatIfResults/stack-brownfield-preview
Name: stack-brownfield-preview
Provisioning State: succeeded
Stack Resource Id: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Resources/deploymentStacks/stack-brownfield
Correlation Id: 00000000-0000-0000-0000-000000000000
Creation Time: 2026-10-08T04:29:00.9637677Z
Expiration Time: 2026-10-08T05:29:00.9637677Z

Resource and property changes are indicated with these symbols:
  + Create              ! Unsupported
  ~ Modify              - Delete
  = NoChange            v Detach

Changes to Stack /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Resources/deploymentStacks/stack-brownfield:
+ DenySettings.Mode: "None"
+ DenySettings.ApplyToChildScopes: "False"

Changes to Managed Resources:

Azure
  = /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Network/networkSecurityGroups/nsg-legacy [2025-07-01]
  ~ Management Status: "notManaged" => "managed"
  = Deny Status: "none"
  = /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Network/virtualNetworks/vnet-legacy [2025-07-01]
  ~ Management Status: "notManaged" => "managed"
  = Deny Status: "none"
  = /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield/providers/Microsoft.Storage/storageAccounts/stlegacyann4ujmzac [2026-04-01]
  ~ Management Status: "notManaged" => "managed"
  = Deny Status: "none"
```

The Stacks What-If succeeded and shows exactly the intended adoption: all three existing resources change only from `notManaged` to `managed`, with no creates, deletes, or property changes. I’m doing one final read-only check that the deployment stack itself was not created.

*Ran:* Confirm stack was not created

```powershell
az stack group list --resource-group rg-demo-nic2026-brownfield --query "[?name=='stack-brownfield'].{name:name,state:provisioningState}" --output json
```

```text
[]
```

## Brownfield migration preview ready

Created the cleaned template at [brownfield/main.bicep](../brownfield/main.bicep) and successfully linted it.

### Stacks What-If

```text
= Microsoft.Network/networkSecurityGroups/nsg-legacy
~ Management Status: "notManaged" => "managed"

= Microsoft.Network/virtualNetworks/vnet-legacy
~ Management Status: "notManaged" => "managed"

= Microsoft.Storage/storageAccounts/stlegacyann4ujmzac
~ Management Status: "notManaged" => "managed"
```

- No resources created or deleted
- No resource property changes
- All three resources will only become managed
- `ActionOnUnmanage: DetachAll`
- `DenySettingsMode: None`

Full output: [brownfield/what-if.txt](../brownfield/what-if.txt)

The `stack-brownfield` stack **was not created**. When ready, the deployment command is:

```powershell
New-AzResourceGroupDeploymentStack `
  -Name stack-brownfield `
  -ResourceGroupName rg-demo-nic2026-brownfield `
  -TemplateFile .\brownfield\main.bicep `
  -ActionOnUnmanage DetachAll `
  -DenySettingsMode None
```

---

## You

> Our pipeline in .github/workflows/deploy.yml still does a regular deployment of that template. Switch it to deploy stack-brownfield instead, and add a Stacks What-If step before the deploy that stops the run if anything would get deleted or detached.

## Copilot

*Used the skill* `convert-template-to-stack`

I’ll inspect the current workflow and preserve its authentication, scope, and template inputs while replacing only the deployment path and adding the safety gate.

*Read* `.github/workflows/deploy.yml`

*Read* `brownfield/main.bicep`

The workflow uses GitHub OIDC and deploys [brownfield/main.bicep](../brownfield/main.bicep) at resource-group scope. I’ll keep that identity and scope, use the migration-safe `DetachAll`/`None` settings, and make the What-If gate fail on any resource `delete` or `detach` before the stack deployment step can run.

*Edited* `.github/workflows/deploy.yml`

*Ran:* Lint deployment stack template

```powershell
bicep lint .\brownfield\main.bicep
```

*(no output)*

*Ran:* Validate GitHub Actions workflow

```powershell
$command = Get-Command actionlint -ErrorAction SilentlyContinue; if ($command) { actionlint .\.github\workflows\deploy.yml } else { Write-Output 'actionlint not installed'; exit 2 }
```

```text
actionlint not installed
```

The Bicep template still passes lint. `actionlint` is not installed in this workspace, so I’m switching to the available local YAML parser rather than adding tooling or dependencies.

*Ran:* Parse workflow YAML locally

```powershell
python -c "import pathlib, yaml; p=pathlib.Path(r'.github\workflows\deploy.yml'); data=yaml.safe_load(p.read_text(encoding='utf-8')); assert isinstance(data, dict) and 'jobs' in data and 'deploy' in data['jobs']; print('Workflow YAML parsed successfully')"
```

```text
Workflow YAML parsed successfully
```

*Ran:* Validate embedded PowerShell syntax

```powershell
$scriptsJson = python -c "import json, pathlib, yaml; d=yaml.safe_load(pathlib.Path(r'.github\workflows\deploy.yml').read_text(encoding='utf-8')); print(json.dumps([s['with']['inlineScript'] for s in d['jobs']['deploy']['steps'] if 'with' in s and 'inlineScript' in s['with']]))"; $scripts = $scriptsJson | ConvertFrom-Json; foreach ($script in $scripts) { $normalized = $script.Replace('${{ github.run_id }}', '1').Replace('${{ github.run_attempt }}', '1'); [void][scriptblock]::Create($normalized) }; Write-Output "Parsed $($scripts.Count) PowerShell scripts successfully"
```

```text
Parsed 2 PowerShell scripts successfully
```

Updated [.github/workflows/deploy.yml](../.github/workflows/deploy.yml).

### Pipeline behavior

1. Authenticates using the existing GitHub OIDC identity.
2. Runs Deployment Stacks What-If for `stack-brownfield`.
3. Fails the job if any resource has a `delete` or `detach` change.
4. Deploys the stack only after the safety check passes.

| Setting | Value | Reason |
|---|---|---|
| Action on unmanage | `DetachAll` | Safe initial migration; unmanaged resources remain in Azure |
| Deny settings | `None` | Avoids introducing access restrictions during adoption |
| Scope | Resource group | Preserves the existing deployment scope |
| Template | `brownfield/main.bicep` | Preserves the existing pipeline input |

Validation completed:

- Bicep lint passed
- Workflow YAML parsed successfully
- Both embedded PowerShell scripts passed syntax parsing
- No deployment or stack modification was performed during this update
