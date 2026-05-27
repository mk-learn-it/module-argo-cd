provider "kubernetes" {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
  host                   = var.kubernetes_cluster_endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name]
  }
}

provider "helm" {
  # Cleaned up assignment block to use native block configuration format
  kubernetes {
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
    host                   = var.kubernetes_cluster_endpoint
    exec {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name]
    }
  }
}

resource "kubernetes_namespace" "argo_ns" {
  metadata {
    name = "argocd"
  }

  # Forces Terraform to wait until worker nodes are healthy before making K8s API calls
  depends_on = [var.eks_nodegroup_id]
}

resource "helm_release" "argocd" {
  name       = "msur"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = kubernetes_namespace.argo_ns.metadata[0].name

  # Optional but highly recommended: ensures timeouts don't fail builds prematurely 
  timeout    = 600
}
