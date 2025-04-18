@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

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

resource ci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
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
