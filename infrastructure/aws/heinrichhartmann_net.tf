locals {
  static_records = {
    // Special Hosts
    "gw.heinrichhartmann.net" = "192.168.2.1",
    "smb.lan.heinrichhartmann.net" = "192.168.2.13",
    "otel-collector.pve.heinrichhartmann.net" = "192.168.3.3",

    // Root Domains
    "*.heinrichhartmann.net" = "100.100.120.89", # PVE on tailscale network
    "*.lan.heinrichhartmann.net" = "192.168.2.12", # PVE on LAN

    // Host Records
    "pve.ts.heinrichhartmann.net" = "100.100.120.89",
    "*.pve.ts.heinrichhartmann.net" = "100.100.120.89",
    "hifipi.ts.heinrichhartmann.net" = "100.97.166.55",
    "*.hifipi.ts.heinrichhartmann.net" = "100.97.166.55",
    "hhe15.ts.heinrichhartmann.net" = "100.121.201.109",
    "*.hhe15.ts.heinrichhartmann.net" = "100.121.201.109",
    "spohrhp20.ts.heinrichhartmann.net" = "100.67.92.4",
    "*.spohrhp20.ts.heinrichhartmann.net" = "100.67.92.4"
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