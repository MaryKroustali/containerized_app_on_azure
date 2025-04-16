@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Address space for this virtual network.')
param address_prefixes array

@description('Array of subnets.')
param subnets subnet

// Custom data type for object of type subnet
type subnet = {
  name: string
  properties: {
    addressPrefix: string
    delegations: [
      {
        name: string
        properties: {
          serviceName: string
        }
      }
    ]?
  }
}[]

resource virtual_network 'Microsoft.Network/virtualNetworks@2024-03-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: address_prefixes
    }
    subnets: subnets
  }
}

// Export array of subnets in main.bicep
output app_snet_id string = virtual_network.properties.subnets[0].id
output pep_snet_id string = virtual_network.properties.subnets[1].id
output bastion_snet_id string = virtual_network.properties.subnets[2].id
output id string = virtual_network.id
