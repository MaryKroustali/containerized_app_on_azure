@description('Name of the Secret.')
param name string

@description('Value of the Secret.')
@secure()
param value string

@description('Name of the Key Vault to add the secret to.')
param kv_name string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kv_name
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: name
  properties: {
    value: value
  }
}
