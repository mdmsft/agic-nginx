param managedIdentityId string
param clusterName string
param nodeResourceGroupName string
param applicationGatewayId string

var managedIdentityOperator = 'f1a07417-d97a-45cb-824c-7a7467783830'
var reader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource applicationGatewayIdentityId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'ingressapplicationgateway-${clusterName}'
  scope: resourceGroup(nodeResourceGroupName)
}

resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: last(split(managedIdentityId, '/'))
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
  name: last(split(applicationGatewayId, '/'))
}

resource rbacManagedIdentityOperator 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(applicationGatewayIdentityId.id, managedIdentityOperator)
  scope: id
  properties: {
    principalId: applicationGatewayIdentityId.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', managedIdentityOperator)
  }
}

resource rbacReader 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(applicationGatewayIdentityId.id, reader)
  properties: {
    principalId: applicationGatewayIdentityId.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', reader)
  }
}

resource rbacContributor 'Microsoft.Authorization/roleAssignments@2018-01-01-preview' = {
  name: guid(applicationGatewayIdentityId.id, contributor)
  scope: applicationGateway
  properties: {
    principalId: applicationGatewayIdentityId.properties.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributor)
  }
}
