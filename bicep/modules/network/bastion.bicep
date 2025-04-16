@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('SKU of the Bastion Host.')
@allowed([
  'Basic'
  'Developer'
  'Standard'
])
param sku_name string

@description('Resource ID of the subnet where the bastion needs to be created.')
param snet_id string

@description('Private IP allocation method.')
@allowed([
  'Dynamic'
  'Static'
])
param private_ip_allocation string = 'Dynamic'


// Pubic Ip
resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = { 
  name: 'pip-${name}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: { 
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = { 
  name: name
  location: location
  sku: {
    name: sku_name
  }
  properties: { 
    ipConfigurations: [
      {
        name: 'ip-config'
        properties: { 
          privateIPAllocationMethod: private_ip_allocation
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: snet_id
          }
        }
      }
    ]
  }
}
