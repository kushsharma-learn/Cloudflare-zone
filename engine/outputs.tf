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

output "foundation_dns_nameservers" {
  description = "Nameservers read after Foundation DNS conversion (the foundationdns.* set to set at your registrar). If still standard, raise ns_lookup_delay or re-apply."
  value       = data.cloudflare_zone.assigned.name_servers
}
