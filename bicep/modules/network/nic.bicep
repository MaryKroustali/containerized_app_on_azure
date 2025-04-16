@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Resource Id of the Network Security Group to assign to the Network Interface Card.')
param nsg_id string

@description('Resource Id of the Subnet for the Network Interface Card to get an IP.')
param snet_id string

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-${name}'
  location: location
  properties: {
    networkSecurityGroup: {
      id: nsg_id
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: snet_id
          }
        }
      }
    ]
  }
}

output id string = nic.id
