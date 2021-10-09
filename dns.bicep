param publicIpAddress string
param dnsZoneName string
param name string
param aliases array

resource dns 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName
}

resource a 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: name
  parent: dns
  properties: {
    ARecords: [
      {
        ipv4Address: publicIpAddress
      }
    ]
    TTL: 3600
  }
}

resource _ 'Microsoft.Network/dnsZones/A@2018-05-01' = [for alias in aliases: {
  name: alias
  parent: dns
  properties: {
    TTL: 3600
    targetResource: {
      id: a.id
    }
  }
}]
