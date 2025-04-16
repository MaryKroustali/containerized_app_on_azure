//////// Common Resources ////////

targetScope = 'subscription'

param application string
param sql_server_admin_username string
@secure()
param sql_server_admin_password string
param vm_admin_username string
@secure()
param vm_admin_password string
param github_pat string

var vnet_rg_name = 'rg-network-infra-${application}'
var snet_pep_name = 'snet-pep-vnet-${application}'
var vnet_name = 'vnet-${application}'


// Existing network resources from previous deployments
resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  scope: resourceGroup(vnet_rg_name)
  name: vnet_name
}

resource snet_pep 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  parent: vnet
  name: snet_pep_name
}


resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-common-infra-${application}'
  location: 'northeurope'
}

module kv '../modules/keyvault/vault.bicep' = {
  scope: rg
  name: 'deploy-kv-${application}'
  params: {
    name: 'kv-${application}'
    vnet_rg_name: vnet_rg_name
    pep_snet_id: snet_pep.id
    public_network_access: 'Disabled'
    sku_name: 'premium'
  }
}

// Add SQL server credentials to key vault
module sql_username '../modules/keyvault/secret.bicep' = {
  scope: rg
  name: 'deploy-secret-sql-username'
  params: {
    name: 'sql-server-admin-username'
    kv_name: kv.outputs.name
    value: sql_server_admin_username
  }
}

module sql_password '../modules/keyvault/secret.bicep' = {
  scope: rg
  name: 'deploy-secret-sql-password'
  params: {
    name: 'sql-server-admin-password'
    kv_name: kv.outputs.name
    value: sql_server_admin_password
  }
}

// Add VM credentials to key vault
module vm_username '../modules/keyvault/secret.bicep' = {
  scope: rg
  name: 'deploy-secret-vm-username'
  params: {
    name: 'vm-admin-username'
    kv_name: kv.outputs.name
    value: vm_admin_username
  }
}

module vm_password '../modules/keyvault/secret.bicep' = {
  scope: rg
  name: 'deploy-secret-vm-password'
  params: {
    name: 'vm-admin-password'
    kv_name: kv.outputs.name
    value: vm_admin_password
  }
}

module log '../modules/log/workspace.bicep' = {
  scope: rg
  name: 'deploy-log-${application}'
  params: {
    name: 'log-${application}'
    sku_name: 'Standalone'
  }
}

module vm '../modules/vm/windows.bicep' = {
  scope: rg
  name: 'deploy-vm-${application}'
  params: {
    name: 'vm-${application}'
    admin_password: vm_admin_password
    admin_username: vm_admin_username
    image_offer: 'WindowsServer'
    image_publisher: 'MicrosoftWindowsServer'
    image_sku: '2022-Datacenter'
    snet_id: snet_pep.id
    vm_size: 'Standard_B1ms'
    vnet_rg_name: vnet_rg_name
    github_pat: github_pat
  }
}
