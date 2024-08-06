# Controller Instance DNS records
resource "hetznerdns_record" "controllers" {
    count = var.controller_count

    # DNS zone where record should be created
    zone_id = hetznerdns_zone.zone.id

    # DNS record (will be prepended to domain)
    name = var.cluster_name
    type = "A"
    ttl = 300

    # IPv4 addresses of controllers
    value = hcloud_server.controllers.*.ipv4_address[count.index]
}

# Discrete DNS records for each controller's private IPv4 for etcd usage
resource "hetznerdns_record" "etcds" {
    count = var.controller_count

    # DNS zone where record should be created
    zone_id = hetznerdns_zone.zone.id

    # DNS record (will be prepended to domain)
    name = "${var.cluster_name}-etcd${count.index}"
    type = "A"
    ttl = 300

    # private IPv4 address for etcd
    value = hcloud_server.controllers.*.ipv4_address[count.index]
}

# Controller instances
resource "hcloud_server" "controllers" {
    count = var.controller_count

    name   = "${var.cluster_name}-controller-${count.index}"
    location = var.location

    image = var.os_image
    server_type = var.controller_type

    user_data = data.ct_config.controllers.*.rendered[count.index]
    ssh_keys  = var.ssh_fingerprints

    public_net {
        ipv4_enabled = true
        ipv6_enabled = false
    }

    labels = {
        name = "${var.cluster_name}-controller"
    }

    lifecycle {
        ignore_changes = [user_data]
    }
}

resource "hcloud_server_network" "controllers" {
  for_each = { for idx, server in hcloud_server.controllers : idx => server }

  server_id = each.value.id
  subnet_id = hcloud_network_subnet.controller_subnet.id
}

# Fedora CoreOS controllers
data "ct_config" "controllers" {
  count = var.controller_count
  content = templatefile("${path.module}/butane/controller.yaml", {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"
    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster = join(",", [
      for i in range(var.controller_count) : "etcd${i}=https://${var.cluster_name}-etcd${i}.${var.dns_zone}:2380"
    ])
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
  })
  strict   = true
  snippets = var.controller_snippets
}