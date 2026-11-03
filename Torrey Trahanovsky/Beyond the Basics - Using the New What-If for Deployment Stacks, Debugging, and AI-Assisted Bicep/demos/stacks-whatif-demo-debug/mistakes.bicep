// A few common mistakes, to show what lint catches.
param location string = resourceGroup().location
param adminPassword string

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-extra'
  location: 'westeurope'
}
