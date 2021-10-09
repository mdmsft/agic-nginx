param dnsZoneId string
param keyVaultSecretId string
param keyVaultResourceGroupName string
param aliases array = []

var dnsZoneComponents = split(dnsZoneId, '/')

var keyVaultComponents = split(substring(keyVaultSecretId, 8), '.')

module managedIdentity 'id.bicep' = {
  name: '${deployment().name}-id'
}

module kv 'kv.rbac.bicep' = {
  name: '${deployment().name}-kv'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultComponents[0]
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
  }
}

module vnet 'vnet.bicep' = {
  name: '${deployment().name}-vnet'
}

module log 'log.bicep' = {
  name: '${deployment().name}-log'
}

module applicationGateway 'agw.bicep' = {
  name: '${deployment().name}-agw'
  dependsOn: [
    kv
  ]
  params: {
    managedIdentityId: managedIdentity.outputs.id
    managedPrincipalId: managedIdentity.outputs.principalId
    keyVaultSecretId: keyVaultSecretId
    subnetId: vnet.outputs.applicationGatewaySubnetId
  }
}

module aks 'aks.bicep' = {
  name: '${deployment().name}-aks'
  params: {
    subnetId: vnet.outputs.kubernetesSubnetId
    applicationGatewayId: applicationGateway.outputs.id
    logAnalyticsWorkspaceId: log.outputs.id
  }
}

module rbac 'rbac.bicep' = {
  name: '${deployment().name}-rbac'
  params: {
    applicationGatewayId: applicationGateway.outputs.id
    clusterName: aks.outputs.name
    managedIdentityId: managedIdentity.outputs.id
    nodeResourceGroupName: aks.outputs.nodeResourceGroupName
  }
}

module dns 'dns.bicep' = {
  name: '${deployment().name}-dns'
  scope: resourceGroup(dnsZoneComponents[4])
  params: {
    dnsZoneName: last(dnsZoneComponents)
    publicIpAddress: applicationGateway.outputs.ip
    name: resourceGroup().name
    aliases: aliases
  }
}

output sslCertificateName string = applicationGateway.outputs.sslCertificateName
output clusterName string = aks.outputs.name
