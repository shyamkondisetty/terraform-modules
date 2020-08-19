variable "do_token" {
  type = string
}

variable "name" {
  type = string
}

variable "ssh_key" {
  type = object({
    public_key_path      = string
    digitalocean_ssh_key = string
    useExistingKey       = bool
  })
}

variable "addons" {
  type = object({

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
}

variable "pod_cidr" {
  type = string
}

variable "service_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "region" {
  type = string
}

variable "primary" {
  type = list(object({
    user  = string
    image = string
    size  = string
    tags  = list(string)

    labels = list(object({
      name  = string
      value = string
    }))

  }))
}

variable "node_pools" {
  type = list(object({
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
}
