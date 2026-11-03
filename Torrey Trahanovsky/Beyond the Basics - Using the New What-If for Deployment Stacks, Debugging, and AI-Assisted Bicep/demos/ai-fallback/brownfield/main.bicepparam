// Stack settings for main.bicep, so "bicep deploy main.bicepparam" deploys it as a stack.
// The "with" block is an experimental Bicep feature (deployCommands in bicepconfig.json).
using 'main.bicep' with {
  mode: 'stack'
  name: 'stack-brownfield'
  scope: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo-nic2026-brownfield'
  actionOnUnmanage: {
    resources: 'detach'
  }
  denySettings: {
    mode: 'denyDelete'
  }
}
