# 1. Regular What-If on the template that's deployed, with no changes.
New-AzResourceGroupDeployment -ResourceGroupName rg-demo-nic2026-stacks -TemplateFile app.v1.bicep -WhatIf
# az deployment group what-if --resource-group rg-demo-nic2026-stacks --template-file app.v1.bicep

code --diff app.v1.bicep app.v2.bicep

# 2. Regular What-If on the change.
New-AzResourceGroupDeployment -ResourceGroupName rg-demo-nic2026-stacks -TemplateFile app.v2.bicep -WhatIf
# az deployment group what-if --resource-group rg-demo-nic2026-stacks --template-file app.v2.bicep

# 3. Deploy the template that's running today, app.v1.bicep, as a stack. -Force is the only optional one.
New-AzResourceGroupDeploymentStack -Name stack-app -ResourceGroupName rg-demo-nic2026-stacks -TemplateFile app.v1.bicep -ActionOnUnmanage DetachAll -DenySettingsMode DenyDelete -Force
# az stack group create --name stack-app --resource-group rg-demo-nic2026-stacks --template-file app.v1.bicep --action-on-unmanage detachAll --deny-settings-mode denyDelete --yes

# 4. Regular What-If on the change again, now that it's a stack.
New-AzResourceGroupDeployment -ResourceGroupName rg-demo-nic2026-stacks -TemplateFile app.v2.bicep -WhatIf
# az deployment group what-if --resource-group rg-demo-nic2026-stacks --template-file app.v2.bicep

# 5. Stacks What-If on the same change. Every parameter is required except -Force.
$stackId = (Get-AzResourceGroupDeploymentStack -ResourceGroupName rg-demo-nic2026-stacks -Name stack-app).Id
# $stackId = az stack group show --name stack-app --resource-group rg-demo-nic2026-stacks --query id --output tsv
New-AzResourceGroupDeploymentStackWhatIfResult -Name whatif-sku -ResourceGroupName rg-demo-nic2026-stacks -StackResourceId $stackId -TemplateFile app.v2.bicep -ActionOnUnmanage DetachAll -DenySettingsMode DenyDelete -RetentionInterval PT1H -Force
# az stack-whatif group create --name whatif-sku --resource-group rg-demo-nic2026-stacks --stack-id $stackId --template-file app.v2.bicep --action-on-unmanage detachAll --deny-settings-mode denyDelete --retention-interval PT1H

# The next change: app.v3.bicep is app.v1.bicep, the one that's deployed, without the virtual network.
code --diff app.v1.bicep app.v3.bicep

# 6. Stacks What-If on that, with action on unmanage set to delete.
New-AzResourceGroupDeploymentStackWhatIfResult -Name whatif-delete -ResourceGroupName rg-demo-nic2026-stacks -StackResourceId $stackId -TemplateFile app.v3.bicep -ActionOnUnmanage DeleteResources -DenySettingsMode DenyDelete -RetentionInterval PT1H -Force
# az stack-whatif group create --name whatif-delete --resource-group rg-demo-nic2026-stacks --stack-id $stackId --template-file app.v3.bicep --action-on-unmanage deleteResources --deny-settings-mode denyDelete --retention-interval PT1H

# 7. Deploy it. The stack deletes the virtual network. This one takes about 3 minutes.
Set-AzResourceGroupDeploymentStack -Name stack-app -ResourceGroupName rg-demo-nic2026-stacks -TemplateFile app.v3.bicep -ActionOnUnmanage DeleteResources -DenySettingsMode DenyDelete -Force
# az stack group create --name stack-app --resource-group rg-demo-nic2026-stacks --template-file app.v3.bicep --action-on-unmanage deleteResources --deny-settings-mode denyDelete --yes

# 8. Try to delete one of the stack's resources outside of the stack.
Remove-AzResource -ResourceGroupName rg-demo-nic2026-stacks -ResourceName nsg-app -ResourceType Microsoft.Network/networkSecurityGroups -Force
# az network nsg delete --resource-group rg-demo-nic2026-stacks --name nsg-app

# 9. The What-If results are resources in Azure.
Get-AzResourceGroupDeploymentStackWhatIfResult -ResourceGroupName rg-demo-nic2026-stacks | Format-Table Name, Type
# az stack-whatif group list --resource-group rg-demo-nic2026-stacks --output table
