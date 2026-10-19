# ===========================================================================
#  DNS RECORDS for this zone.
#
#  Map keyed by a logical name of YOUR choice (the key is only a label in
#  Terraform — it is not sent to Cloudflare). Use "@" for the zone apex.
#  Full field list + allowed values (incl. structured records like CAA, SRV,
#  TLSA, LOC, …): ../../../engine/variables.tf
#
#  Leave as {} if you only want to create the zone for now and add records later.
#
#  The examples below cover: A, AAAA, CNAME, MX, NS, PTR, TXT.
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

  # CNAME — www -> apex (proxied).
  www = {
    type    = "CNAME"
    name    = "www"
    content = "example.com"
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

  # PTR — pointer record (reverse DNS); content is the target hostname.
  ptr = {
    type    = "PTR"
    name    = "1"
    content = "host.example.com"
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
