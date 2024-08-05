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

variable "os_image" {
  type        = string
  description = "Fedora CoreOS image for instances"
}

# configuration
variable "ssh_fingerprints" {
  type        = list(string)
  description = "SSH public key fingerprints. (e.g. see `ssh-add -l -E md5`)"
}