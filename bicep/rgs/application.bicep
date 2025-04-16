//////// Application Resources ////////

targetScope = 'subscription'

param application string

var vnet_rg_name = 'rg-network-infra-${application}'
var snet_pep_name = 'snet-pep-vnet-${application}'
var snet_app_name = 'snet-app-vnet-${application}'
var vnet_name = 'vnet-${application}'
var common_rg_name = 'rg-common-infra-${application}'
var log_name = 'log-${application}'


// Existing resources from previous deployments
resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  scope: resourceGroup(vnet_rg_name)
  name: vnet_name
}

resource snet_pep 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  parent: vnet
  name: snet_pep_name
}

resource snet_app 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  parent: vnet
  name: snet_app_name
}

resource log 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  scope: resourceGroup(common_rg_name)
  name: log_name
}


resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-application-infra-${application}'
  location: 'northeurope'
}

module ci '../modules/container/instance.bicep' = {
  scope: rg
  name: 'deploy-ci-${application}'
  params: {
    name: 'ci-${application}'
    image: ''
    port: 8080
  }
}

module appi '../modules/container/insights.bicep' = {
  scope: rg
  name: 'deploy-appi-${application}'
  params: {
    name: 'appi-${application}'
    log_id: log.id
  }
}
