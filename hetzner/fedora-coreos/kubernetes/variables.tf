variable "cluster_name" {
  type        = string
  description = "Unique cluster name (prepended to dns_zone)"
}

# Hetzner
# https://docs.hetzner.cloud/#datacenters-get-all-datacenters
variable "network_zone" {
  type        = string
  description = "Hetzner network zone (eu-central, us-east, us-west)"
}

variable "network_cidr" {
  type = object({
    ipv4 = list(string)
  })
  description = "Virtual network CIDR ranges"
  default = {
    ipv4 = ["10.0.0.0/16"]
  }
}

variable "dns_zone" {
  type        = string
  description = "Top level domain (i.e. DNS zone) (e.g. example.com)"
}

variable "location" {
  type        = string
  description = "Hetzner location (e.g. nbg1, fsn1, hel1, ash, hil)"
}

# Instances
variable "controller_count" {
  type        = number
  description = "Number of controllers (i.e. masters)"
  default     = 1
}

variable "worker_count" {
  type        = number
  description = "Number of workers"
  default     = 1
}

variable "controller_type" {
  type        = string
  description = "Server type for controllers (e.g. cpx11, cpx21, cpx31)."
  default     = "cpx11"
}

variable "worker_type" {
  type        = string
  description = "Server type for controllers (e.g. cpx11, cpx21, cpx31)."
  default     = "cpx11"
}

variable "os_image" {
  type        = string
  description = "Fedora CoreOS image for instances"
}

variable "controller_snippets" {
  type        = list(string)
  description = "Controller Butane snippets"
  default     = []
}

variable "worker_snippets" {
  type        = list(string)
  description = "Worker Butane snippets"
  default     = []
}

# configuration
variable "ssh_fingerprints" {
  type        = list(string)
  description = "SSH public key fingerprints. (e.g. see `ssh-add -l -E md5`)"
}

variable "networking" {
  type        = string
  description = "Choice of networking provider (flannel, calico, or cilium)"
  default     = "cilium"
}

variable "pod_cidr" {
  type        = string
  description = "CIDR IPv4 range to assign Kubernetes pods"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  type        = string
  description = <<EOD
CIDR IPv4 range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for coredns.
EOD
  default     = "10.3.0.0/16"
}

# advanced
variable "components" {
  description = "Configure pre-installed cluster components"
  # Component configs are passed through to terraform-render-bootstrap,
  # which handles type enforcement and defines defaults
  # https://github.com/poseidon/terraform-render-bootstrap/blob/main/variables.tf#L95
  type = object({
    enable     = optional(bool)
    coredns    = optional(map(any))
    kube_proxy = optional(map(any))
    flannel    = optional(map(any))
    calico     = optional(map(any))
    cilium     = optional(map(any))
  })
  default = null
}