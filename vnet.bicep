resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-${resourceGroup().name}'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.100.1.0/24'
        }
      }
      {
        name: 'agw'
        properties: {
          addressPrefix: '10.100.2.0/24'
        }
      }
      {
        name: 'aks'
        properties: {
          addressPrefix: '10.100.3.0/24'
        }
      }
    ]
  }
}

output id string = virtualNetwork.id
output defaultSubnetId string = virtualNetwork.properties.subnets[0].id
output applicationGatewaySubnetId string = virtualNetwork.properties.subnets[1].id
output kubernetesSubnetId string = virtualNetwork.properties.subnets[2].id
