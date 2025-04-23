resource "aws_route53_zone" "hhnet" {
  name    = "heinrichhartmann.net"
  comment = "local infrastructure"
}

resource "aws_route53_record" "gw" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "gw.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.2.1",
  ]
  ttl = 300
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.heinrichhartmann.net"
  type    = "A"
  records = [
    "100.100.120.89",
  ]
  ttl = 300
}

resource "aws_route53_record" "lan" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.lan.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.2.12",
  ]
  ttl = 300
}

resource "aws_route53_record" "samba_lan" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "smb.lan.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.2.13",
  ]
  ttl = 300
}

resource "aws_route53_record" "otelcol_pve" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "otel-collector.pve.heinrichhartmann.net"
  type    = "A"
  records = [
    "192.168.3.3",
  ]
  ttl = 300
}

resource "aws_route53_record" "tailscale" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.ts.heinrichhartmann.net"
  type    = "A"
  records = [
    "100.100.120.89",
  ]
  ttl = 300
}

resource "aws_route53_record" "hifipi" {
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.hifipi.heinrichhartmann.net"
  type    = "A"
  records = [
    "100.97.166.55",
  ]
  ttl = 300
}

locals {
    ts_hosts = {
        "pve" = "100.100.120.89"
        "hifipi" = "100.97.166.55"
        "hhe15" = "100.121.201.109"
        "spohrhp20" = "100.67.92.4"
    }
}

resource "aws_route53_record" "ts_hosts" {
  for_each = local.ts_hosts
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "${each.key}.ts.heinrichhartmann.net"
  type    = "A"
  records = [
    each.value,
  ]
  ttl = 300
}

resource "aws_route53_record" "ts_wildcards" {
  for_each = local.ts_hosts
  zone_id = aws_route53_zone.hhnet.zone_id
  name    = "*.${each.key}.ts.heinrichhartmann.net"
  type    = "A"
  records = [
    each.value,
  ]
  ttl = 300
} 