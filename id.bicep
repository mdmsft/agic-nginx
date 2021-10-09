resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'id-${resourceGroup().name}'
  location: resourceGroup().location
}

output id string = userAssignedIdentity.id
output principalId string = userAssignedIdentity.properties.principalId
