#### This is the Terraform to deploy Grafana and Prometheus.
#### This is being deployed in the default namespace which isn't best practice. 
#### It should be in its own namespace when in production.

resource "helm_release" "grafana" {
  name       = "grafana"

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  values = [
    "${file("./helm/grafana-prometheus/values.yaml")}"
    ]
}

### This ingress is for a local K3s server and doesn't use encryption. It needs to be changed for your use case.
### This setup is accessed from the internet via Cloudflare Tunnel which handles the encryption and proxies the traffic to the pods.

# resource "kubernetes_ingress_v1" "prometheus_ingress" {
#   metadata {
#     name      = "prometheus-ingress"
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }

#   spec {
#     rule {
#       host = "prometheus.k3s.lan"
#       http {
#         path {
#           path = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "grafana-kube-prometheus-st-prometheus"
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
