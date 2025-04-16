@description('Resource Name.')
@minLength(1)
@maxLength(15)
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('''Specifies the name of the administrator account of the Windows Virtual Machine.

Disallowed values: "administrator", "admin", "user", "user1", "test", "user2", "test1", "user3", "admin1", "1", "123", "a", "actuser", "adm", "admin2", "aspnet", "backup", "console", "david", "guest", "john", "owner", "root", "server", "sql", "support", "support_388945a0", "sys", "test2", "test3", "user4", "user5".

Cannot end in "."

This property cannot be updated after the VM is created.
''')
@maxLength(20)
param admin_username string

@description('''Specifies the password of the administrator account of the Windows Virtual Machine.

Complexity requirements: 3 out of 4 conditions below need to be fulfilled:
- Has lower characters
- Has upper characters
- Has a digit
- Has a special character (Regex match [\W_])

Disallowed values: "abc@123", "P@$$w0rd", "P@ssw0rd", "P@ssword123", "Pa$$word", "pass@word1", "Password!", "Password1", "Password22", "iloveyou!"

''')
@secure()
@minLength(8)
param admin_password string

@description('''Specifies the size of the virtual machine. The recommended way to get the list of available sizes is using these APIs: 
- https://learn.microsoft.com/en-us/rest/api/compute/availabilitysets/listavailablesizes
- https://learn.microsoft.com/en-us/rest/api/compute/resourceskus/list
- https://learn.microsoft.com/en-us/rest/api/compute/virtualmachines/listavailablesizes
''')
@allowed([
  'Standard_B1ms'
  'Standard_B1s'
  'Standard_B2ms'
  'Standard_B2s'
  'Standard_B4ms'
  'Standard_B8ms'
])
param vm_size string

@description('Publisher of the VM Image.')
param image_publisher string

@description('Offer of the VM Image.')
param image_offer string

@description('SKU of thr VM Image.')
param image_sku string

@description('Name of the Resource Group containing all network resources.')
param vnet_rg_name string

@description('Resource Id of the Subnet for the Network Interface Card to get an IP.')
param snet_id string

@description('GitHub Personal Access Token to register Virtual Machine to Github Runners.')
param github_pat string

// Network Security Group
module nsg '../network/nsg.bicep' = {
  scope: resourceGroup(vnet_rg_name)  // Deploy in Network RG
  name: 'deploy-nsg-${name}'
  params: {
    name: 'nsg-${name}'
    security_rules: [
      {
        name: 'Allow-RDP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          destinationPortRange: '3389'  // Allow incoming traffic in 3389 (RDP) for Bastion Host
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Network Interface Card for the Virtual Machine
module nic '../network/nic.bicep' = {
  scope: resourceGroup(vnet_rg_name) // Deploy in Network RG
  name: 'deploy-nic-${name}'
  params: {
    name: 'nic-${name}'
    nsg_id: nsg.outputs.id
    snet_id: snet_id
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vm_size
    }
    osProfile: {
      computerName: name
      adminUsername: admin_username
      adminPassword: admin_password
      windowsConfiguration: {
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            bypassPlatformSafetyChecksOnUserSchedule: true
          }
          assessmentMode: 'AutomaticByPlatform'
        }
      }
    }
    storageProfile: {
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: image_publisher
        offer: image_offer
        sku: image_sku
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.outputs.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

// Configures Virtual Machine as a GitHub Runner to run workflows on private resources
resource ext 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'AzureDevopsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [ 'https://raw.githubusercontent.com/MaryKroustali/private_app_on_azure/main/scripts/buildagent.ps1' ]  // script configuring the runner
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File buildagent.ps1 -token ${github_pat}'  // run the script upon initializing the Virtual Machine
    }
  }
}
