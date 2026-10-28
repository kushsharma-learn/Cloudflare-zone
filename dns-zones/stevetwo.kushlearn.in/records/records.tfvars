# ===========================================================================
#  DNS RECORDS for this zone.
#
#  Map keyed by a logical name of YOUR choice (label only; not sent to
#  Cloudflare). Use "@" for the zone apex.
#   * SIMPLE  (value in `content`): A, AAAA, CNAME, MX (+priority), NS,
#             OPENPGPKEY, PTR, TXT
#   * STRUCTURED (value in a `data = {}` block): CAA, CERT, DNSKEY, DS, HTTPS,
#             LOC, NAPTR, SMIMEA, SRV, SSHFP, SVCB, TLSA, URI
#     e.g.  caa = { type = "CAA", name = "@", ttl = 3600,
#                   data = { tag = "issue", value = "letsencrypt.org", flags = 0 } }
#
#  Leave as {} to create the zone with no records.
# ===========================================================================

records = {
  # A — apex IPv4 (DNS-only / grey-cloud).
  apex = {
    type    = "A"
    name    = "@"
    content = "192.0.2.1"
    ttl     = 3600
    proxied = false
    comment = "Apex A record"
  }

  # AAAA — apex IPv6, proxied (orange-cloud). Proxied records must use ttl = 1.
  apex-v6 = {
    type    = "AAAA"
    name    = "@"
    content = "2001:db8::1"
    ttl     = 1
    proxied = true
  }

  # CNAME — www (proxied).
  www = {
    type    = "CNAME"
    name    = "www"
    content = "abc.com"
    ttl     = 1
    proxied = true
  }

  # MX — mail exchanger. MX needs a priority (lower = preferred).
  mx-primary = {
    type     = "MX"
    name     = "@"
    content  = "route1.mx.cloudflare.net"
    ttl      = 3600
    priority = 10
  }

  # NS — delegate a subdomain to external nameservers.
  ns-subdelegation = {
    type    = "NS"
    name    = "sub"
    content = "ns1.externalprovider.com"
    ttl     = 3600
  }

  # TXT — e.g. SPF.
  spf = {
    type    = "TXT"
    name    = "@"
    content = "v=spf1 include:_spf.example.com ~all"
    ttl     = 3600
  }
}
