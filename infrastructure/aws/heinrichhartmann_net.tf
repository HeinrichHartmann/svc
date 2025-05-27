locals {
  static_records = {
    // Special Hosts
    "*.heinrichhartmann.net" = "100.100.120.89", # pve host
    "gw.heinrichhartmann.net" = "192.168.2.1",
    "otel-collector.pve.heinrichhartmann.net" = "192.168.3.3",

    // LAN hosts
    "*.lan.heinrichhartmann.net" = "192.168.2.12", # pve on LAN
    "pve.lan.heinrichhartmann.net" = "192.168.2.12",
    "smb.lan.heinrichhartmann.net" = "192.168.2.13",
    "qve.lan.heinrichhartmann.net" = "192.168.2.14",

    // Tailscale Network
    "pve.heinrichhartmann.net" = "100.100.120.89",
    "pve.ts.heinrichhartmann.net" = "100.100.120.89",
    "*.pve.ts.heinrichhartmann.net" = "100.100.120.89",

    "hhe15.ts.heinrichhartmann.net" = "100.121.201.109",
    "*.hhe15.ts.heinrichhartmann.net" = "100.121.201.109",

    "qve.heinrichhartmann.net" = "100.75.70.47",
    "qve.ts.heinrichhartmann.net" = "100.75.70.47",
    "*.qve.ts.heinrichhartmann.net" = "100.75.70.47",
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
