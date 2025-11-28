terraform {
  required_version = ">= 1.4.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.31.0"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

resource "kubernetes_namespace" "devops_challenge" {
  metadata {
    name = "devops-challenge"
  }
}

resource "kubernetes_resource_quota" "devops_memory_cap" {
  metadata {
    name      = "devops-memory-cap"
    namespace = kubernetes_namespace.devops_challenge.metadata[0].name
  }

  spec {
    hard = {
      "limits.memory" = "512Mi"
    }
  }
}

