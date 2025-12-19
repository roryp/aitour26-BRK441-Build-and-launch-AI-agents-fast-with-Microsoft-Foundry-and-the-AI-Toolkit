// User Assigned Managed Identity for Container Apps
// Used to authenticate with Azure AI Foundry and pull images from ACR

@description('Name of the Managed Identity')
param managedIdentityName string

@description('Location for resources')
param location string

@description('Tags for resources')
param tags object = {}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output managedIdentityName string = managedIdentity.name
