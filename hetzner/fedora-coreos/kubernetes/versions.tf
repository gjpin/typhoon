# Terraform version and plugin versions

terraform {
  required_version = ">= 0.13.0, < 2.0.0"
  required_providers {
    null = ">= 2.1"
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.13"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.48, < 2.0"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = ">= 2.2, < 3.0"
    }
  }
}
