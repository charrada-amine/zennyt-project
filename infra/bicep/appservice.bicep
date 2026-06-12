// infra/bicep/appservice.bicep
// Provisionne le plan App Service + l'app conteneurisée + le slot staging (prod).
// Déployé par le pipeline infra-cd uniquement sur modification de infra/**.

@description('Environnement cible : dev, staging ou prod')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Région Azure')
param location string = resourceGroup().location

@description('Registre de conteneurs')
param acrName string = 'zennyt'

@description('Nom de l\'image (sans le tag)')
param imageName string = 'zennyt-api'

@description('Tag de l\'image à déployer')
param imageTag string = 'latest'

@description('URI du Key Vault pour les secrets')
param keyVaultUri string

var appName = 'zennyt-${environmentName}'
var planSku = environmentName == 'prod' ? 'P1v3' : (environmentName == 'staging' ? 'S1' : 'B1')
var isProd = environmentName == 'prod'

// ───────────── App Service Plan (Linux) ─────────────
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-${appName}'
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    reserved: true   // requis pour Linux
  }
}

// ───────────── Application Insights ─────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${appName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// ───────────── App Service (conteneur) ─────────────
resource app 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'   // pour accéder à Key Vault et ACR sans secret
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrName}.azurecr.io/${imageName}:${imageTag}'
      alwaysOn: environmentName != 'dev'
      healthCheckPath: '/actuator/health'
      acrUseManagedIdentityCreds: true
      appSettings: [
        { name: 'WEBSITES_PORT', value: '8080' }
        { name: 'SPRING_PROFILES_ACTIVE', value: environmentName }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsights.properties.ConnectionString }
        // Les secrets sont référencés depuis Key Vault, jamais en clair
        { name: 'SPRING_DATASOURCE_URL', value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/db-url-${environmentName})' }
        { name: 'SPRING_DATASOURCE_PASSWORD', value: '@Microsoft.KeyVault(SecretUri=${keyVaultUri}secrets/db-password-${environmentName})' }
      ]
    }
  }
}

// ───────────── Slot "staging" (production uniquement) ─────────────
// C'est ce slot qui reçoit la nouvelle version avant le swap atomique.
resource stagingSlot 'Microsoft.Web/sites/slots@2023-12-01' = if (isProd) {
  parent: app
  name: 'staging'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrName}.azurecr.io/${imageName}:${imageTag}'
      alwaysOn: true
      healthCheckPath: '/actuator/health'
      acrUseManagedIdentityCreds: true
      autoSwapSlotName: ''   // swap manuel, déclenché par le pipeline après smoke tests
    }
  }
}

output appServiceName string = app.name
output appServiceHostname string = app.properties.defaultHostName
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output principalId string = app.identity.principalId
