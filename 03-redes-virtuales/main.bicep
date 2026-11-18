// Lab 03 - Hub-and-spoke: dos redes virtuales emparejadas
param location string = resourceGroup().location

// Red central (hub): solo la subred del firewall
resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'hub-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/26'
        }
      }
    ]
  }
}

// Red de la aplicación (spoke): front-end y back-end
resource appVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'app-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'frontend'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: 'backend'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

// Peering app -> hub (vive en app-vnet)
resource appToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: appVnet
  name: 'app-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

// Peering hub -> app (vive en hub-vnet)
resource hubToApp 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hubVnet
  name: 'hub-to-app'
  properties: {
    remoteVirtualNetwork: {
      id: appVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

output appVnetId string = appVnet.id
output hubVnetId string = hubVnet.id
