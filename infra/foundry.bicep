// ai-services.bicep
// This file contains the AI services resources for the agent workshop

// Parameters
@description('Name for the project')
param aiProjectName string

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Location for the Azure AI Foundry resource')
param location string

@description('Name of the Azure AI Foundry account')
@minLength(3)
@maxLength(24)
param foundryResourceName string

@description('Application Insights resource ID for observability')
param applicationInsightsResourceId string = ''

@description('Log Analytics workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string = ''

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: foundryResourceName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiProperties: {}
    allowProjectManagement: true
    customSubDomainName: foundryResourceName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    defaultProject: aiProjectName
    associatedProjects: [aiProjectName]
  }
  tags: tags
}

// Add diagnostic settings to send logs to Log Analytics workspace
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${foundryResourceName}-diagnostics'
  scope: account
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
      {
        category: 'RequestResponse'
        enabled: true
      }
      {
        category: 'Trace'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output accountName string = account.name
output endpoint string = account.properties.endpoints['AI Foundry API']
