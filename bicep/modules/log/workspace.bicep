@description('Resource Name.')
@minLength(4)
@maxLength(63)
param name string

@description('Name of the SKU for the Log Analytics Workspace.')
@allowed([
  'CapacityReservation'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Standalone'
])
param sku_name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('The workspace data retention in days.')
param retention_in_days int?

resource log 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  properties:{
    sku: {
      name: sku_name
    }
    retentionInDays: retention_in_days
  }
}
