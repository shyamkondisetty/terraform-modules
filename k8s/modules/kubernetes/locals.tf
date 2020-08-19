locals {
  cluster_name   = replace(var.name, "_", "-")
  create_vpc     = var.vpc_name == null
  create_ssh_key = var.ssh_key.useExistingKey == false
  nodes = flatten([for node_pool in var.node_pools : [
    for node_id in range(node_pool.count) : {
      image       = node_pool.image
      size        = node_pool.size
      region      = var.region
      tags        = node_pool.tags
      user        = node_pool.user
      id          = "${node_pool.name}-${node_id}"
      node_labels = node_pool.labels
    }
  ]])
}

locals {
  python_interpreter           = "/usr/bin/python3"
  ansible_ssh_private_key_file = pathexpand(replace(var.ssh_key.public_key_path, ".pub", ""))

  digitalocean_labels = [{
    name  = "platform",
    value = "digitalocean"
  }]

  primary_droplets = [for index, primary in var.primary : {
    ansible_python_interpreter   = local.python_interpreter
    hostname                     = digitalocean_droplet.kubernetes_primary[format("%02s", index + 1)].name
    ansible_host                 = digitalocean_droplet.kubernetes_primary[format("%02s", index + 1)].ipv4_address
    ansible_user                 = primary.user
    ansible_ssh_private_key_file = local.ansible_ssh_private_key_file
    type                         = "primary"
    node_labels                  = concat(primary.labels, local.digitalocean_labels)
  }]

  node_droplets = [for index, node in local.nodes : {
    ansible_python_interpreter   = local.python_interpreter
    hostname                     = digitalocean_droplet.kubernetes_nodes[node.id].name
    ansible_host                 = digitalocean_droplet.kubernetes_nodes[node.id].ipv4_address
    ansible_user                 = node.user
    ansible_ssh_private_key_file = local.ansible_ssh_private_key_file
    type                         = "node"
    node_labels                  = concat(node.node_labels, local.digitalocean_labels)
  }]

  hosts = coalesce(concat(local.primary_droplets, local.node_droplets), [])
}
