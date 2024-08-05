locals {
  # Subdivide the virtual network into subnets
  controller_subnet_ipv4 = [for i, cidr in var.network_cidr.ipv4 : cidrsubnet(cidr, 1, 0)]
  worker_subnet_ipv4 = [for i, cidr in var.network_cidr.ipv4 : cidrsubnet(cidr, 1, 1)]
  cluster_subnet_ipv4 = concat(local.controller_subnet.ipv4, local.worker_subnet.ipv4)
}

resource "hcloud_network" "network" {
  name     = "var.cluster_name"
  ip_range = var.network_cidr.ipv4
}

# Subnets - separate subnets for controllers and workers because Hetzner
# supports a single label selector 
resource "hcloud_network_subnet" "controller_subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.controller_subnet.ipv4
}

resource "hcloud_network_subnet" "worker_subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.worker_subnet.ipv4
}

# Controller firewall
resource "hcloud_firewall" "controller_firewall" {
  name = "${var.cluster_name}-controller"

  apply_to {
    label_selector   = "name=${var.cluster_name}-controller"
  }
  
  # ICMP
  rule {
    direction = "in"
    protocol  = "icmp"
    description = "ICMP"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # SSH
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "22"
    description = "SSH"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    destination_ips = local.controller_subnet_ipv4
  }

  # ETCD
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "2379-2380"
    description = "etcd"
    source_ips = local.controller_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Allow Prometheus to scrape etcd metrics
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "2381"
    description = "Allow Prometheus to scrape etcd metrics"
    source_ips = local.worker_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Allow Prometheus to scrape kube-proxy metrics
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "10249"
    description = "Allow Prometheus to scrape kube-proxy metrics"
    source_ips = local.worker_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Allow Prometheus to scrape kube-scheduler and kube-controller-manager metrics
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "10257-10259"
    description = "Allow Prometheus to scrape kube-scheduler and kube-controller-manager metrics"
    source_ips = local.worker_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Kubernetes API server
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "6443"
    description = "Kubernetes API server"
    destination_ips = local.controller_subnet_ipv4
  }

  # Cilium health
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "4240"
    description = "Cilium health"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Cilium metrics
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "9962-9965"
    description = "Cilium metrics"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # VXLAN
  rule {
    direction = "in"
    protocol  = "udp"
    port = "4789"
    description = "VXLAN"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Linux VXLAN
  rule {
    direction = "in"
    protocol  = "udp"
    port = "8472"
    description = "Linux VXLAN"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Allow Prometheus to scrape node-exporter daemonset
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "9100"
    description = "Allow Prometheus to scrape node-exporter daemonset"
    source_ips = local.worker_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }

  # Allow apiserver to access kubelet's for exec, log, port-forward
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "10250"
    description = "Allow apiserver to access kubelet's for exec, log, port-forward"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.controller_subnet_ipv4
  }
}

# Worker firewall
resource "hcloud_firewall" "worker_firewall" {
  name = "${var.cluster_name}-worker"

  apply_to {
    label_selector   = "name=${var.cluster_name}-worker"
  }
  
  # ICMP
  rule {
    direction = "in"
    protocol  = "icmp"
    description = "ICMP"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # SSH
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "22"
    description = "SSH"
    source_ips = local.controller_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # HTTP
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "80"
    description = "HTTP"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    destination_ips = local.worker_subnet_ipv4
  }

  # HTTPS
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "443"
    description = "HTTPS"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
    destination_ips = local.worker_subnet_ipv4
  }

  # Cilium health
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "4240"
    description = "Cilium health"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # Cilium metrics
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "9962-9965"
    description = "Cilium metrics"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # VXLAN
  rule {
    direction = "in"
    protocol  = "udp"
    port = "4789"
    description = "VXLAN"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # Linux VXLAN
  rule {
    direction = "in"
    protocol  = "udp"
    port = "8472"
    description = "Linux VXLAN"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # Allow Prometheus to scrape node-exporter daemonset
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "9100"
    description = "Allow Prometheus to scrape node-exporter daemonset"
    source_ips = local.worker_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # Allow Prometheus to scrape kube-proxy metrics
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "10249"
    description = "Allow Prometheus to scrape kube-proxy metrics"
    source_ips = local.worker_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }

  # Allow apiserver to access kubelet's for exec, log, port-forward
  rule {
    direction = "in"
    protocol  = "tcp"
    port = "10250"
    description = "Allow apiserver to access kubelet's for exec, log, port-forward"
    source_ips = local.cluster_subnet_ipv4
    destination_ips = local.worker_subnet_ipv4
  }
}