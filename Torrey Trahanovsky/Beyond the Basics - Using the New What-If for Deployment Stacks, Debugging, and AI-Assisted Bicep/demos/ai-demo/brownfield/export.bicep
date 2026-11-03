resource nsg_legacy 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: 'nsg-legacy'
  location: 'norwayeast'
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
        id: nsg_legacy_allow_https.id
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
  location: 'norwayeast'
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
        id: vnet_legacy_snet_web.id
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
  location: 'norwayeast'
  tags: {
    event: 'NIC 2026'
    purpose: 'demo'
    myTag: 'myValue'
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
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

resource nsg_legacy_allow_https 'Microsoft.Network/networkSecurityGroups/securityRules@2025-07-01' = {
  name: 'nsg-legacy/allow-https'
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
  dependsOn: [
    nsg_legacy
  ]
}

resource vnet_legacy_snet_web 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'vnet-legacy/snet-web'
  properties: {
    addressPrefix: '10.60.1.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    vnet_legacy
  ]
}

resource stlegacyann4ujmzac_default 'Microsoft.Storage/storageAccounts/blobServices@2026-04-01' = {
  parent: stlegacyann4ujmzac
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    staticWebsite: {
      enabled: false
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_stlegacyann4ujmzac_default 'Microsoft.Storage/storageAccounts/fileServices@2026-04-01' = {
  parent: stlegacyann4ujmzac
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_stlegacyann4ujmzac_default 'Microsoft.Storage/storageAccounts/queueServices@2026-04-01' = {
  parent: stlegacyann4ujmzac
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_stlegacyann4ujmzac_default 'Microsoft.Storage/storageAccounts/tableServices@2026-04-01' = {
  parent: stlegacyann4ujmzac
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

