@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('List of security rules.')
param security_rules array


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: name
  location: location
  properties: {
    securityRules: security_rules
  }
}

output id string = nsg.id
