// The same app after a refactor: the storage account moved into a module.
targetScope = 'resourceGroup'

param location string = resourceGroup().location

var tags = { purpose: 'demo', event: 'NIC 2026' }

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-app'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: ['10.40.0.0/16'] }
    subnets: [
      {
        name: 'snet-app'
        properties: { addressPrefix: '10.40.1.0/24', defaultOutboundAccess: false }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-app'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'allow-https'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    tags: tags
  }
}