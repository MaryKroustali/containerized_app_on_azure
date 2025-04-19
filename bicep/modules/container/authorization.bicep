@description('Principal id of the Managed Identity.')
param principalId string

@description('The role to be assigned.')
param role string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  name: role
}

// Owner role is required to deploy role assignments
resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinition.id)
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinition.id
    principalType: 'ServicePrincipal'
  }
}
