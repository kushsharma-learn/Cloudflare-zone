# ===========================================================================
# PLUMBING — DO NOT EDIT.
# Builds ONE Cloudflare zone from the tfvars in ../settings and ../tfvars:
# the zone itself, its Enterprise subscription, Foundation DNS advanced
# nameservers, and the DNS records you listed. DNSSEC is intentionally NOT
# configured (left disabled).
# ===========================================================================

# ---- ZONE: the domain itself ------------------------------------------------
# type = "full" means Cloudflare is the authoritative (primary) DNS provider.
resource "cloudflare_zone" "this" {
  account = {
    id = var.account_id
  }
  name = var.zone_name
  type = var.zone_type
}

# ---- SUBSCRIPTION: the zone's rate plan (e.g. Enterprise) -------------------
# Created only when manage_subscription = true. Needs a token with Billing
# Write. Set manage_subscription = false if your Enterprise contract already
# provisions new zones automatically.
resource "cloudflare_zone_subscription" "this" {
  count = var.manage_subscription ? 1 : 0

  zone_id   = cloudflare_zone.this.id
  frequency = var.subscription_frequency

  rate_plan = {
    id = var.plan
  }
}

# ---- DNS SETTINGS: this is where Foundation DNS is turned on ----------------
# nameservers.type = "cloudflare.advanced" opts the zone in to Foundation DNS
# advanced nameservers. "cloudflare.standard" keeps the regular nameservers.
resource "cloudflare_zone_dns_settings" "this" {
  zone_id = cloudflare_zone.this.id

  nameservers = {
    type = var.foundation_dns ? "cloudflare.advanced" : "cloudflare.standard"
  }

  # Only sent when you set a value; otherwise Cloudflare's default is kept.
  ns_ttl = var.ns_ttl
}

# ---- DNS RECORDS: one per entry in var.records -----------------------------
resource "cloudflare_dns_record" "record" {
  for_each = var.records

  zone_id  = cloudflare_zone.this.id
  type     = each.value.type
  name     = each.value.name
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
  tags     = each.value.tags

  # Structured value for CAA, CERT, DNSKEY, DS, HTTPS, LOC, NAPTR, SMIMEA, SRV,
  # SSHFP, SVCB, TLSA, URI. null for simple record types (which use content).
  data = each.value.data
}
