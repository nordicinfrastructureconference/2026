param location string = resourceGroup().location

resource nsg_legacy 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: 'nsg-legacy'
  location: location
  tags: {
    event: 'NIC 2026'
    purpose: 'demo'
    myTag: 'myValue'
  }
  properties: {
    flushConnection: false
    securityRules: [
      {
        name: 'allow-https'
        properties: {
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource vnet_legacy 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: 'vnet-legacy'
  location: location
  tags: {
    event: 'NIC 2026'
    purpose: 'demo'
    myTag: 'myValue'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.60.0.0/16'
      ]
    }
    privateEndpointVNetPolicies: 'Disabled'
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: '10.60.1.0/24'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource stlegacyann4ujmzac 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: 'stlegacyann4ujmzac'
  location: location
  tags: {
    event: 'NIC 2026'
    purpose: 'demo'
    myTag: 'myValue'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    networkAcls: {
      ipv6Rules: []
      bypass: 'None'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}
