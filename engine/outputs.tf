# ===========================================================================
# PLUMBING — DO NOT EDIT.
# ===========================================================================
output "zone_id" {
  description = "ID of the created zone."
  value       = cloudflare_zone.this.id
}

output "zone_name" {
  description = "The zone (domain) name."
  value       = cloudflare_zone.this.name
}

output "name_servers" {
  description = "Nameservers Cloudflare assigned to the zone. Set THESE at your registrar to activate the domain. When Foundation DNS advanced nameservers are enabled, the advanced NS values are also shown on the DNS Records page in the dashboard."
  value       = cloudflare_zone.this.name_servers
}

output "status" {
  description = "Zone activation status (pending until nameservers are updated at the registrar)."
  value       = cloudflare_zone.this.status
}

output "nameserver_type" {
  description = "The configured nameserver type (cloudflare.advanced = Foundation DNS is on)."
  value       = cloudflare_zone_dns_settings.this.nameservers.type
}

output "plan" {
  description = "Rate plan applied to the zone (null when Terraform does not manage the subscription)."
  value       = var.manage_subscription ? var.plan : null
}

output "record_ids" {
  description = "Map of logical record key to created DNS record ID."
  value       = { for k, r in cloudflare_dns_record.record : k => r.id }
}
