records = {
  apex = {
    type    = "A"
    name    = "@"
    content = "192.0.2.1"
    ttl     = 3600
    proxied = false
    comment = "Apex A record"
  }

  apex-v6 = {
    type    = "AAAA"
    name    = "@"
    content = "2001:db8::1"
    ttl     = 1
    proxied = true
  }

  www = {
    type    = "CNAME"
    name    = "www"
    content = "abc.com"
    ttl     = 1
    proxied = true
  }

  mx-primary = {
    type     = "MX"
    name     = "@"
    content  = "route1.mx.cloudflare.net"
    ttl      = 3600
    priority = 10
  }

  ns-subdelegation = {
    type    = "NS"
    name    = "sub"
    content = "ns1.externalprovider.com"
    ttl     = 3600
  }

  spf = {
    type    = "TXT"
    name    = "@"
    content = "v=spf1 include:_spf.example.com ~all"
    ttl     = 3600
  }
}
