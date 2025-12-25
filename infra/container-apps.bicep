// Container Apps Environment for hosting the Cora web application
// This module creates the Azure Container Apps infrastructure

@description('Name of the Container Apps Environment')
param containerAppsEnvName string

@description('Name of the Container App')
param containerAppName string

@description('Location for resources')
param location string

@description('Tags for resources')
param tags object = {}

@description('Container image to deploy')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Azure AI Foundry Project Endpoint')
param projectEndpoint string

@description('GPT Model Deployment Name')
param gptModelDeploymentName string = 'gpt-4o-mini'

@description('Embedding Model Deployment Name')
param embeddingModelDeploymentName string = 'text-embedding-3-small'

@description('Application Insights Connection String')
param applicationInsightsConnectionString string = ''

@description('PostgreSQL connection string')
param postgresConnectionString string = ''

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Azure Container Registry name')
param containerRegistryName string

@description('User Assigned Managed Identity ID')
param managedIdentityId string

@description('User Assigned Managed Identity Client ID')
param managedIdentityClientId string

@description('Subnet ID for VNet integration (optional)')
param subnetId string = ''

// Reference the existing container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

// Container Apps Environment (Consumption plan - no VNet integration)
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

// Cora Web App Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: union(tags, { 'azd-service-name': 'web-app' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'OPTIONS']
          allowedHeaders: ['*']
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'cora-web-app'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'PROJECT_ENDPOINT'
              value: projectEndpoint
            }
            {
              name: 'GPT_MODEL_DEPLOYMENT_NAME'
              value: gptModelDeploymentName
            }
            {
              name: 'EMBEDDING_MODEL_DEPLOYMENT_NAME'
              value: embeddingModelDeploymentName
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsightsConnectionString
            }
            {
              name: 'AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED'
              value: 'true'
            }
            {
              name: 'POSTGRES_URL'
              value: postgresConnectionString
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: managedIdentityClientId
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8000
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: 8000
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output containerAppsEnvironmentId string = containerAppsEnvironment.id
output containerAppName string = containerApp.name
