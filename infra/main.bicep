targetScope = 'subscription'

// ===================================================================
// Zava Cora Agent - Azure Infrastructure
// ===================================================================
// Deploys:
//   - Azure AI Foundry (existing infrastructure)
//   - Azure Container Apps (web application hosting)
//   - Azure Container Registry (container images)
//   - Azure Database for PostgreSQL Flexible Server
//   - Log Analytics Workspace (monitoring)
//   - Managed Identity (authentication)
// ===================================================================

// Parameters - General
@description('Name of the environment (used for resource naming)')
param environmentName string

@description('Primary location for all resources')
param location string

@description('Prefix for the resource group and resources')
param resourcePrefix string = 'zava-cora'

@description('Set of tags to apply to all resources')
param tags object = {}

// Parameters - AI Foundry
@description('Friendly name for your Azure AI resource')
param aiProjectFriendlyName string = 'Zava Cora Agent Project'

@description('Description of your Azure AI resource')
param aiProjectDescription string = 'Cora AI Assistant for Zava home improvement store'

@description('Array of models to deploy')
param models array = [
  {
    name: 'gpt-4o-mini'
    format: 'OpenAI'
    version: '2024-07-18'
    skuName: 'GlobalStandard'
    capacity: 10
  }
  {
    name: 'text-embedding-3-small'
    format: 'OpenAI'
    version: '1'
    skuName: 'GlobalStandard'
    capacity: 10
  }
]

// Parameters - PostgreSQL
@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

// Parameters - Container Apps
@description('Container image for the web app (set by azd deploy)')
param webAppImageName string = ''

// Variables
var abbrs = {
  containerAppsEnvironment: 'cae-'
  containerApp: 'ca-'
  containerRegistry: 'cr'
  logAnalytics: 'log-'
  managedIdentity: 'id-'
  postgresql: 'psql-'
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var resourceGroupName = 'rg-${environmentName}'

var defaultTags = union({
  'azd-env-name': environmentName
  source: 'Azure AI Foundry Agents Service'
}, tags)

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: defaultTags
}

// Resource names
var aiProjectName = 'project-${resourceToken}'
var foundryResourceName = 'foundry-${resourceToken}'
var applicationInsightsName = 'appi-${resourceToken}'
var containerAppsEnvName = '${abbrs.containerAppsEnvironment}${resourceToken}'
var containerAppName = '${abbrs.containerApp}cora-${resourceToken}'
var containerRegistryName = '${abbrs.containerRegistry}${resourceToken}'
var logAnalyticsName = '${abbrs.logAnalytics}${resourceToken}'
var managedIdentityName = '${abbrs.managedIdentity}${resourceToken}'
var postgresServerName = '${abbrs.postgresql}${resourceToken}'

// ===================================================================
// Core Infrastructure Modules
// ===================================================================

// Log Analytics Workspace
module logAnalytics 'log-analytics.bicep' = {
  name: 'log-analytics-deployment'
  scope: rg
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    tags: defaultTags
  }
}

// Managed Identity
module managedIdentity 'managed-identity.bicep' = {
  name: 'managed-identity-deployment'
  scope: rg
  params: {
    managedIdentityName: managedIdentityName
    location: location
    tags: defaultTags
  }
}

// Container Registry
module containerRegistry 'container-registry.bicep' = {
  name: 'container-registry-deployment'
  scope: rg
  params: {
    containerRegistryName: containerRegistryName
    location: location
    tags: defaultTags
    managedIdentityPrincipalId: managedIdentity.outputs.managedIdentityPrincipalId
  }
}

// ===================================================================
// Azure AI Foundry (existing infrastructure)
// ===================================================================

module applicationInsights 'application-insights.bicep' = {
  name: 'application-insights-deployment'
  scope: rg
  params: {
    applicationInsightsName: applicationInsightsName
    location: location
    tags: defaultTags
  }
}

module foundry 'foundry.bicep' = {
  name: 'foundry-account-deployment'
  scope: rg
  params: {
    aiProjectName: aiProjectName
    location: location
    tags: defaultTags
    foundryResourceName: foundryResourceName
  }
}

module foundryProject 'foundry-project.bicep' = {
  name: 'foundry-project-deployment'
  scope: rg
  params: {
    foundryResourceName: foundry.outputs.accountName
    aiProjectName: aiProjectName
    aiProjectFriendlyName: aiProjectFriendlyName
    aiProjectDescription: aiProjectDescription
    location: location
    tags: defaultTags
  }
}

@batchSize(1)
module foundryModelDeployments 'foundry-model-deployment.bicep' = [for (model, index) in models: {
  name: 'foundry-model-deployment-${model.name}-${index}'
  scope: rg
  dependsOn: [
    foundryProject
  ]
  params: {
    foundryResourceName: foundry.outputs.accountName
    modelName: model.name
    modelFormat: model.format
    modelVersion: model.version
    modelSkuName: model.skuName
    modelCapacity: model.capacity
    tags: defaultTags
  }
}]

// Grant managed identity access to AI Foundry
module aiFoundryRoleAssignment 'ai-foundry-role-assignment.bicep' = {
  name: 'ai-foundry-role-assignment'
  scope: rg
  params: {
    foundryResourceName: foundry.outputs.accountName
    principalId: managedIdentity.outputs.managedIdentityPrincipalId
  }
}

// ===================================================================
// PostgreSQL Database
// ===================================================================

module postgresql 'postgresql.bicep' = {
  name: 'postgresql-deployment'
  scope: rg
  params: {
    serverName: postgresServerName
    location: location
    tags: defaultTags
    administratorLoginPassword: postgresAdminPassword
  }
}

// ===================================================================
// Container Apps
// ===================================================================

module containerApps 'container-apps.bicep' = {
  name: 'container-apps-deployment'
  scope: rg
  params: {
    containerAppsEnvName: containerAppsEnvName
    containerAppName: containerAppName
    location: location
    tags: defaultTags
    containerImage: !empty(webAppImageName) ? '${containerRegistry.outputs.containerRegistryLoginServer}/${webAppImageName}' : 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    projectEndpoint: '${foundry.outputs.endpoint}api/projects/${foundryProject.outputs.aiProjectName}'
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    postgresConnectionString: postgresql.outputs.connectionString
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    managedIdentityClientId: managedIdentity.outputs.managedIdentityClientId
  }
}

// ===================================================================
// Outputs (used by azd)
// ===================================================================

// Azure subscription and resource group
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location

// Container Registry (for azd deploy)
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.containerRegistryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.containerRegistryName

// Container App outputs
output SERVICE_WEB_APP_NAME string = containerApps.outputs.containerAppName
output SERVICE_WEB_APP_URI string = containerApps.outputs.containerAppUrl

// AI Foundry outputs
output AZURE_AI_PROJECT_NAME string = foundryProject.outputs.aiProjectName
output PROJECT_ENDPOINT string = '${foundry.outputs.endpoint}api/projects/${foundryProject.outputs.aiProjectName}'
output GPT_MODEL_DEPLOYMENT_NAME string = models[0].name
output EMBEDDING_MODEL_DEPLOYMENT_NAME string = models[1].name

// Application Insights
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString

// PostgreSQL
output POSTGRES_SERVER_NAME string = postgresql.outputs.serverName
output POSTGRES_DATABASE_NAME string = postgresql.outputs.databaseName

// Managed Identity
output AZURE_CLIENT_ID string = managedIdentity.outputs.managedIdentityClientId
