---
name: convert-template-to-stack
description: Move a Bicep template that's deployed with a regular deployment (New-AzResourceGroupDeployment, az deployment group create, or a pipeline task) to an Azure deployment stack, pick the stack settings, and add a Stacks What-If check before it deploys. Use when someone asks to convert a template, deployment or pipeline to deployment stacks, or asks which actionOnUnmanage or deny settings to use.
---

# Convert a template deployment to a deployment stack

## 1. Find how it's deployed today

Look for `New-AzResourceGroupDeployment`, `az deployment group create`, `azure/arm-deploy` or
`azure/bicep-deploy` in scripts and pipelines. Note the scope, the template, the parameters file
and the identity that runs the deployment.

## 2. Check that the template fits a stack

- A stack at resource group scope deploys to its own resource group. A subscription stack can
  deploy to a resource group in the same subscription, and that's the better place for a stack
  you want to protect, because the team using the resources can't change the stack itself.
- Deny settings only cover resources the template creates through the control plane. They don't
  cover data plane items like blobs and secrets, or resources another service creates for you.
- A stack can't delete Key Vault secrets, and the Microsoft Graph extension doesn't support stacks.
- With a resource group stack, someone can still delete the whole resource group. If that
  matters, use a subscription stack that includes the resource group in the template, or add a lock.

## 3. Pick the settings

| Setting | Start with | Why |
| --- | --- | --- |
| actionOnUnmanage | `detachAll` | Removing something from the template leaves it in Azure. Move to `deleteResources` once the team trusts the template. `deleteAll` also deletes resource groups. |
| denySettingsMode | `denyDelete` | Blocks deletes outside the stack. `denyWriteAndDelete` also blocks changes, including Azure Policy remediation, so exclude the policy's identity if you use it. |
| excluded principals | the pipeline's identity, or a group | Up to five. An Entra group lets you change who's excluded without redeploying the stack. |
| applyToChildScopes | off | Turn it on only when child resources, like databases under a SQL server, need the same protection. |

The identity that deploys the stack needs the Azure Deployment Stack Owner role to set deny
settings. Azure Deployment Stack Contributor can manage the stack but not its deny settings.

## 4. Write the stack deployment

Replace the old deployment command and keep the template and parameters the same.

PowerShell:

```powershell
New-AzResourceGroupDeploymentStack -Name <stack-name> -ResourceGroupName <rg> `
  -TemplateFile main.bicep -TemplateParameterFile main.bicepparam `
  -ActionOnUnmanage DetachAll -DenySettingsMode DenyDelete `
  -DenySettingsExcludedPrincipal <group-object-id>
```

Azure CLI:

```bash
az stack group create --name <stack-name> --resource-group <rg> \
  --template-file main.bicep --parameters main.bicepparam \
  --action-on-unmanage detachAll --deny-settings-mode denyDelete \
  --deny-settings-excluded-principals <group-object-id>
```

If the team uses the Bicep deploy commands, the stack settings can live in the parameters file
instead. This is experimental, so say that, and don't suggest it for production. It needs
`"experimentalFeaturesEnabled": { "deployCommands": true }` in bicepconfig.json:

```bicep
using 'main.bicep' with {
  mode: 'stack'
  name: '<stack-name>'
  scope: '/subscriptions/<subscription-id>/resourceGroups/<rg>'
  actionOnUnmanage: {
    resources: 'detach'
  }
  denySettings: {
    mode: 'denyDelete'
    excludedPrincipals: ['<group-object-id>']
  }
}
```

Then `bicep deploy main.bicepparam` deploys the stack. `bicep what-if` doesn't support stacks
yet, so keep using Stacks What-If for the preview.

## 5. Preview before the first stack deployment

Run Stacks What-If with the new stack's resource ID. The stack doesn't need to exist yet.

```powershell
New-AzResourceGroupDeploymentStackWhatIfResult -Name convert-preview -ResourceGroupName <rg> `
  -StackResourceId /subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Resources/deploymentStacks/<stack-name> `
  -TemplateFile main.bicep -TemplateParameterFile main.bicepparam `
  -ActionOnUnmanage DetachAll -DenySettingsMode DenyDelete -RetentionInterval PT1H -Force
```

Resources the old deployment created show `Management Status: "notManaged" => "managed"`. That's
expected, because the stack takes over resources that already exist. The retention interval has
to be between PT1H and PT3H.

## 6. Add the check to the pipeline

Run Stacks What-If right before the stack deployment with the same settings, and stop if it
finds a delete or detach:

```powershell
$stack = @{
    ResourceGroupName     = '<rg>'
    TemplateFile          = 'main.bicep'
    TemplateParameterFile = 'main.bicepparam'
    ActionOnUnmanage      = 'DetachAll'
    DenySettingsMode      = 'DenyDelete'
}
$stackId = '/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Resources/deploymentStacks/<stack-name>'

$result = New-AzResourceGroupDeploymentStackWhatIfResult @stack -Name "ci-$env:BUILD_BUILDID" `
    -StackResourceId $stackId -RetentionInterval PT1H -Force
$risky = @($result.Properties.Changes.ResourceChanges | Where-Object ChangeType -in 'delete', 'detach')
if ($risky) {
    $risky | ForEach-Object { "$($_.ChangeType): $($_.Id)" }
    throw 'Stacks What-If found resources that would be deleted or detached. Review them before deploying.'
}

New-AzResourceGroupDeploymentStack @stack -Name '<stack-name>' -Force
```

## 7. Report back

Give a short table of the settings and why you picked them, the new commands, and the What-If
result. Don't deploy the stack unless someone asks you to.
