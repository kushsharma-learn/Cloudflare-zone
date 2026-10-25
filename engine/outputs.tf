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

output "status" {
  description = "Zone activation status (pending until registrar nameservers are updated)."
  value       = cloudflare_zone.this.status
}

output "nameserver_type" {
  description = "Configured nameserver type (cloudflare.advanced = Foundation DNS)."
  value       = cloudflare_zone_dns_settings.this.nameservers.type
}

output "standard_name_servers" {
  description = "Standard Cloudflare nameservers captured at creation (pre-conversion)."
  value       = cloudflare_zone.this.name_servers
}

output "foundation_dns_nameservers" {
  description = "Nameservers read after Foundation DNS conversion (the foundationdns.* set to set at your registrar). If still standard, raise ns_lookup_delay or re-apply."
  value       = data.cloudflare_zone.assigned.name_servers
}

output "plan" {
  description = "Rate plan applied (null when Terraform does not manage the subscription)."
  value       = var.manage_subscription ? var.plan : null
}

output "record_ids" {
  description = "Map of logical record key to created DNS record ID."
  value       = { for k, r in cloudflare_dns_record.record : k => r.id }
}
