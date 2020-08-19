variable "do_token" {
  type = string
}

variable "do_ssh_key_name" {
  type        = string
  default     = ""
  description = "required only if use_existing_do_ssh_key is true"
}

variable "use_existing_do_ssh_key" {
  type        = bool
  default     = false
  description = "If it is true, provide the key name in 'do_ssh_key_name'. If it is false, ssh key will added in DO in the name of cluster"
}

variable "ssh_key_public_key_path" {
  type = string
}

variable "k8s_cluster" {
  type = object({
    cluster_name = string
    pod_cidr     = string
    service_cidr = string
    region       = string

    addons = object({
      ingress = object({
        enabled = bool
      })

      csi = object({
        enabled = bool
        upgrade = bool
      })

      ccm = object({
        enabled = bool
      })

      external_dns = object({
        enabled       = bool
        source        = string
        domain_filter = string
      })

      cert_manager = object({
        enabled            = bool
        acme_email_address = string
        environment        = string
      })

      ebs = object({
        enabled = bool
      })
    })

    primary = list(object({
      user  = string
      image = string
      size  = string
      tags  = list(string)
      labels = list(object({
        name  = string
        value = string
      }))

    }))

    node_pools = list(object({
      count = number
      name  = string
      user  = string
      image = string
      size  = string
      tags  = list(string)

      labels = list(object({
        name  = string
        value = string
      }))

    }))

  })
}
