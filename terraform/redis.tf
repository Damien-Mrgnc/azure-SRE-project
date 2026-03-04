# ---
# 6. Redis Cache (Azure Cache for Redis)
# ---
resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.project_name}-${random_id.server_suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Basic SKU C0 is the cheapest (250MB) - Perfect for dev/lab
  capacity = 0
  family   = "C"
  sku_name = "Basic"

  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  redis_configuration {
    maxmemory_reserved = 2
    maxmemory_delta    = 2
    maxmemory_policy   = "allkeys-lru"
  }

  tags = local.tags
}

# Store Redis Connection String in Key Vault
resource "azurerm_key_vault_secret" "redis_connection_string" {
  name = "redis-connection-string"
  # Format : rediss://:<password>@<hostname>:<port>
  value           = "rediss://:${azurerm_redis_cache.main.primary_access_key}@${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port}"
  key_vault_id    = azurerm_key_vault.main.id
  content_type    = "text/plain"
  expiration_date = "2026-12-31T00:00:00Z"

  tags = local.tags
}
