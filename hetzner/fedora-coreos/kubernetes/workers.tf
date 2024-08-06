# Controller Instance DNS records
resource "hetznerdns_record" "workers-record-a" {
    count = var.worker_count

    # DNS zone where record should be created
    zone_id = hetznerdns_zone.zone.id

    # DNS record (will be prepended to domain)
    name = "${var.cluster_name}-workers"
    type = "A"
    ttl = 300

    # IPv4 addresses of controllers
    value = hcloud_server.workers.*.ipv4_address[count.index]
}

# Controller instances
resource "hcloud_server" "workers" {
    count = var.worker_count

    name   = "${var.cluster_name}-worker-${count.index}"
    location = var.location

    image = var.os_image
    server_type = var.worker_type

    user_data = data.ct_config.worker.rendered
    ssh_keys  = var.ssh_fingerprints

    public_net {
        ipv4_enabled = true
        ipv6_enabled = false
    }

    labels = {
        name = "${var.cluster_name}-worker"
    }

  lifecycle {
    create_before_destroy = true
  }
}

resource "hcloud_server_network" "workers" {
  for_each = { for idx, server in hcloud_server.workers : idx => server }

  server_id = each.value.id
  subnet_id = hcloud_network_subnet.worker_subnet.id
}

# Fedora CoreOS worker
data "ct_config" "worker" {
  content = templatefile("${path.module}/butane/worker.yaml", {
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
  })
  strict   = true
  snippets = var.worker_snippets
}