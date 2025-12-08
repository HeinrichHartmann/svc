locals {
  static_records = {
    "gw.heinrichhartmann.net" = "192.168.2.1",
    "otel-collector.pve.heinrichhartmann.net" = "192.168.3.3",

    // LAN hosts
    "*.lan.heinrichhartmann.net" = "192.168.2.14",
    "qve.lan.heinrichhartmann.net" = "192.168.2.14",

    "pve.lan.heinrichhartmann.net" = "192.168.2.12",

    // Tailscale Network
    "*.heinrichhartmann.net" = "100.75.70.47",
    "qve.heinrichhartmann.net" = "100.75.70.47",
    "*.qve.heinrichhartmann.net" = "100.75.70.47",
    "qve.ts.heinrichhartmann.net" = "100.75.70.47",
    "*.qve.ts.heinrichhartmann.net" = "100.75.70.47",

    "pve.heinrichhartmann.net" = "100.100.120.89",
    "*.pve.heinrichhartmann.net" = "100.100.120.89",
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
