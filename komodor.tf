/*
  Komodor install — simplified: API key is resolved only by AKS cluster name.
*/
locals {
  komodor_enabled = { for k, v in local.aks_instances :
    k => (
      try(lookup(lookup(v.komodor_enabled, "env_override", {}), local.basic["local"].env_short, null) != null, false) ?
        v.komodor_enabled.env_override[local.basic["local"].env_short] :
      try(lookup(lookup(v.komodor_enabled, "mg_override", {}), local.basic["local"].mg_short, null) != null, false) ?
        v.komodor_enabled.mg_override[local.basic["local"].mg_short] :
        try(v.komodor_enabled.default, true)
    )
  }

  komodor_version_tag = { for k, v in local.aks_instances :
    k => (
      try(lookup(lookup(v.komodor_version_tag, "env_override", {}), local.basic["local"].env_short, null) != null, false) ?
        v.komodor_version_tag.env_override[local.basic["local"].env_short] :
      try(lookup(lookup(v.komodor_version_tag, "mg_override", {}), local.basic["local"].mg_short, null) != null, false) ?
        v.komodor_version_tag.mg_override[local.basic["local"].mg_short] :
        try(v.komodor_version_tag.default, "1.8.11")
    )
  }

  komodor_namespace = "komodor"
}

resource "kubernetes_namespace" "komodor" {
  for_each = { for k, v in local.aks_instances : k => v if local.komodor_enabled[k] }

  metadata {
    name = local.komodor_namespace
    labels = {
      "app.kubernetes.io/name" = "komodor-agent"
      "fnf.env"                = local.basic["local"].env_short
    }
  }
}

resource "helm_release" "komodor" {
  for_each = { for k, v in local.aks_instances : k => v if local.komodor_enabled[k] }

  name             = "komodor-agent"
  repository       = "https://helm-charts.komodor.io"
  chart            = "komodor-agent"
  version          = local.komodor_version_tag[each.key]

  namespace        = local.komodor_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values-komodor.yaml", {
      clusterName = azurerm_kubernetes_cluster.aks[each.key].name
    })
  ]

  set_sensitive {
    name  = "apiKey"
    value = lookup(
      var.komodor_api_keys_by_cluster,
      azurerm_kubernetes_cluster.aks[each.key].name,
      ""
    )
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    kubernetes_namespace.komodor
  ]
}
