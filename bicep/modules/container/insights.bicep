@description('Resource Name.')
param name string

@description('Id of the Log Analytics Workspace.')
param log_id string

@description('Resource Location.')
param location string = resourceGroup().location

@description('The kind of application that this component refers to. Typically should be one of the following: web, ios, other, store, java, phone.')
param kind string = 'web'

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: kind
  properties: {
    Application_Type: kind
    WorkspaceResourceId: log_id
  }
}

output instrumentation_key string = appi.properties.InstrumentationKey
output connection_string string = appi.properties.ConnectionString
