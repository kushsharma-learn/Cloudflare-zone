# ===========================================================================
#  ZONE SETTINGS  (one zone per folder)
#
#  To add another zone, copy the whole "example.com" folder (under dns-zones/)
#  and rename it to your domain (the folder name is just for humans — the real
#  domain is zone_name below). Then edit this file and ../records/records.tfvars.
# ===========================================================================

# ---- WHERE + WHAT (required) ----
account_id = "<YOUR_ACCOUNT_ID>" # Cloudflare Account ID (Enterprise account)
zone_name  = "<YOUR_DOMAIN>"     # the domain to create, e.g. "example.com"

# Zone setup type. "full" = Cloudflare is your authoritative (primary) DNS.
# full | partial | secondary | internal
zone_type = "full"

# ---- FOUNDATION DNS ----
# true  = enable Foundation DNS advanced nameservers (Enterprise)
# false = standard Cloudflare nameservers
foundation_dns = true

# TTL (seconds) for the zone's NS records. null = Cloudflare default.
# (Custom NS TTL is a Foundation DNS feature.)  e.g. 300 | 3600 | 86400
ns_ttl = null

# ---- SUBSCRIPTION / PLAN ----
# true  = Terraform sets the zone's plan to `plan` below (needs Billing Write)
# false = don't manage the plan (use this if your Enterprise contract
#         auto-provisions new zones as Enterprise)
manage_subscription = true

# Plan applied when manage_subscription = true.
# free | lite | pro | pro_plus | business | enterprise | partners_*
plan = "enterprise"

# Billing frequency. For Enterprise contracts leave null (billed by contract).
# weekly | monthly | quarterly | yearly | null
subscription_frequency = null
