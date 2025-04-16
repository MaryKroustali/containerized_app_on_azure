///////// Network Resources ////////

targetScope = 'subscription'

param application string

var dns_zones = [  // Names of the private Azure DNS zones needed for private networking https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns 
  #disable-next-line no-hardcoded-env-urls
  'privatelink.database.windows.net'  // zone for sql servers
  'privatelink.vaultcore.azure.net' // zone for key vault
  'privatelink.azurecr.io' // zone for container registry
]


resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-network-infra-${application}'
  location: 'northeurope'
}

module vnet '../modules/network/vnet.bicep' = { // Private Virtual Network
  scope: rg
  name: 'deploy-vnet-${application}'
  params: {
    address_prefixes: ['10.1.0.0/26']
    name: 'vnet-${application}'
    subnets: [
      { // Subnet for container instances, must be delegated for 'Microsoft.ContainerInstance/containerGroups'
        // https://learn.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview
        name: 'snet-app-vnet-${application}'
        properties: {
          addressPrefix: '10.1.0.0/28'
          delegations: [
            {
              name: 'Microsoft.ContainerInstance/containerGroups'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      { // Subnet for private endpoints of the resources
        name: 'snet-pep-vnet-${application}'
        properties: {
          addressPrefix: '10.1.0.16/28'
        }
      }
      { // Subnet for Bastion Host
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.0.32/27'
        }
      }
    ]
  }
}

module dns '../modules/network/dns.bicep' = [ for name in dns_zones: {
  scope: rg
  name: 'deploy-${name}'
  params: {
    name: name
    vnet_id: vnet.outputs.id
  }
} ]

// Resource to access private resources using a public IP safely
module bastion '../modules/network/bastion.bicep' = {
  scope: rg
  name: 'deploy-bastion-${application}'
  params: {
    name: 'bastion-${application}'
    sku_name: 'Basic'
    snet_id: vnet.outputs.bastion_snet_id
  }
}
