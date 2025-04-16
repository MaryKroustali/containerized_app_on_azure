@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('The name of the image used to create the container instance.')
param image string

@description('The exposed ports on the container instance.')
param port int

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
  }
}
