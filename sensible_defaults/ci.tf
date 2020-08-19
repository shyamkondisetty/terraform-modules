resource "kubernetes_namespace" "ci" {
  count = var.install_ci ? 1 : 0
  metadata {
    annotations = {
      name = "ci"
    }
    name = "ci"
  }

}

resource "helm_release" "ci" {
  count = var.install_ci ? 1 : 0
  name      = "jenkins"
  chart     = "stable/jenkins"
  namespace = kubernetes_namespace.ci[0].metadata[0].name
  timeout   = 600

  values = [file("${path.root}/values.yaml")]
}
