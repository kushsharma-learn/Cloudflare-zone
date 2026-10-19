# ===========================================================================
# PLUMBING — DO NOT EDIT.
# ---------------------------------------------------------------------------
# These are the inputs for ONE zone. You set their VALUES in the per-zone
# tfvars files under ../dns-zones/<domain>/, not here:
#   ../dns-zones/<domain>/settings/settings.tfvars -> account_id, zone_name,
#       zone_type, foundation_dns, ns_ttl, manage_subscription, plan,
#       subscription_frequency
#   ../dns-zones/<domain>/records/records.tfvars   -> records
#
# This file documents every field and its ALLOWED VALUES (shown by `terraform`
# tooling). Read it if you are unsure what to put in a tfvars file.
# ===========================================================================


# ---------------------------------------------------------------------------
# 1. IDENTIFIERS (where the zone lives + what it is called)
# ---------------------------------------------------------------------------
variable "account_id" {
  description = "Cloudflare Account ID that will own the zone. Must be on an Enterprise plan for Foundation DNS. Find it in: Dashboard > any zone > Overview (right sidebar), or Manage Account > Account ID."
  type        = string
}

variable "zone_name" {
  description = "The domain (apex) to create, e.g. \"example.com\". Per RFC 1035 the name can be up to 253 characters."
  type        = string
}

variable "zone_type" {
  description = "Zone setup type. \"full\" = Cloudflare is your authoritative/primary DNS (the normal choice). Allowed: \"full\" | \"partial\" | \"secondary\" | \"internal\"."
  type        = string
  default     = "full"
}


# ---------------------------------------------------------------------------
# 2. FOUNDATION DNS (Enterprise-only advanced nameservers)
# ---------------------------------------------------------------------------
# true  -> opt the zone in to Foundation DNS advanced nameservers
#          (nameservers.type = "cloudflare.advanced"): strategically
#          distributed anycast IPs, reduced blast radius, more consistent
#          nameserver assignment.  https://developers.cloudflare.com/dns/foundation-dns/
# false -> standard Cloudflare nameservers (nameservers.type = "cloudflare.standard")
#
# NOTE: after this is applied, update the authoritative nameservers at your
# registrar to the assigned values. With Cloudflare Registrar, contact
# Cloudflare Support to switch to the advanced nameservers.
variable "foundation_dns" {
  description = "Enable Foundation DNS advanced nameservers on the zone (Enterprise only). true | false."
  type        = bool
  default     = true
}

# Time to live (in seconds) of the zone's nameserver (NS) records. Customizing
# the NS TTL is a Foundation DNS feature. null = leave at Cloudflare's default.
# e.g. 300 | 3600 | 86400
variable "ns_ttl" {
  description = "TTL in seconds for the zone's NS records (Foundation DNS). null = Cloudflare default."
  type        = number
  default     = null
}


# ---------------------------------------------------------------------------
# 3. SUBSCRIPTION / PLAN (how the zone is billed)
# ---------------------------------------------------------------------------
# true  -> Terraform applies var.plan (e.g. "enterprise") to the zone.
#          Requires a token with Billing Write and an entitled account.
# false -> Terraform does NOT manage the subscription. Use this if your
#          Enterprise contract auto-provisions new zones as Enterprise.
variable "manage_subscription" {
  description = "Whether Terraform manages the zone's rate plan/subscription. true | false."
  type        = bool
  default     = true
}

# The rate plan to apply when manage_subscription = true.
# Allowed: "free" | "lite" | "pro" | "pro_plus" | "business" | "enterprise" |
#          "partners_free" | "partners_pro" | "partners_business" | "partners_enterprise"
variable "plan" {
  description = "Zone rate plan ID applied when manage_subscription = true."
  type        = string
  default     = "enterprise"
}

# How often the subscription renews. For Enterprise contracts billing is
# usually handled by the contract, so leave null unless you know you need it.
# Allowed: "weekly" | "monthly" | "quarterly" | "yearly" | null
variable "subscription_frequency" {
  description = "Billing frequency for the subscription. null = not set (contract default)."
  type        = string
  default     = null
}


# ---------------------------------------------------------------------------
# 4. DNS RECORDS  (keyed by a logical name of your choice)
#    The map key (e.g. "apex", "www", "mx-primary") is just a label used in
#    Terraform state and plan output; it is not sent to Cloudflare.
#
#    There are two kinds of record:
#      * SIMPLE records put their value in `content`:
#          A, AAAA, CNAME, MX, NS, OPENPGPKEY, PTR, TXT
#        (MX and URI also set the top-level `priority`.)
#      * STRUCTURED records leave `content` unset and fill the `data` object
#        with type-specific fields:
#          CAA, CERT, DNSKEY, DS, HTTPS, LOC, NAPTR, SMIMEA, SRV, SSHFP,
#          SVCB, TLSA, URI
#
#    Field-by-type reference (matches the Cloudflare API record models):
#      CAA    -> data: tag, value, flags
#      CERT   -> data: type, algorithm, key_tag, certificate
#      DNSKEY -> data: flags, protocol, algorithm, public_key
#      DS     -> data: key_tag, algorithm, digest_type, digest
#      HTTPS  -> data: priority, target, value
#      LOC    -> data: lat_degrees, lat_minutes, lat_seconds, lat_direction,
#                      long_degrees, long_minutes, long_seconds, long_direction,
#                      altitude, size, precision_horz, precision_vert
#      NAPTR  -> data: order, preference, flags, service, regex, replacement
#      SMIMEA -> data: usage, selector, matching_type, certificate
#      SRV    -> data: priority, weight, port, target
#      SSHFP  -> data: algorithm, type, fingerprint
#      SVCB   -> data: priority, target, value
#      TLSA   -> data: usage, selector, matching_type, certificate
#      URI    -> priority (top-level) + data: weight, target
# ---------------------------------------------------------------------------
variable "records" {
  description = "DNS records to create in the zone, keyed by a logical name of your choice."
  type = map(object({
    # Record type.
    # Allowed: "A" | "AAAA" | "CAA" | "CERT" | "CNAME" | "DNSKEY" | "DS" |
    #          "HTTPS" | "LOC" | "MX" | "NAPTR" | "NS" | "OPENPGPKEY" | "PTR" |
    #          "SMIMEA" | "SRV" | "SSHFP" | "SVCB" | "TLSA" | "TXT" | "URI"
    type = string

    # Record name. Use "@" for the zone apex (the domain itself), or a short
    # label like "www" / "mail" (Cloudflare appends the zone automatically).
    name = string

    # Value for SIMPLE records (leave unset for structured records that use `data`):
    #   A          -> IPv4 address     e.g. "192.0.2.1"
    #   AAAA       -> IPv6 address     e.g. "2001:db8::1"
    #   CNAME      -> target hostname  e.g. "www.example.com"
    #   MX         -> mail host        e.g. "route1.mx.cloudflare.net"
    #   NS         -> nameserver host  e.g. "ns1.example.net"
    #   OPENPGPKEY -> base64 public key
    #   PTR        -> target domain    e.g. "host.example.com"
    #   TXT        -> text value       e.g. "v=spf1 include:_spf.example.com ~all"
    content = optional(string)

    # Time To Live in seconds. 1 = "automatic" (required for proxied records).
    # Range 60-86400 (Enterprise zones may go as low as 30). e.g. 1 | 300 | 3600
    ttl = optional(number, 1)

    # Orange-cloud (proxied through Cloudflare) vs grey-cloud (DNS only).
    # Only valid for A / AAAA / CNAME. Use false for a pure authoritative-DNS
    # record (MX, TXT, NS, verification CNAMEs, etc.). true | false
    proxied = optional(bool, false)

    # Top-level priority. Required for MX and URI (lower = preferred). For SRV,
    # HTTPS and SVCB the priority lives inside `data` instead. e.g. 10 | 20
    priority = optional(number)

    # Free-text note shown in the dashboard. No effect on DNS responses.
    comment = optional(string)

    # Custom tags for organizing records (Enterprise). No effect on DNS responses.
    # e.g. ["team:platform", "env:prod"]
    tags = optional(set(string))

    # Structured value for the record types listed in the header above. Set only
    # the fields that apply to the record's type; leave the rest unset.
    data = optional(object({
      # CAA
      tag   = optional(string) # "issue" | "issuewild" | "iodef"
      value = optional(string) # also used by HTTPS / SVCB (SvcParams); CAA value
      # CAA / DNSKEY: a number; NAPTR: a string. Typed as any to allow both.
      flags = optional(any)

      # CERT / DNSKEY / DS / SSHFP
      algorithm   = optional(number) # CERT, DNSKEY, DS, SSHFP
      type        = optional(number) # CERT (cert type), SSHFP (fingerprint type)
      key_tag     = optional(number) # CERT, DS
      certificate = optional(string) # CERT, SMIMEA, TLSA
      protocol    = optional(number) # DNSKEY
      public_key  = optional(string) # DNSKEY
      digest      = optional(string) # DS
      digest_type = optional(number) # DS
      fingerprint = optional(string) # SSHFP

      # SMIMEA / TLSA
      usage         = optional(number) # SMIMEA, TLSA
      selector      = optional(number) # SMIMEA, TLSA
      matching_type = optional(number) # SMIMEA, TLSA

      # SRV / HTTPS / SVCB / URI
      priority = optional(number) # SRV, HTTPS, SVCB (data-level priority)
      weight   = optional(number) # SRV, URI
      port     = optional(number) # SRV
      target   = optional(string) # SRV, HTTPS, SVCB, URI

      # NAPTR
      order       = optional(number)
      preference  = optional(number)
      service     = optional(string)
      regex       = optional(string)
      replacement = optional(string)

      # LOC
      lat_degrees    = optional(number)
      lat_minutes    = optional(number)
      lat_seconds    = optional(number)
      lat_direction  = optional(string) # "N" | "S"
      long_degrees   = optional(number)
      long_minutes   = optional(number)
      long_seconds   = optional(number)
      long_direction = optional(string) # "E" | "W"
      altitude       = optional(number)
      size           = optional(number)
      precision_horz = optional(number)
      precision_vert = optional(number)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.records) : contains([
        "A", "AAAA", "CAA", "CERT", "CNAME", "DNSKEY", "DS", "HTTPS", "LOC",
        "MX", "NAPTR", "NS", "OPENPGPKEY", "PTR", "SMIMEA", "SRV", "SSHFP",
        "SVCB", "TLSA", "TXT", "URI",
      ], r.type)
    ])
    error_message = "Each record 'type' must be one of the supported Cloudflare DNS record types: A, AAAA, CAA, CERT, CNAME, DNSKEY, DS, HTTPS, LOC, MX, NAPTR, NS, OPENPGPKEY, PTR, SMIMEA, SRV, SSHFP, SVCB, TLSA, TXT, URI."
  }
}
