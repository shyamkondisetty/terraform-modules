module "devops_catalyst" {
  source       = "./modules/kubernetes"
  name         = var.k8s_cluster.cluster_name
  vpc_name     = null
  do_token     = var.do_token
  region       = var.k8s_cluster.region
  pod_cidr     = var.k8s_cluster.pod_cidr
  service_cidr = var.k8s_cluster.service_cidr
  primary      = var.k8s_cluster.primary
  node_pools   = var.k8s_cluster.node_pools
  addons       = var.k8s_cluster.addons
  ssh_key = {
    public_key_path      = var.ssh_key_public_key_path
    digitalocean_ssh_key = var.do_ssh_key_name
    useExistingKey       = var.use_existing_do_ssh_key
  }
}
