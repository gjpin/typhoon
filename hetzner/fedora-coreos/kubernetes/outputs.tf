output "kubeconfig-admin" {
  value     = module.bootstrap.kubeconfig-admin
  sensitive = true
}

# Outputs for Kubernetes Ingress
output "controllers_dns" {
  value = "${hetzner_record.controllers[0]}.${var.dns_zone}"
}

output "workers_dns" {
  # Multiple A and AAAA records with the same FQDN
  value = "${hetzner_record.workers-record-a[0]}.${var.dns_zone}"
}

output "controllers_ipv4" {
  value = hcloud_server.controllers.*.value
}

output "workers_ipv4" {
  value = hcloud_server.workers.*.value
}

# Outputs for worker pools

output "kubeconfig" {
  value     = module.bootstrap.kubeconfig-kubelet
  sensitive = true
}

# Outputs for debug

output "assets_dist" {
  value     = module.bootstrap.assets_dist
  sensitive = true
}

