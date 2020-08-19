locals {
  primary_tags = [for droplet in digitalocean_droplet.kubernetes_primary : droplet.tags]
  node_tags    = [for droplet in digitalocean_droplet.kubernetes_nodes : droplet.tags]
  droplet_tags = flatten([local.primary_tags, local.node_tags])
  network_cidr = local.create_vpc ? digitalocean_vpc.vpc[0].ip_range : data.digitalocean_vpc.vpc[0].ip_range
  outbound_rules = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0"]
    }
  ]
  inbound_rules = [
    {
      protocol         = "tcp"
      port_range       = "1-65535"
      source_addresses = [local.network_cidr]
      source_tags      = local.droplet_tags
    },
    {
      protocol         = "udp"
      port_range       = "1-65535"
      source_addresses = [local.network_cidr]
      source_tags      = local.droplet_tags
    },
    {
      protocol         = "icmp"
      port_range       = null
      source_addresses = [local.network_cidr]
      source_tags      = local.droplet_tags
    },
    {
      protocol         = "tcp"
      port_range       = 22
      source_addresses = ["0.0.0.0/0"]
      source_tags      = local.droplet_tags
    },
    {
      protocol         = "tcp"
      port_range       = 6443
      source_addresses = ["0.0.0.0/0"]
      source_tags      = local.droplet_tags
    },
  ]
}

resource "digitalocean_firewall" "firewall" {
  name = local.cluster_name
  tags = local.droplet_tags

  dynamic "outbound_rule" {
    for_each = { for index, rule in local.outbound_rules : index => rule }

    content {
      protocol              = outbound_rule.value.protocol
      port_range            = outbound_rule.value.port_range
      destination_addresses = outbound_rule.value.destination_addresses
    }
  }

  dynamic "inbound_rule" {
    for_each = { for index, rule in local.inbound_rules : index => rule }

    content {
      protocol         = inbound_rule.value.protocol
      port_range       = inbound_rule.value.port_range
      source_addresses = inbound_rule.value.source_addresses
      source_tags      = inbound_rule.value.source_tags
    }
  }
}
