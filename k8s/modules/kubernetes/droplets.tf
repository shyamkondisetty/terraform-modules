resource "digitalocean_ssh_key" "ssh_key" {
  count      = local.create_ssh_key ? 1 : 0
  name       = local.cluster_name
  public_key = file(pathexpand(var.ssh_key.public_key_path))
}

data "digitalocean_ssh_key" "ssh_key" {
  count = local.create_ssh_key ? 0 : 1
  name  = var.ssh_key.digitalocean_ssh_key
}

locals {
  ssh_key  = local.create_ssh_key ? digitalocean_ssh_key.ssh_key[0].fingerprint : data.digitalocean_ssh_key.ssh_key[0].id
  vpc_uuid = local.create_vpc ? digitalocean_vpc.vpc[0].id : data.digitalocean_vpc.vpc[0].id
}

resource "digitalocean_droplet" "kubernetes_primary" {
  for_each = { for index, primary in var.primary : format("%02s", index + 1) => primary }

  image    = each.value.image
  name     = "${local.cluster_name}-primary-${each.key}"
  region   = var.region
  size     = each.value.size
  tags     = each.value.tags
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_uuid
}

resource "random_id" "nodes" {
  for_each = { for node in local.nodes : node.id => node }

  prefix      = "${local.cluster_name}-node-"
  byte_length = 4
}

resource "digitalocean_droplet" "kubernetes_nodes" {
  for_each = { for node in local.nodes : node.id => node }

  image    = each.value.image
  name     = random_id.nodes[each.key].hex
  region   = var.region
  size     = each.value.size
  tags     = each.value.tags
  ssh_keys = [local.ssh_key]
  vpc_uuid = local.vpc_uuid
}
