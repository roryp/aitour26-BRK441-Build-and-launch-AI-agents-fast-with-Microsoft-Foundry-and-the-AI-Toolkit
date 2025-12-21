// Virtual Network for Container Apps and PostgreSQL connectivity
// Enables secure communication between Container Apps and PostgreSQL via VNet integration

@description('Name of the Virtual Network')
param vnetName string

@description('Location for resources')
param location string

@description('Tags for resources')
param tags object = {}

@description('Address prefix for the VNet')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for Container Apps subnet')
param containerAppsSubnetPrefix string = '10.0.0.0/23'

@description('Address prefix for PostgreSQL subnet')
param postgresSubnetPrefix string = '10.0.2.0/24'

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'container-apps-subnet'
        properties: {
          addressPrefix: containerAppsSubnetPrefix
          // No delegation needed - Container Apps with workload profiles
          // manages subnet directly without delegation
        }
      }
      {
        name: 'postgres-subnet'
        properties: {
          addressPrefix: postgresSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL.flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

// Private DNS Zone for PostgreSQL
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'private.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

// Link Private DNS Zone to VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output containerAppsSubnetId string = vnet.properties.subnets[0].id
output postgresSubnetId string = vnet.properties.subnets[1].id
output privateDnsZoneId string = privateDnsZone.id
