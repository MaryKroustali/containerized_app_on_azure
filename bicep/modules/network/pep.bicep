@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Id of the subnet from where private endpoints get their private addresses.')
param snet_id string

@description('The remote resource Id to connect the private endpoint to.')
param resource_id string

@description('Id of the group obtained from the remote resource that this private endpoint should connect to.')
param group_ids array

@description('Private DNS zone to connect the private endpoint to.')
param dns_zone string

resource pep 'Microsoft.Network/privateEndpoints@2024-01-01' = {
  name: name
  location: location
  properties: {
    subnet: { 
      id: snet_id
    }
    privateLinkServiceConnections: [
      {
        name: 'pse-${name}'
        properties: {
          privateLinkServiceId: resource_id  // The resource to connect the private endpoint to
          groupIds: group_ids  // List of available group Ids per resource type https://blog.blksthl.com/2023/03/22/the-complete-list-of-groupids-for-private-endpoint-privatelink-service-connection/
        }
      }
    ]
  }
}

resource dns 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: dns_zone
}

// Resource that connects parent private endpoint with the corresponding private DNS zone 
resource dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-03-01' = {
  parent: pep
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      { 
        name: 'default-config'
        properties: { 
          privateDnsZoneId: dns.id
        }
      }
    ]
  }
}
