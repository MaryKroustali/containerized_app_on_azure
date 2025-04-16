@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Name of the associated SQL Server.')
param server_name string

resource sql_server 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: server_name
}

resource sqql_database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sql_server
  name: name
  location: location
}
