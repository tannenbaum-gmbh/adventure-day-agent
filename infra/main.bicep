targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed(['northcentralus','swedencentral', 'eastus2', 'westus3'])
param location string

param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param openaiName string = ''
param apiContainerAppName string = 'phase1'
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param logAnalyticsName string = ''

param phase1Exits bool = false

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

param completionDeploymentModelName string = 'gpt-4o'
param completionModelName string = 'gpt-4o'
param completionModelVersion string = '2024-08-06'
param embeddingDeploymentModelName string = 'text-embedding-ada-002'
param embeddingModelName string = 'text-embedding-ada-002'
param openaiApiVersion string = '2024-02-01'
param openaiCapacity int = 50
param modelDeployments array = [
  {
    name: completionDeploymentModelName
    model: {
      format: 'OpenAI'
      name: completionModelName
      version: completionModelVersion
    }
  }
  {
    name: embeddingDeploymentModelName
    model: {
      format: 'OpenAI'
      name: embeddingModelName
      version: '2'
    }
  }
]


// Container apps host (including container registry)
module containerApps './core/host/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    name: 'app'
    containerAppsEnvironmentName: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
}

// Phase 1 Container App
module phase1 './app/phase1.bicep' = {
  name: 'phase1'
  params: {
    name: !empty(apiContainerAppName) ? apiContainerAppName : '${abbrs.appContainerApps}api-${resourceToken}'
    location: location
    tags: tags
    imageName: ''
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}api-agents'
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    openaiName: openai.outputs.openaiName
    searchName: search.outputs.searchName
    searchEndpoint: search.outputs.searchEndpoint
    openaiApiVersion: openaiApiVersion
    openaiEndpoint: openai.outputs.openaiEndpoint
    completionDeploymentName: completionDeploymentModelName
    exists: phase1Exits
  }
}

// Azure OpenAI Model
module openai './ai/openai.bicep' = {
  name: 'openai'
  params: {
    location: location
    tags: tags
    customDomainName: !empty(openaiName) ? openaiName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    name: !empty(openaiName) ? openaiName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    deployments: modelDeployments
    capacity: openaiCapacity
  }
}

// Azure AI Search
module search './ai/search.bicep' = {
  name: 'search'
  params: {
    location: location
    tags: tags
    name: !empty(openaiName) ? openaiName : '${abbrs.searchSearchServices}${resourceToken}'
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = resourceGroup().name

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output SERVICE_NAME_PHASE1 string = phase1.outputs.SERVICE_API_NAME
output OPENAI_API_TYPE string = 'azure'
output AZURE_OPENAI_VERSION string = openaiApiVersion
output AZURE_OPENAI_API_KEY string = openai.outputs.openaiKey
output AZURE_OPENAI_ENDPOINT string = openai.outputs.openaiEndpoint
output AZURE_OPENAI_COMPLETION_MODEL string = completionModelName
output AZURE_OPENAI_COMPLETION_DEPLOYMENT_NAME string = completionDeploymentModelName
output AZURE_OPENAI_EMBEDDING_MODEL string = embeddingModelName
output AZURE_OPENAI_EMBEDDING_DEPLOYMENT_NAME string = embeddingDeploymentModelName
output PHASE1_URL string = phase1.outputs.SERVICE_API_URI
output AZURE_AI_SEARCH_NAME string = search.outputs.searchName
output AZURE_AI_SEARCH_ENDPOINT string = search.outputs.searchEndpoint
output AZURE_AI_SEARCH_KEY string = search.outputs.searchAdminKey
