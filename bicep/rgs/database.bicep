//////// Database Resources ////////

targetScope = 'subscription'

param application string

param sql_db_name string

var vnet_rg_name = 'rg-network-infra-${application}'
var snet_pep_name = 'snet-pep-vnet-${application}'
var vnet_name = 'vnet-${application}'
var kv_rg_name = 'rg-common-infra-${application}'
var kv_name = 'kv-${application}'
var sql_username_kv_secret = 'sql-server-admin-username'
var sql_password_kv_secret = 'sql-server-admin-password'

// Existing resources from previous deployments
resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  scope: resourceGroup(vnet_rg_name)
  name: vnet_name
}

resource snet_pep 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  parent: vnet
  name: snet_pep_name
}

resource kv_rg 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: kv_rg_name
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  scope: kv_rg
  name: kv_name
}


resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-database-infra-${application}'
  location: 'northeurope'
}

module sql_server '../modules/sql/server.bicep' = {
  scope: rg
  name: 'deploy-sql-${application}'
  params: {
    admin_password: kv.getSecret(sql_password_kv_secret)  // get password from Key Vault
    admin_username: kv.getSecret(sql_username_kv_secret)  // get useraname from Key Vault
    name: 'sql-${application}'
    pep_snet_id: snet_pep.id
    vnet_rg_name: vnet_rg_name
  }
}

module sql_db '../modules/sql/database.bicep' = {
  scope: rg
  name: 'deploy-sql-db-${application}'
  params: {
    name: sql_db_name
    server_name: sql_server.outputs.name
  }
}
