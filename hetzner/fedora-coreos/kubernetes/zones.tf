resource "hetznerdns_zone" "zone" {
    name = var.dns_zone
    ttl = 300
}