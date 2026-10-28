# ===========================================================================
#  ZONE SETTINGS (one zone per folder)
#
#  To add a zone: copy this whole folder to dns-zones/<your-domain>/ and edit
#  this file + ../records/records.tfvars. CI creates every folder under
#  dns-zones/. The folder name is the zone id (CI job + state file); the real
#  domain is zone_name below.
# ===========================================================================

# ---- WHERE + WHAT (required) ----
account_id = "b1d2a86cbf7d5358135fe2674a27b717" # Cloudflare Account ID (Enterprise account)
zone_name  = "stevethree.kushlearn.in"           # the domain to create

# Zone setup type. full | partial | secondary | internal
zone_type = "full"

# ---- FOUNDATION DNS ----
# true = enable Foundation DNS advanced nameservers | false = standard
foundation_dns = true

# Nameserver (NS) record TTL in seconds (Foundation DNS lets you set this).
# null = Cloudflare default. e.g. 300 | 3600 | 86400
ns_ttl = null

# Delay after enabling Foundation DNS before reading the assigned advanced
# nameservers, so the foundation_dns_nameservers output shows foundationdns.*
# names. Go duration. e.g. "15s" | "30s" | "60s"
ns_lookup_delay = "30s"

# ---- SOA RECORD (optional — Foundation DNS lets you customize SOA) ----
# Leave commented to use Cloudflare's default SOA. To customize, uncomment and
# set the fields you want (any field left out uses the Cloudflare default).
# soa = {
#   mname   = "ns.cloudflare.com"       # primary nameserver (null = Cloudflare-assigned)
#   rname   = "admin.tfcreated.kushlearn.in" # admin email; first label = local part
#   ttl     = 3600                      # SOA record TTL        (60-86400)
#   refresh = 10000                     # secondary re-check    (600-86400)
#   retry   = 2400                      # secondary retry       (600-86400)
#   expire  = 604800                    # secondary expiry      (86400-2419200)
#   min_ttl = 1800                      # negative-cache TTL    (60-86400)
# }

# ---- SUBSCRIPTION / PLAN ----
# true = Terraform sets the plan below (needs Billing Write) | false = don't manage
manage_subscription = true

# free | lite | pro | pro_plus | business | enterprise | partners_*
plan = "enterprise"

# weekly | monthly | quarterly | yearly | null (contract default)
subscription_frequency = null
