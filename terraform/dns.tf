data "cloudflare_zone" "jali-clarke" {
  name = "jali-clarke.ca"
}

resource "cloudflare_record" "cerberus" {
  zone_id = data.cloudflare_zone.jali-clarke.id
  name    = "cerberus"
  value   = hcloud_server.cerberus.ipv4_address
  type    = "A"
  ttl     = 1 # automatic
}
