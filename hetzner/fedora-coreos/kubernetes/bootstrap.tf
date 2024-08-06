# Kubernetes assets (kubeconfig, manifests)
module "bootstrap" {
  source = "git::https://github.com/poseidon/terraform-render-bootstrap.git?ref=1609060f4f138f3b3aef74a9e5494e0fe831c423"

  cluster_name = var.cluster_name
  api_servers  = [format("%s.%s", var.cluster_name, var.dns_zone)]
  etcd_servers = "${hetznerdns_record.etcds.*.name}.${var.dns_zone}"

  networking = var.networking
  # only effective with Calico networking
  network_encapsulation = "vxlan"
  network_mtu           = "1450"

  pod_cidr     = var.pod_cidr
  service_cidr = var.service_cidr
  components   = var.components
}

