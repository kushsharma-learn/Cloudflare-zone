# ===========================================================================
# PLUMBING — DO NOT EDIT.
# ---------------------------------------------------------------------------
# Inputs for ONE zone. Values are supplied per zone by the tfvars files, which
# the GitHub Actions workflow (or you, locally) pass with -var-file:
#   dns-zones/<zone>/settings/settings.tfvars -> account_id, zone_name, ...
#   dns-zones/<zone>/records/records.tfvars   -> records
# Every field and its ALLOWED VALUES is documented inline below.
# ===========================================================================


# ---------------------------------------------------------------------------
# 1. IDENTIFIERS
# ---------------------------------------------------------------------------
variable "account_id" {
  description = "Cloudflare Account ID that will own the zone (Enterprise account for Foundation DNS)."
  type        = string
}

variable "zone_name" {
  description = "The domain (apex) to create, e.g. \"example.com\"."
  type        = string
}

variable "zone_type" {
  description = "Zone setup type. Allowed: \"full\" | \"partial\" | \"secondary\" | \"internal\"."
  type        = string
  default     = "full"
}


# ---------------------------------------------------------------------------
# 2. FOUNDATION DNS
# ---------------------------------------------------------------------------
variable "foundation_dns" {
  description = "Enable Foundation DNS advanced nameservers (Enterprise). true | false."
  type        = bool
  default     = true
}

variable "ns_ttl" {
  description = "TTL in seconds for the zone's NS records (Foundation DNS). null = Cloudflare default."
  type        = number
  default     = null
}

# Delay after enabling Foundation DNS before re-reading the zone so the
# foundation_dns_nameservers output shows the advanced foundationdns.* names
# (the zone is created on standard nameservers and then converted). Go duration.
variable "ns_lookup_delay" {
  description = "Delay (Go duration) after enabling Foundation DNS before reading assigned nameservers. e.g. \"15s\" | \"30s\" | \"60s\"."
  type        = string
  default     = "30s"
}


# ---------------------------------------------------------------------------
# 3. SUBSCRIPTION / PLAN
# ---------------------------------------------------------------------------
variable "manage_subscription" {
  description = "Whether Terraform sets the zone's rate plan/subscription. true | false."
  type        = bool
  default     = true
}

variable "plan" {
  description = "Zone rate plan ID applied when manage_subscription = true. free | lite | pro | pro_plus | business | enterprise | partners_*."
  type        = string
  default     = "enterprise"
}

variable "subscription_frequency" {
  description = "Billing frequency: weekly | monthly | quarterly | yearly | null (contract default)."
  type        = string
  default     = null
}


# ---------------------------------------------------------------------------
# 4. DNS RECORDS (keyed by a logical name of your choice)
#    SIMPLE records (A, AAAA, CNAME, MX, NS, OPENPGPKEY, PTR, TXT) use `content`.
#    STRUCTURED records (CAA, CERT, DNSKEY, DS, HTTPS, LOC, NAPTR, SMIMEA, SRV,
#    SSHFP, SVCB, TLSA, URI) use the `data` object. Field-by-type reference:
#      CAA  -> data: tag, value, flags          DS    -> data: key_tag, algorithm, digest_type, digest
#      CERT -> data: type, algorithm, key_tag, certificate   HTTPS/SVCB -> data: priority, target, value
#      DNSKEY -> data: flags, protocol, algorithm, public_key  SRV  -> data: priority, weight, port, target
#      LOC  -> data: lat_*/long_*/altitude/size/precision_*  SSHFP -> data: algorithm, type, fingerprint
#      NAPTR -> data: order, preference, flags, service, regex, replacement
#      SMIMEA/TLSA -> data: usage, selector, matching_type, certificate   URI -> priority + data: weight, target
# ---------------------------------------------------------------------------
variable "records" {
  description = "DNS records to create in the zone, keyed by a logical name of your choice."
  type = map(object({
    # Record type. Allowed: A | AAAA | CAA | CERT | CNAME | DNSKEY | DS | HTTPS |
    # LOC | MX | NAPTR | NS | OPENPGPKEY | PTR | SMIMEA | SRV | SSHFP | SVCB | TLSA | TXT | URI
    type = string

    # Record name. "@" = zone apex, or a short label like "www" / "mail".
    name = string

    # Value for SIMPLE records (leave unset for structured records using `data`).
    content = optional(string)

    # TTL seconds. 1 = automatic (required for proxied). 60-86400 (Enterprise: 30+).
    ttl = optional(number, 1)

    # Proxied (orange-cloud) vs DNS-only. Only A/AAAA/CNAME. true | false.
    proxied = optional(bool, false)

    # Required for MX and URI (lower = preferred). SRV/HTTPS/SVCB use data.priority.
    priority = optional(number)

    comment = optional(string)
    tags    = optional(set(string))

    # Structured value for the record types listed in the header above.
    data = optional(object({
      tag            = optional(string)
      value          = optional(string)
      flags          = optional(any)
      algorithm      = optional(number)
      type           = optional(number)
      key_tag        = optional(number)
      certificate    = optional(string)
      protocol       = optional(number)
      public_key     = optional(string)
      digest         = optional(string)
      digest_type    = optional(number)
      fingerprint    = optional(string)
      usage          = optional(number)
      selector       = optional(number)
      matching_type  = optional(number)
      priority       = optional(number)
      weight         = optional(number)
      port           = optional(number)
      target         = optional(string)
      order          = optional(number)
      preference     = optional(number)
      service        = optional(string)
      regex          = optional(string)
      replacement    = optional(string)
      lat_degrees    = optional(number)
      lat_minutes    = optional(number)
      lat_seconds    = optional(number)
      lat_direction  = optional(string)
      long_degrees   = optional(number)
      long_minutes   = optional(number)
      long_seconds   = optional(number)
      long_direction = optional(string)
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
    error_message = "Each record 'type' must be a supported Cloudflare DNS record type."
  }
}
