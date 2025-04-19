@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Name of the resource group containing the Azure Container Registry.')
param acr_rg_name string

@description('The name of the image used to create the container instance.')
param image string

@description('The exposed ports on the container instance.')
param port int

@description('Id of the delegated subnet of type \'Microsoft.ContainerInstance/containerGroups\'')
param app_snet_id string

@description('Id of the log analytics workspace for container insights.')
param log_id string

@description('Key of the log analytics workspace for container insights.')
@secure()
param log_key string

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  scope: resourceGroup(acr_rg_name)
  name: split(image, '.azurecr.io')[0]  // get acr name
}

// A resource needs to have an identity in order to be assigned permissions
resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-${name}'
  location: location
}

// Assign AcrPull permission to container instance
module rbac './authorization.bicep' = {
  name: 'deploy-id-${name}-AcrPull'
  scope: resourceGroup(acr_rg_name)
  params: {
    principalId: id.properties.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
  }
}

resource ci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${id.id}': {}  // attach identity to container instance
    }
  }
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 4
            }
          }
        }
      }
    ]
    imageRegistryCredentials: [ // authenticating to ACR using the identity permissions
      {
        server: acr.properties.loginServer
        identity: id.id
      }
    ]
    osType: 'Linux' // APS.NET Core apps use Linux containers
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Private' // Disable public access to the container
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
    }
    subnetIds: [
      {
        id: app_snet_id // Integrate with private network
      }
    ]
    diagnostics: {
      logAnalytics: {
        logType: 'ContainerInstanceLogs'
        workspaceId: log_id
        workspaceKey: log_key
      }
    }
  }
}
