locals {
  inventory = {
    all = {
      hosts = { for host in local.hosts : host.hostname => host }
      children = {
        common = {
          hosts = { for host in local.hosts : host.hostname => {} }
          vars  = {}
        }
        primary = {
          hosts = { for host in local.hosts : host.hostname => {} if host.type == "primary" }
        }
        node = {
          hosts = { for host in local.hosts : host.hostname => {} if host.type == "node" }
        }
      }
    }
  }

  empty_addons = {
    ingress      = null
    csi          = null
    ccm          = null
    external_dns = null
    cert_manager = null
    ebs          = null
  }

  addons = var.addons == null ? local.empty_addons : var.addons

  addons_default = {
    ingress = { enabled = false }
    csi     = { enabled = false, upgrade = false }
    ccm     = { enabled = false }
    ebs     = { enabled = false }

    external_dns = {
      enabled       = false
      domain_filter = "example@example.com"
      source        = "ingress"
    }

    cert_manager = {
      enabled            = false
      environment        = "dev"
      acme_email_address = "example@example.com"
    }
  }

  cluster_addons = {
    ingress      = local.addons.ingress == null ? local.addons_default.ingress : var.addons.ingress
    csi          = local.addons.csi == null ? local.addons_default.csi : var.addons.csi
    ccm          = local.addons.ccm == null ? local.addons_default.ccm : var.addons.ccm
    external_dns = local.addons.external_dns == null ? local.addons_default.external_dns : var.addons.external_dns
    cert_manager = local.addons.cert_manager == null ? local.addons_default.cert_manager : var.addons.cert_manager
    ebs          = local.addons.ebs == null ? local.addons_default.ebs : var.addons.ebs
  }

  extra_vars = {
    network_interface = "eth1"
    provider          = "digitalocean"
  }

  primary_extra_vars = {
    vpc_id = local.vpc_uuid
    digital_ocean_token = var.do_token
    cluster_name        = local.cluster_name
    addons              = local.cluster_addons
    custom_cluster_config = {
      clusterName = local.cluster_name
      networking = {
        podSubnet     = var.pod_cidr
        serviceSubnet = var.service_cidr
      }
    }
  }

  node_extra_vars = {
    addons = {
      ebs = local.cluster_addons.ebs
    }
  }
}

resource "local_file" "kubernetes_inventory" {
  sensitive_content = yamlencode(local.inventory)
  filename          = "${path.root}/${local.cluster_name}-nodes.inventory.yaml"
}

resource "local_file" "ansible_primary_host_vars" {
  for_each = { for host in local.hosts : host.hostname => host if host.type == "primary" }

  sensitive_content = yamlencode(merge(local.extra_vars, local.primary_extra_vars))
  filename          = "${path.module}/playbook/host_vars/${each.key}.yaml"
}

resource "local_file" "ansible_node_host_vars" {
  for_each = { for index, host in local.hosts : index => host if host.type == "node" }

  sensitive_content = yamlencode(merge(local.extra_vars, local.node_extra_vars))
  filename          = "${path.module}/playbook/host_vars/${each.value.hostname}.yaml"
}

locals {
  node_host_vars_ids    = [for host_var in local_file.ansible_node_host_vars : host_var.sensitive_content]
  primary_host_vars_ids = [for host_var in local_file.ansible_primary_host_vars : host_var.sensitive_content]
  host_vars_ids         = flatten([local.primary_host_vars_ids, local.node_host_vars_ids])
}

resource "time_sleep" "wait_for_droplets" {
  create_duration = "30s"

  triggers = {
    inventory_file = local_file.kubernetes_inventory.id
    host_vars      = join(",", local.host_vars_ids)
  }
}

resource "null_resource" "provision_kubernetes" {
  triggers = time_sleep.wait_for_droplets.triggers

  provisioner "local-exec" {
    command = "ANSIBLE_FORCE_COLOR=1 ANSIBLE_HASH_BEHAVIOUR=merge ansible-playbook --ssh-extra-args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' -i ${local_file.kubernetes_inventory.filename} ${path.module}/playbook/kubernetes.yaml"
  }
}