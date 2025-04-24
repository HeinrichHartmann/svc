locals {
  static_records = {
    // Special Hosts
    "gw.heinrichhartmann.net" = "192.168.2.1",
    "otel-collector.pve.heinrichhartmann.net" = "192.168.3.3",

    // Home Network
    "*.lan.heinrichhartmann.net" = "192.168.2.12", # pve on LAN
    "pve.lan.heinrichhartmann.net" = "192.168.2.12",
    "smb.lan.heinrichhartmann.net" = "192.168.2.13",

    // Tailscale Network
    "*.heinrichhartmann.net" = "100.100.120.89", # pve host
    "pve.ts.heinrichhartmann.net" = "100.100.120.89",
    "*.pve.ts.heinrichhartmann.net" = "100.100.120.89",
    "hhe15.ts.heinrichhartmann.net" = "100.121.201.109",
    "*.hhe15.ts.heinrichhartmann.net" = "100.121.201.109",
  }
}

resource "aws_route53_zone" "hhnet" {
  name    = "heinrichhartmann.net"
  comment = "local infrastructure"
}

resource "aws_route53_record" "static_records" {
  for_each = local.static_records
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = each.key
  type    = "A"
  records = [
    each.value,
  ]
  ttl = 300
} 