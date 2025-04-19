@description('Principal id of the Managed Identity.')
param principalId string

@description('The role to be assigned.')
param roleDefinitionId string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  name: roleDefinitionId
}

// Owner role is required to deploy role assignments
resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = { 
  name: guid(principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinition.id
  }
}
