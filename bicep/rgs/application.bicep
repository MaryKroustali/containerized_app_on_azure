//////// Application Resources ////////

targetScope = 'subscription'

param application string

var vnet_rg_name = 'rg-network-infra-${application}'
var snet_app_name = 'snet-app-vnet-${application}'
var vnet_name = 'vnet-${application}'
var common_rg_name = 'rg-common-infra-${application}'
var log_name = 'log-${application}'
var acr_url = toLower(replace(take('acr-${application}${uniqueString(rg.id)}', 20), '-', '')) // lowercase, remove hyphens, unique suffix, 20 characters long


// Existing resources from previous deployments
resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  scope: resourceGroup(vnet_rg_name)
  name: vnet_name
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
    app_snet_id: snet_app.id
    image: '${acr_url}/record-store-app:1.0.0'
    port: 8080
    log_id: log.properties.customerId
    log_key: log.listKeys().primarySharedKey
  }
}
