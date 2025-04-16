@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Required. SKU name to specify whether the key vault is a standard vault or a premium vault.')
@allowed([
  'premium'
  'standard'
])
param sku_name string

@description('Id of the private endpoints\' subnet.')
param pep_snet_id string

@description('Name of the Network Resources\' Resource Group.')
param vnet_rg_name string

@description('Property to specify whether the vault will accept traffic from public internet. If set to \'disabled\' all traffic except private endpoint traffic and that that originates from trusted services will be blocked. This will override the set firewall rules, meaning that even if the firewall rules are present we will not honor the rules.')
@allowed([
  'Disabled'
  'Enabled'
])
param public_network_access string

@description('''
Property specifying whether protection against purge is enabled for this vault. Setting this property to `true` activates protection against purge for this vault and its content - only the Key Vault service may initiate a hard, irrecoverable deletion. 
**The setting is effective only if soft delete is also enabled**. 

Enabling this functionality is irreversible - that is, the property does not accept false as its value.
''')
param purge_protection bool = true

@description('Property to specify whether the `soft delete` functionality is enabled for this key vault. Default value is set to `true`. Once set to `true`, it cannot be reverted to `false`.')
param soft_delete bool = false

@description('''
Property that controls how data actions are authorized. 

When `true`, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the `accessPolicies` specified in vault properties will be ignored. When `false`, the key vault will use the `accessPolicies` specified in vault properties, and any policy stored on Azure Resource Manager will be ignored. If null or not specified, the vault is created with the default value of `false`. Note that management actions are always authorized with RBAC.
''')
param rbac_authorization bool = true

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param template_deployment bool = true


var dns_zone = 'privatelink.vaultcore.azure.net'  // Private DNS zone for key vault

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: sku_name
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: template_deployment
    enableRbacAuthorization: rbac_authorization
    enableSoftDelete: soft_delete
    enablePurgeProtection: purge_protection
    publicNetworkAccess: public_network_access
  }
}

// A private endpoint is used to enable private access to the key vault
module pep '../network/pep.bicep' = {
  scope: resourceGroup(vnet_rg_name)
  name: 'deploy-pep-${name}'
  params: {
    name: 'pep-${name}'
    group_ids: [ 'vault' ]
    resource_id: kv.id  // Connect this private endpoint to the key vault
    snet_id: pep_snet_id
    dns_zone: dns_zone
  }
}

output name string = kv.name
