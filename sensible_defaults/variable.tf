variable "install_ci" {
  type = bool
  default = false
}

variable "grafana_admin_password" {
  type = string
}

variable "jenkins_admin_password" {
  type = string
}

variable "linkerd_validity_hours" {
  description = "The number of hours after initial issuing that the certificate will become invalid"
  type = number
  default     = 87600
}

variable "linkerd_common_name" {
  description = "Common name for the certificate"
  type = string
  default = "identity.linkerd.cluster.local"
}

variable "linkerd_organization" {
  description = "Organization name for the certificate"
  type = string
  default = "thoughtworks"
}

variable kubeconfig_path {
  type = string
}
