resource "digitalocean_vpc" "vpc" {
  count = local.create_vpc ? 1 : 0

  name        = local.cluster_name
  region      = var.region
  description = "vpc for ${local.cluster_name} cluster"
}

data "digitalocean_vpc" "vpc" {
  count = local.create_vpc ? 0 : 1
  name  = var.vpc_name
}
