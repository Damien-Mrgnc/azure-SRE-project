terraform {
  required_version = ">= 1.5.0" # Force la derniere version stable

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-backend"
    storage_account_name = "sttfstate3756"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Version > 4.0 pour supporter Grafana 11
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false # Facilite le 'terraform destroy' pour les labs
    }
    key_vault {
      purge_soft_delete_on_destroy          = true # Purge le KV à la destruction
      recover_soft_deleted_key_vaults       = true # Récupère le KV s'il est soft-deleted
      recover_soft_deleted_secrets          = true # ✅ Clé du fix : récupère les secrets soft-deleted au lieu de crasher
      purge_soft_deleted_secrets_on_destroy = true # Purge les secrets à la destruction (ne laisse rien traîner)
    }
  }
}
