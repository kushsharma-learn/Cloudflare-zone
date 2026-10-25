# ===========================================================================
# PLUMBING — DO NOT EDIT.
# Builds ONE Cloudflare zone from the tfvars passed via -var-file:
#   dns-zones/<zone>/settings/settings.tfvars  -> zone + subscription + Foundation DNS
#   dns-zones/<zone>/records/records.tfvars    -> that zone's DNS records
# The GitHub Actions workflow runs this once per zone folder (a matrix "loop"),
# each with its own state file. DNSSEC is intentionally NOT configured.
# ===========================================================================

# ---- ZONE: the domain itself ------------------------------------------------
resource "cloudflare_zone" "this" {
  account = {
    id = var.account_id
  }
  name = var.zone_name
  type = var.zone_type
}

# ---- SUBSCRIPTION: the zone's rate plan (e.g. Enterprise) -------------------
resource "cloudflare_zone_subscription" "this" {
  count = var.manage_subscription ? 1 : 0

  zone_id   = cloudflare_zone.this.id
  frequency = var.subscription_frequency

  rate_plan = {
    id = var.plan
  }
}

# ---- DNS SETTINGS: this is where Foundation DNS is turned on ----------------
resource "cloudflare_zone_dns_settings" "this" {
  zone_id = cloudflare_zone.this.id

  nameservers = {
    type = var.foundation_dns ? "cloudflare.advanced" : "cloudflare.standard"
  }

  # Nameserver TTL (Foundation DNS). null = Cloudflare default.
  ns_ttl = var.ns_ttl

  # Custom SOA (Foundation DNS). null = Cloudflare defaults.
  soa = var.soa
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
  data     = each.value.data
}

# ---- WAIT then RE-READ the zone to surface the assigned nameservers ---------
# The zone is created on STANDARD nameservers and only then converted to
# Foundation DNS. We wait var.ns_lookup_delay after enabling advanced
# nameservers, then read the zone fresh so name_servers reflects the assigned
# foundationdns.com/.net/.org set.
resource "time_sleep" "wait_for_nameservers" {
  depends_on      = [cloudflare_zone_dns_settings.this]
  create_duration = var.ns_lookup_delay
}

data "cloudflare_zone" "assigned" {
  zone_id    = cloudflare_zone.this.id
  depends_on = [time_sleep.wait_for_nameservers]
}
