@description('Resource name (globally unique & lowercase).')
param name string

@description('Resource location')
param location string = resourceGroup().location

@description('SKU of the Container Registry.')
@allowed([
  'Basic'
  'Classic'
  'Premium'
  'Standard'
])
param sku string

@description('Property to specify whether the vault will accept traffic from public internet. If set to \'disabled\' all traffic except private endpoint traffic and that that originates from trusted services will be blocked. This will override the set firewall rules, meaning that even if the firewall rules are present we will not honor the rules.')
@allowed([
  'Disabled'
  'Enabled'
])
param public_network_access string

@description('Id of the private endpoints\' subnet.')
param pep_snet_id string

@description('Name of the Network Resources\' Resource Group.')
param vnet_rg_name string


var dns_zone = 'privatelink.azurecr.io'  // Private DNS zone for container registry

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: toLower(replace(take('${name}${uniqueString(resourceGroup().id)}', 20), '-', '')) // lowercase, remove hyphens, unique suffix, 20 characters long
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: public_network_access
  }
}

// A private endpoint is used to enable private access to the registry
module pep '../network/pep.bicep' = {
  scope: resourceGroup(vnet_rg_name)
  name: 'deploy-pep-${name}'
  params: {
    name: 'pep-${name}'
    group_ids: [ 'registry' ]
    resource_id: acr.id  // Connect this private endpoint to the key vault
    snet_id: pep_snet_id
    dns_zone: dns_zone
  }
}
