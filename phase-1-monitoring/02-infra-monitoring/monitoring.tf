# ---
# 6. Observability (Log Analytics & App Insights)
# ---

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${random_id.server_suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${random_id.server_suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.tags
}

resource "azurerm_linux_web_app" "grafana" {
  name                    = "grafana-${var.project_name}-${random_id.server_suffix.hex}"
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_service_plan.main.location
  service_plan_id         = azurerm_service_plan.main.id # Partage le plan App Service existant (pas de surcoût)
  https_only              = true
  client_affinity_enabled = false

  # checkov:skip=CKV_AZURE_13: "Auth simplifiée pour lab"
  # checkov:skip=CKV_AZURE_222: "Private Endpoints trop chers pour lab"
  # checkov:skip=CKV_AZURE_113: "Accès public requis pour Grafana lab"
  # checkov:skip=CKV_AZURE_88: "Pas de storage account monté"
  # checkov:skip=CKV_AZURE_17: "Client affinity non nécessaire"
  # checkov:skip=CKV_AZURE_65: "Restrictions d'accès ignorées pour lab"
  # checkov:skip=CKV_AZURE_71: "Managed identity non utilisée ici"
  # checkov:skip=CKV_AZURE_78: "Client certs non requis"

  site_config {
    application_stack {
      docker_image_name   = "grafana/grafana:latest"
      docker_registry_url = "https://index.docker.io"
    }

    always_on                         = true
    ftps_state                        = "Disabled"
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 2

    ip_restriction {
      name       = "AllowAny"
      priority   = 100
      action     = "Allow"
      ip_address = "0.0.0.0/0"
    }
  }

  app_settings = {
    # Port exposé par Grafana (Docker)
    "WEBSITES_PORT" = "3000"

    # Sécurité admin
    "GF_SECURITY_ADMIN_USER"     = "admin"
    "GF_SECURITY_ADMIN_PASSWORD" = random_password.grafana_admin.result

    # URL publique (corrige les redirections)
    "GF_SERVER_ROOT_URL" = "https://grafana-${var.project_name}-${random_id.server_suffix.hex}.azurewebsites.net"

    # Datasource Azure Monitor pointer vers Log Analytics
    "GF_PLUGINS_PREINSTALL" = "grafana-azure-monitor-datasource"

    # Désactiver les analytics Grafana
    "GF_ANALYTICS_REPORTING_ENABLED"        = "false"
    "GF_ANALYTICS_CHECK_FOR_UPDATES"        = "false"
    "GF_ANALYTICS_CHECK_FOR_PLUGIN_UPDATES" = "false"
  }

  tags = local.tags
}

# Mot de passe aléatoire pour l'admin Grafana
resource "random_password" "grafana_admin" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Stocker le mot de passe Grafana dans Key Vault pour ne pas le perdre
resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name            = "grafana-admin-password"
  value           = random_password.grafana_admin.result
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "text/plain"
  expiration_date = "2026-12-31T00:00:00Z"

  tags = local.tags
}

resource "null_resource" "grafana_dashboard_webapp" {
  # Re-déployer le dashboard si le JSON change OU si l'App Service Grafana change
  triggers = {
    dashboard_md5 = filemd5("${path.module}/dashboards/webapp-health.json")
    grafana_id    = azurerm_linux_web_app.grafana.id
  }

  provisioner "local-exec" {
    # Attendre que Grafana soit prêt (jusqu'à 3 min), puis pousser le dashboard via son API REST
    command = <<-EOT
      echo "Attente du démarrage de Grafana..."
      for i in $(seq 1 18); do
        STATUS=$(curl -s -o /dev/null -w "%%{http_code}" https://${azurerm_linux_web_app.grafana.default_hostname}/api/health)
        if [ "$STATUS" = "200" ]; then
          echo "Grafana est prêt (tentative $i)"
          break
        fi
        echo "Tentative $i/18 - Statut HTTP: $STATUS - attente 10s..."
        sleep 10
      done

      echo "Déploiement du dashboard..."
      curl -sf \
        -X POST \
        -H "Content-Type: application/json" \
        -u "admin:${random_password.grafana_admin.result}" \
        -d "{\"dashboard\": $(cat ${path.module}/dashboards/webapp-health.json), \"overwrite\": true, \"folderId\": 0}" \
        https://${azurerm_linux_web_app.grafana.default_hostname}/api/dashboards/db
      echo "Dashboard déployé avec succès !"
    EOT

    interpreter = ["bash", "-c"]
  }

  depends_on = [
    azurerm_linux_web_app.grafana,
    azurerm_key_vault_secret.grafana_admin_password
  ]
}
