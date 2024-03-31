# resource "kubernetes_secret" "aws_credentials" {
#   metadata {
#     name = "aws-credentials"
#   }

#   data = {
#     AWS_ACCESS_KEY_ID     = ""
#     AWS_SECRET_ACCESS_KEY = ""
#   }
# }

# resource "kubernetes_deployment" "space-fetch" {
#   metadata {
#     name = "space-fetch"
#   }

#   spec {
#     replicas = 2

#     selector {
#       match_labels = {
#         app = "space-fetch"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "space-fetch"
#         }
#       }

#       spec {
#         container {
#           image = "ghcr.io/daniel-mcdonough/space-fetch:v0.1.7"
#           name  = "space-fetch"

#           env {
#             name  = "BUCKET_NAME"
#             value = "intercax"
#           }

#           env {
#             name  = "OBJECT_NAME"
#             value = "space-fetch.json"
#           }

#           env {
#             name  = "PATH_NAME"
#             value = "space-fetch"
#           }          

#           env {
#             name = "AWS_ACCESS_KEY_ID"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.aws_credentials.metadata[0].name
#                 key  = ""
#               }
#             }
#           }

#           env {
#             name = "AWS_SECRET_ACCESS_KEY"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.aws_credentials.metadata[0].name
#                 key  = ""
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }
