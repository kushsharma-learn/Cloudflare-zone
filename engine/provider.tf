# ===========================================================================
# PLUMBING — DO NOT EDIT.
# Terraform + provider configuration for this zone. You never change anything
# in the engine/ folder; you only edit the tfvars in ../settings and ../tfvars.
# ===========================================================================
terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.7, < 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

# Authentication: export your Cloudflare API token before running Terraform:
#   export CLOUDFLARE_API_TOKEN="<your-token>"
# Token permissions needed:
#   Zone -> Zone          : Edit  (create the zone)
#   Zone -> DNS           : Edit  (create records)
#   Zone -> DNS Settings  : Edit  (enable Foundation DNS)
#   Billing               : Write (only if manage_subscription = true)
provider "cloudflare" {}
