param subnetId string
param applicationGatewayId string
param logAnalyticsWorkspaceId string

var segments = split(subnetId, '/')

var name = 'aks-${resourceGroup().name}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: segments[8]
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: last(segments)
  parent: vnet
}

resource agw 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
  name: last(split(applicationGatewayId, '/'))
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: name
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.21.2'
    dnsPrefix: name
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'sys'
        count: 1
        minCount: 1
        maxCount: 3
        enableAutoScaling: true
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: subnetId
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'usr'
        count: 1
        minCount: 1
        maxCount: 3
        enableAutoScaling: true
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'User'
        vnetSubnetID: subnetId
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
    }
    addonProfiles: {
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGatewayId
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
  }
}

var networkContributorRoleId = '4d97b98b-1d4f-4787-a291-c67834d212e7'

resource rbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().subscriptionId, subscription().tenantId, guid(aksCluster.id), networkContributorRoleId)
  scope: subnet
  properties: {
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', networkContributorRoleId)
  }
}

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(subscription().subscriptionId, subscription().tenantId, aksCluster.id, contributorRoleId)
  scope: agw
  properties: {
    principalId: aksCluster.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
  }
}

output name string = aksCluster.name
output nodeResourceGroupName string = aksCluster.properties.nodeResourceGroup
